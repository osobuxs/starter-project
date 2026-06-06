import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/cricket_marks_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/repository/dardos_game_repository.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/services/dardos_cricket_rules.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/services/dardos_leg_rules.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/services/dardos_score_rules.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_state.dart';

class DardosGameBloc extends Bloc<DardosGameEvent, DardosGameState> {
  final DardosGameRepository _repository;
  bool _writeInFlight = false;

  DardosGameBloc({required DardosGameRepository repository})
      : _repository = repository,
        super(const DardosGameState()) {
    on<CreateDardosGameEvent>(_onCreate);
    on<LoadDardosGameEvent>(_onLoad);
    on<AcquireAnnotatorEvent>(_onAcquireAnnotator);
    on<ReleaseAnnotatorEvent>(_onReleaseAnnotator);
    on<RecordThrowEvent>(_onRecordThrow);
    on<UndoLastThrowEvent>(_onUndo);
    on<ReopenGameEvent>(_onReopen);
    on<CancelGameEvent>(_onCancel);
    on<AcknowledgeBannerEvent>(_onAcknowledgeBanner);
  }

  // ─── Create ────────────────────────────────────────────────────────────
  Future<void> _onCreate(
    CreateDardosGameEvent event,
    Emitter<DardosGameState> emit,
  ) async {
    if (event.name.trim().isEmpty) {
      emit(state.copyWith(
        status: DardosGameStatus.error,
        error: 'El nombre de la partida no puede estar vacío',
      ));
      return;
    }
    if (event.playerIds.length < 2) {
      emit(state.copyWith(
        status: DardosGameStatus.error,
        error: 'Se necesitan al menos 2 participantes',
      ));
      return;
    }
    if (event.teamMode) {
      if (event.teams.isEmpty) {
        emit(state.copyWith(
          status: DardosGameStatus.error,
          error: 'La configuración de equipos no es válida.',
        ));
        return;
      }
      final firstTeamSize = (event.teams.first['playerIds'] as List?)?.length ?? 0;
      if (firstTeamSize < 2) {
        emit(state.copyWith(
          status: DardosGameStatus.error,
          error: 'Cada equipo debe tener al menos 2 jugadores.',
        ));
        return;
      }
      for (final team in event.teams) {
        final size = (team['playerIds'] as List?)?.length ?? 0;
        if (size != firstTeamSize) {
          emit(state.copyWith(
            status: DardosGameStatus.error,
            error: 'Todos los equipos deben tener la misma cantidad de jugadores.',
          ));
          return;
        }
      }
    }

    emit(state.copyWith(status: DardosGameStatus.loading));

    final result = await _repository.createGame(
      name: event.name,
      mode: event.mode,
      doubleOut: event.doubleOut,
      sets: event.sets,
      legs: event.legs,
      playerIds: event.playerIds,
      teamMode: event.teamMode,
      teams: event.teams,
      playerTeamIds: event.playerTeamIds,
      createdBy: event.createdBy,
    );

    if (result is DataSuccess) {
      final game = result.data!;
      final recomputed = _recomputeGameState(baseGame: game, throws_: const []);
      emit(recomputed.copyWith(status: DardosGameStatus.gameCreated));
    } else {
      emit(state.copyWith(
        status: DardosGameStatus.error,
        error: result.error?.toString() ?? 'Error al crear la partida',
      ));
    }
  }

  // ─── Load ──────────────────────────────────────────────────────────────
  Future<void> _onLoad(
    LoadDardosGameEvent event,
    Emitter<DardosGameState> emit,
  ) async {
    emit(state.copyWith(status: DardosGameStatus.loading));

    final gameResult = await _repository.getGame(event.gameId);
    if (gameResult is! DataSuccess) {
      emit(state.copyWith(
        status: DardosGameStatus.error,
        error: gameResult.error?.toString() ?? 'Error al cargar la partida',
      ));
      return;
    }

    final game = gameResult.data!;
    final throwsResult = await _repository.getThrows(event.gameId);
    final throws_ = throwsResult is DataSuccess
        ? (throwsResult.data ?? <DardosThrowEntity>[])
        : <DardosThrowEntity>[];

    final sorted = _sortThrows(throws_);
    final recomputed = _recomputeGameState(baseGame: game, throws_: sorted);
    emit(recomputed.copyWith(status: DardosGameStatus.loaded));
  }

  // ─── Annotator lock ────────────────────────────────────────────────────
  Future<void> _onAcquireAnnotator(
    AcquireAnnotatorEvent event,
    Emitter<DardosGameState> emit,
  ) async {
    final result = await _repository.acquireAnnotator(
      gameId: event.gameId,
      deviceId: event.deviceId,
    );
    final acquired = result is DataSuccess && result.data == true;
    emit(state.copyWith(annotatorOwned: acquired));
  }

  Future<void> _onReleaseAnnotator(
    ReleaseAnnotatorEvent event,
    Emitter<DardosGameState> emit,
  ) async {
    await _repository.releaseAnnotator(
      gameId: event.gameId,
      deviceId: event.deviceId,
    );
    emit(state.copyWith(annotatorOwned: false));
  }

  // ─── Record throw ──────────────────────────────────────────────────────
  // Strategy: build the throw locally, recompute state with the new throw
  // included, emit optimistically. Persist to Firestore in parallel.
  Future<void> _onRecordThrow(
    RecordThrowEvent event,
    Emitter<DardosGameState> emit,
  ) async {
    final game = state.game;
    if (game == null) return;
    // Game already has a winner → no more throws allowed
    if (game.winnerId != null) return;
    if (!state.annotatorOwned) {
      emit(state.copyWith(status: DardosGameStatus.annotatorLocked));
      return;
    }
    // Defensive: no more than 3 darts per turn for the same player
    final dartsInCurrentTurn = state.throws
        .where((t) =>
            t.playerId == game.currentTurnPlayerId &&
            t.setIndex == game.currentSet &&
            t.legIndex == game.currentLeg &&
            t.turnIndex == game.currentTurnIndex)
        .length;
    if (dartsInCurrentTurn >= 3) return;
    // Drop concurrent throws — only one write may be in flight at a time
    if (_writeInFlight) return;
    _writeInFlight = true;
    try {
      await _processRecordThrow(event, emit, game);
    } finally {
      _writeInFlight = false;
    }
  }

  Future<void> _processRecordThrow(
    RecordThrowEvent event,
    Emitter<DardosGameState> emit,
    DardosGameEntity game,
  ) async {
    final mode = game.mode;
    final playerId = game.currentTurnPlayerId;
    final scoreOwnerId = game.scoreOwnerForPlayer(playerId);
    final points = event.isMiss ? 0 : event.number * event.multiplier;

    // Determine isBust / remainingAfter for 501/301 using the *recomputed*
    // current score (single source of truth = throws collection).
    int? remainingAfter;
    bool isBust_ = false;

    if (!event.isMiss && (mode == '501' || mode == '301')) {
      final currentRemaining =
          state.liveScores[scoreOwnerId] ?? (mode == '501' ? 501 : 301);
      final after = currentRemaining - points;
      isBust_ = isBust(
        remainingBefore: currentRemaining,
        dartPoints: points,
        dartMultiplier: event.multiplier,
        doubleOut: game.doubleOut,
      );
      remainingAfter = isBust_ ? null : after;
    }

    String? cricketTarget;
    int? cricketMarksDelta;
    int cricketPointsScored = 0;
    if (mode == 'cricket' && !event.isMiss) {
      cricketTarget = event.number == 25
          ? 'bull'
          : (event.number >= 15 && event.number <= 20
              ? '${event.number}'
              : null);
      if (cricketTarget != null) {
        cricketMarksDelta = event.multiplier;
      }
    }

    final tempThrow = DardosThrowEntity(
      id: 'tmp_${DateTime.now().microsecondsSinceEpoch}',
      playerId: playerId,
      setIndex: game.currentSet,
      legIndex: game.currentLeg,
      turnIndex: game.currentTurnIndex,
      dartIndex: game.currentDartIndex,
      number: event.number,
      multiplier: event.multiplier,
      points: points,
      isMiss: event.isMiss,
      isBust: isBust_,
      remainingAfter: remainingAfter,
      cricketTarget: cricketTarget,
      cricketMarksDelta: cricketMarksDelta,
      cricketPointsScored: cricketPointsScored,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      createdBy: playerId,
    );

    // 1. Compute optimistic state
    final optimisticThrows = _sortThrows([...state.throws, tempThrow]);
    final optimistic = _recomputeGameState(
      baseGame: game,
      throws_: optimisticThrows,
    );

    final bannerType = _bannerForLastEvent(
      previousState: state,
      newState: optimistic,
      lastThrow: tempThrow,
    );

    final isWinningThrow = optimistic.game?.winnerId != null;

    // Always emit optimistically for snappy UI. For a winning throw
    // we emit gameFinished status + gameWon banner immediately; the
    // play page UI shows the celebration banner while persistence
    // happens in parallel below. Navigation to the finished page is
    // delayed until the banner is dismissed (~2s) — by then the
    // Firestore writes have completed and the finished page can read
    // a consistent game doc.
    emit(optimistic.copyWith(
      annotatorOwned: state.annotatorOwned,
      bannerType: bannerType,
      bannerPayload: optimistic.game?.winnerId,
      status: isWinningThrow
          ? DardosGameStatus.gameFinished
          : (bannerType == DardosBannerType.bust
              ? DardosGameStatus.bustDetected
              : (bannerType == DardosBannerType.legWon
                  ? DardosGameStatus.legWon
                  : DardosGameStatus.throwRecorded)),
    ));

    // 2. Persist throw
    final appendResult = await _repository.appendThrow(
      gameId: game.id,
      throw_: tempThrow,
    );

    if (appendResult is! DataSuccess) {
      // Rollback: remove the temp throw and re-emit
      final rollbackThrows =
          state.throws.where((t) => t.id != tempThrow.id).toList();
      final rolled = _recomputeGameState(
        baseGame: game,
        throws_: rollbackThrows,
      );
      emit(rolled.copyWith(
        status: DardosGameStatus.error,
        error: appendResult.error?.toString() ?? 'Error al registrar el tiro',
        annotatorOwned: state.annotatorOwned,
      ));
      return;
    }

    // 3. Replace temp throw with persisted (real id)
    final persisted = appendResult.data!;
    final finalThrows = state.throws.map((t) {
      return t.id == tempThrow.id ? persisted : t;
    }).toList();

    // 4. Update game progress (cursor + winners) — fire and forget;
    //    the banner timeout gives time for the write to land before
    //    the finished page reads from Firestore.
    final rg = optimistic.game;
    if (rg != null) {
      _repository
          .updateGameProgress(
            gameId: rg.id,
            currentSet: rg.currentSet,
            currentLeg: rg.currentLeg,
            currentTurnPlayerId: rg.currentTurnPlayerId,
            currentTurnIndex: rg.currentTurnIndex,
            currentDartIndex: rg.currentDartIndex,
            legWinners: rg.legWinners,
            setWinners: rg.setWinners,
            rosterLocked: true,
          )
          .catchError((_) => const DataSuccess(null));
    }

    // 5. If game finished, persist final state + stats in parallel.
    //    All these writes happen while the banner is celebrating.
    if (isWinningThrow && rg != null) {
      final metrics = _computeMetrics(
        mode: rg.mode,
        playerIds: rg.playerIds,
        throws_: finalThrows,
      );
      final freqByPlayer = _computeFreqByPlayer(
        playerIds: rg.playerIds,
        throws_: finalThrows,
      );
      // Wait for final writes to land before navigating to the finished page.
      await Future.wait([
        _repository.finishGame(
          gameId: rg.id,
          winnerId: rg.winnerId!,
          computedMetrics: metrics,
        ),
        _repository.updateParticipantStatsOnGameFinished(
          playerIds: rg.playerIds,
          winnerId: rg.winnerId!,
          winnerPlayerIds: rg.playersForWinner(rg.winnerId!),
          mode: rg.mode,
          metricsPerPlayer: metrics['perPlayer'] as Map<String, dynamic>? ?? {},
          freqByPlayer: freqByPlayer,
        ),
      ]).catchError((_) => <DataState<void>>[]);
      // Emit final throws (replace tmp with persisted) but keep
      // gameFinished status + banner — the listener will navigate
      // when the banner dismisses.
      emit(state.copyWith(throws: finalThrows));
      return;
    }

    // 6. Sync persisted id silently (no UI re-emit needed unless rollback)
    if (state.throws.any((t) => t.id == tempThrow.id)) {
      emit(state.copyWith(throws: finalThrows));
    }
  }

  // ─── Undo ──────────────────────────────────────────────────────────────
  Future<void> _onUndo(
    UndoLastThrowEvent event,
    Emitter<DardosGameState> emit,
  ) async {
    final game = state.game;
    if (game == null || state.throws.isEmpty) return;
    if (_writeInFlight) return;
    _writeInFlight = true;
    try {
      await _processUndo(game, emit);
    } finally {
      _writeInFlight = false;
    }
  }

  Future<void> _processUndo(
    DardosGameEntity game,
    Emitter<DardosGameState> emit,
  ) async {
    // 1. Optimistic local update: remove last throw, recompute, emit
    final remaining = [...state.throws]..removeLast();
    final recomputed = _recomputeGameState(
      baseGame: game,
      throws_: remaining,
    );
    emit(recomputed.copyWith(
      bannerType: DardosBannerType.none,
      annotatorOwned: state.annotatorOwned,
      status: DardosGameStatus.throwRecorded,
    ));

    // 2. Persist deletion
    await _repository.deleteLastThrow(game.id);

    // 3. Sync game progress
    final rg = recomputed.game;
    if (rg != null) {
      _repository
          .updateGameProgress(
            gameId: rg.id,
            currentSet: rg.currentSet,
            currentLeg: rg.currentLeg,
            currentTurnPlayerId: rg.currentTurnPlayerId,
            currentTurnIndex: rg.currentTurnIndex,
            currentDartIndex: rg.currentDartIndex,
            legWinners: rg.legWinners,
            setWinners: rg.setWinners,
            rosterLocked: rg.rosterLocked,
          )
          .catchError((_) => const DataSuccess(null));
    }
  }

  // ─── Reopen (undo the winning dart of a finished game) ──────────────────
  // Reverses the lifetime stats that were written at finish time, deletes
  // the dart that closed the game, and flips the doc back to in_progress.
  // Because the whole state is event-sourced from the throws collection,
  // removing the winning dart makes _recomputeGameState clear the winner
  // and hand the turn back to the player who threw it.
  Future<void> _onReopen(
    ReopenGameEvent event,
    Emitter<DardosGameState> emit,
  ) async {
    if (!event.isAdmin) {
      emit(state.copyWith(
        status: DardosGameStatus.error,
        error: 'Solo el administrador puede reabrir partidas',
      ));
      return;
    }
    final game = state.game;
    // Nothing to reopen unless the game actually finished.
    if (game == null || game.winnerId == null) return;
    if (_writeInFlight) return;
    _writeInFlight = true;
    try {
      await _processReopen(game, emit);
    } finally {
      _writeInFlight = false;
    }
  }

  Future<void> _processReopen(
    DardosGameEntity game,
    Emitter<DardosGameState> emit,
  ) async {
    final winnerId = game.winnerId!;
    final throws_ = state.throws;

    // 1. Revert the exact stats that were summed at finish time. We
    //    recompute them from the same throws so the decrement matches.
    final metrics = _computeMetrics(
      mode: game.mode,
      playerIds: game.playerIds,
      throws_: throws_,
    );
    final freqByPlayer = _computeFreqByPlayer(
      playerIds: game.playerIds,
      throws_: throws_,
    );
    await _repository.reverseParticipantStatsOnGameFinished(
      playerIds: game.playerIds,
      winnerId: winnerId,
      winnerPlayerIds: game.playersForWinner(winnerId),
      mode: game.mode,
      metricsPerPlayer: metrics['perPlayer'] as Map<String, dynamic>? ?? {},
      freqByPlayer: freqByPlayer,
    );

    // 2. Delete the dart that closed the game.
    await _repository.deleteLastThrow(game.id);

    // 3. Flip the doc back to in_progress (clears winnerId + metrics).
    await _repository.reopenGame(gameId: game.id);

    // 4. Recompute local state without the winning dart.
    final remaining =
        throws_.isEmpty ? <DardosThrowEntity>[] : ([...throws_]..removeLast());
    final reopenedBase = game.copyWith(status: 'in_progress');
    final recomputed = _recomputeGameState(
      baseGame: reopenedBase,
      throws_: remaining,
    );

    // 5. Persist the rolled-back cursor.
    final rg = recomputed.game;
    if (rg != null) {
      await _repository
          .updateGameProgress(
            gameId: rg.id,
            currentSet: rg.currentSet,
            currentLeg: rg.currentLeg,
            currentTurnPlayerId: rg.currentTurnPlayerId,
            currentTurnIndex: rg.currentTurnIndex,
            currentDartIndex: rg.currentDartIndex,
            legWinners: rg.legWinners,
            setWinners: rg.setWinners,
            rosterLocked: rg.rosterLocked,
          )
          .catchError((_) => const DataSuccess(null));
    }

    emit(recomputed.copyWith(
      status: DardosGameStatus.gameReopened,
      annotatorOwned: state.annotatorOwned,
      clearBanner: true,
    ));
  }

  // ─── Cancel ────────────────────────────────────────────────────────────
  Future<void> _onCancel(
    CancelGameEvent event,
    Emitter<DardosGameState> emit,
  ) async {
    if (!event.isAdmin) {
      emit(state.copyWith(
        status: DardosGameStatus.error,
        error: 'Solo el administrador puede cancelar partidas',
      ));
      return;
    }
    final result = await _repository.cancelGame(
      gameId: event.gameId,
      cancelledBy: event.cancelledBy,
    );
    if (result is DataSuccess) {
      emit(state.copyWith(status: DardosGameStatus.gameCancelled));
    } else {
      emit(state.copyWith(
        status: DardosGameStatus.error,
        error: result.error?.toString() ?? 'Error al cancelar la partida',
      ));
    }
  }

  void _onAcknowledgeBanner(
    AcknowledgeBannerEvent event,
    Emitter<DardosGameState> emit,
  ) {
    emit(state.copyWith(clearBanner: true));
  }

  // ═══ CORE: event-sourced recompute ════════════════════════════════════
  //
  // Single source of truth = the throws collection (ordered).
  // Derives: per-player remaining/points, leg winners, set winners,
  // game winner, current cursor (set, leg, turnIndex, dartIndex, player).
  //
  // Rules:
  //  • A turn with ANY bust dart contributes 0 to that player's score
  //    (entire turn is voided in standard darts).
  //  • A miss dart contributes 0 but does NOT void the turn.
  //  • A dart that lands at exactly 0 with a valid checkout wins the leg.
  //  • After a leg is won, scores reset for the next leg.
  //
  DardosGameState _recomputeGameState({
    required DardosGameEntity baseGame,
    required List<DardosThrowEntity> throws_,
  }) {
    final mode = baseGame.mode;
    final legStartScore = mode == '501' ? 501 : (mode == '301' ? 301 : 0);

    // Pre-compute which (player, set, leg, turn) tuples have a bust.
    // Used to void entire turns when summing.
    final bustedTurns = <String>{};
    for (final t in throws_) {
      if (t.isBust) {
        bustedTurns.add(
            '${baseGame.scoreOwnerForPlayer(t.playerId)}|${t.setIndex}|${t.legIndex}|${t.turnIndex}');
      }
    }

    // Both legWinners (outer) and each legWinners[s] (inner) are
    // GROWABLE — supports OVERTIME for both legs (extra legs within a
    // set when no one reaches the leg threshold) and sets (extra sets
    // when no one reaches the set threshold).
    final legWinners = <List<String?>>[
      for (var s = 0; s < baseGame.sets; s++)
        List<String?>.filled(baseGame.legs, null, growable: true),
    ];

    void ensureSetSlot(int s) {
      while (legWinners.length <= s) {
        legWinners.add(
          List<String?>.filled(baseGame.legs, null, growable: true),
        );
      }
    }

    void ensureLegSlot(int s, int len) {
      ensureSetSlot(s);
      while (legWinners[s].length < len) {
        legWinners[s].add(null);
      }
    }

    final scoreOwnerIds = baseGame.scoreOwnerIds;

    var liveScores = <String, int>{
      for (final p in scoreOwnerIds) p: legStartScore,
    };
    var cricket = CricketMarksState.empty(scoreOwnerIds);

    // Walk throws in order, applying each one.
    var currentLegSet = -1;
    var currentLegLeg = -1;
    var lastApplied = throws_.isEmpty ? null : throws_.first;

    for (final t in throws_) {
      // New leg detected → reset scores
      if (t.setIndex != currentLegSet || t.legIndex != currentLegLeg) {
        currentLegSet = t.setIndex;
        currentLegLeg = t.legIndex;
        liveScores = {for (final p in scoreOwnerIds) p: legStartScore};
        cricket = CricketMarksState.empty(scoreOwnerIds);
      }

      // Make sure legWinners has a slot for this set and leg index
      // (overtime grows both dimensions beyond baseGame.sets/legs).
      ensureLegSlot(t.setIndex, t.legIndex + 1);

      // If this leg already has a winner, skip subsequent darts in
      // the same leg (defensive — shouldn't normally happen).
      if (legWinners[t.setIndex][t.legIndex] != null) {
        lastApplied = t;
        continue;
      }

      if (mode == 'cricket') {
        final scoreOwnerId = baseGame.scoreOwnerForPlayer(t.playerId);
        if (t.cricketTarget != null && !t.isMiss && !t.isBust) {
          final marksForTarget = <String, int>{};
          for (final pid in scoreOwnerIds) {
            marksForTarget[pid] =
                cricket.marksByPlayer[pid]?[t.cricketTarget!] ?? 0;
          }
          final basePoints = t.cricketTarget == 'bull'
              ? 25
              : (int.tryParse(t.cricketTarget!) ?? 0);
          final earned = computePointsFromOverflow(
            playerMarksOnTarget: marksForTarget,
            playerId: scoreOwnerId,
            target: t.cricketTarget!,
            multiplierApplied: t.multiplier,
            basePoints: basePoints,
          );
          cricket = computeMarksAfterThrow(
            currentState: cricket,
            playerId: scoreOwnerId,
            target: t.cricketTarget!,
            multiplier: t.multiplier,
          );
          if (earned > 0) {
            final newPoints = Map<String, int>.from(cricket.pointsByPlayer);
            newPoints[scoreOwnerId] = (newPoints[scoreOwnerId] ?? 0) + earned;
            cricket = cricket.copyWith(pointsByPlayer: newPoints);
          }
          // Cricket leg-winner check
          if (isCricketWinner(
            state: cricket,
            playerId: scoreOwnerId,
            playerIds: scoreOwnerIds,
          )) {
            legWinners[t.setIndex][t.legIndex] = scoreOwnerId;
          }
        }
      } else {
        final scoreOwnerId = baseGame.scoreOwnerForPlayer(t.playerId);
        // 501/301: void entire turn if it contains any bust dart
        final turnKey =
            '$scoreOwnerId|${t.setIndex}|${t.legIndex}|${t.turnIndex}';
        final turnBusted = bustedTurns.contains(turnKey);

        if (!turnBusted && !t.isMiss) {
          final remainingBefore = liveScores[scoreOwnerId] ?? legStartScore;
          final remainingAfter = remainingBefore - t.points;
          liveScores[scoreOwnerId] = remainingAfter;

          // Leg winner: reached 0 with valid checkout
          if (remainingAfter == 0) {
            final valid = isValidCheckout(
              remainingBefore: remainingBefore,
              dartPoints: t.points,
              dartMultiplier: t.multiplier,
              doubleOut: baseGame.doubleOut,
            );
            if (valid) {
              legWinners[t.setIndex][t.legIndex] = scoreOwnerId;
            }
          }
        }
      }

      lastApplied = t;
    }

    // Compute set winners. Threshold is fixed at ceil(legs/2) and
    // ceil(sets/2) — NEITHER inflates as overtime legs/sets are
    // appended. setWinners may grow past baseGame.sets for set
    // overtime.
    final setWinners = <String?>[
      for (var s = 0; s < legWinners.length; s++)
        setWinner(legWinners[s], legsPerSet: baseGame.legs),
    ];
    final gWinner = gameWinner(setWinners, setsPerGame: baseGame.sets);

    // Determine current cursor
    int curSet, curLeg, curTurnIdx, curDartIdx;
    if (lastApplied == null) {
      curSet = 0;
      curLeg = 0;
      curTurnIdx = 0;
      curDartIdx = 0;
    } else {
      final last = lastApplied;
      final lastScoreOwnerId = baseGame.scoreOwnerForPlayer(last.playerId);
      final legWonByLast =
          legWinners[last.setIndex][last.legIndex] == lastScoreOwnerId &&
              !last.isBust &&
              !last.isMiss;

      if (legWonByLast) {
        // Advance to next leg / set. If the set has a winner (someone
        // reached the legs threshold), advance to next set. Otherwise
        // play the next leg in the same set — even if past the
        // configured leg count (OVERTIME).
        if (isSetOver(
          legsPerSet: baseGame.legs,
          legWinnersInSet: legWinners[last.setIndex],
        )) {
          curSet = last.setIndex + 1;
          curLeg = 0;
        } else {
          curSet = last.setIndex;
          curLeg = last.legIndex + 1;
        }
        curTurnIdx = 0;
        curDartIdx = 0;
        // Reset live scores for new leg unless the game is over.
        if (gWinner == null) {
          liveScores = {for (final p in scoreOwnerIds) p: legStartScore};
          cricket = CricketMarksState.empty(scoreOwnerIds);
        }
      } else {
        curSet = last.setIndex;
        curLeg = last.legIndex;
        final turnComplete = last.isBust || last.dartIndex == 2;
        if (turnComplete) {
          curTurnIdx = last.turnIndex + 1;
          curDartIdx = 0;
        } else {
          curTurnIdx = last.turnIndex;
          curDartIdx = last.dartIndex + 1;
        }
      }
    }

    // Determine current player based on starterOrder + turn rotation.
    // gWinner != null means the game is over → no current player.
    String currentPlayerId = '';
    if (gWinner == null &&
        baseGame.playerIds.isNotEmpty &&
        baseGame.starterOrder.isNotEmpty) {
      final globalLeg = curSet * baseGame.legs + curLeg;
      final starter = nextStarter(
        starterOrder: baseGame.starterOrder,
        globalLegIndex: globalLeg,
      );
      final starterIdx = baseGame.playerIds.indexOf(starter);
      if (starterIdx >= 0) {
        currentPlayerId = baseGame
            .playerIds[(starterIdx + curTurnIdx) % baseGame.playerIds.length];
      }
    }

    final updatedGame = baseGame.copyWith(
      currentSet: curSet,
      currentLeg: curLeg,
      currentTurnPlayerId: currentPlayerId,
      currentTurnIndex: curTurnIdx,
      currentDartIndex: curDartIdx,
      legWinners: legWinners,
      setWinners: setWinners,
      winnerId: gWinner,
      // copyWith uses `?? this`, so passing null alone won't clear a
      // previously-set winner (e.g. when reopening a finished game).
      clearWinnerId: gWinner == null,
      rosterLocked: throws_.isNotEmpty || baseGame.rosterLocked,
      status: gWinner != null ? 'finished' : baseGame.status,
    );

    return DardosGameState(
      status: gWinner != null
          ? DardosGameStatus.gameFinished
          : DardosGameStatus.loaded,
      game: updatedGame,
      throws: throws_,
      liveScores: liveScores,
      cricketState: mode == 'cricket' ? cricket : null,
      annotatorOwned: state.annotatorOwned,
      bannerType: DardosBannerType.none,
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  List<DardosThrowEntity> _sortThrows(List<DardosThrowEntity> throws_) {
    final sorted = [...throws_];
    sorted.sort((a, b) {
      if (a.setIndex != b.setIndex) return a.setIndex.compareTo(b.setIndex);
      if (a.legIndex != b.legIndex) return a.legIndex.compareTo(b.legIndex);
      if (a.turnIndex != b.turnIndex) return a.turnIndex.compareTo(b.turnIndex);
      return a.dartIndex.compareTo(b.dartIndex);
    });
    return sorted;
  }

  DardosBannerType _bannerForLastEvent({
    required DardosGameState previousState,
    required DardosGameState newState,
    required DardosThrowEntity lastThrow,
  }) {
    if (newState.game?.winnerId != null) return DardosBannerType.gameWon;
    // Set just won?
    final newSetWinners = newState.game?.setWinners ?? const [];
    final oldSetWinners = previousState.game?.setWinners ?? const [];
    for (var i = 0; i < newSetWinners.length; i++) {
      final wasNull = i >= oldSetWinners.length || oldSetWinners[i] == null;
      if (wasNull && newSetWinners[i] != null) {
        return DardosBannerType.setWon;
      }
    }
    // Leg just won?
    final newLW = newState.game?.legWinners ?? const [];
    final oldLW = previousState.game?.legWinners ?? const [];
    for (var s = 0; s < newLW.length; s++) {
      for (var l = 0; l < newLW[s].length; l++) {
        final oldVal =
            (s < oldLW.length && l < oldLW[s].length) ? oldLW[s][l] : null;
        if (oldVal == null && newLW[s][l] != null) {
          return DardosBannerType.legWon;
        }
      }
    }
    if (lastThrow.isBust) return DardosBannerType.bust;
    return DardosBannerType.none;
  }

  /// Aggregate (number, multiplier) frequency per player.
  /// Key format: "{number}_{multiplier}" — e.g. "20_3" = T20 hits.
  /// Bust darts are NOT counted (the turn was voided). Miss darts go
  /// to "0_1". Skipped/empty turns contribute nothing.
  Map<String, Map<String, int>> _computeFreqByPlayer({
    required List<String> playerIds,
    required List<DardosThrowEntity> throws_,
  }) {
    final result = <String, Map<String, int>>{
      for (final p in playerIds) p: <String, int>{},
    };
    // Pre-compute busted turns to skip them entirely
    final bustedTurns = <String>{};
    for (final t in throws_) {
      if (t.isBust) {
        bustedTurns
            .add('${t.playerId}|${t.setIndex}|${t.legIndex}|${t.turnIndex}');
      }
    }
    for (final t in throws_) {
      final turnKey =
          '${t.playerId}|${t.setIndex}|${t.legIndex}|${t.turnIndex}';
      if (bustedTurns.contains(turnKey)) continue;
      final key = t.isMiss ? '0_1' : '${t.number}_${t.multiplier}';
      final freq = result[t.playerId];
      if (freq != null) {
        freq[key] = (freq[key] ?? 0) + 1;
      }
    }
    return result;
  }

  Map<String, dynamic> _computeMetrics({
    required String mode,
    required List<String> playerIds,
    required List<DardosThrowEntity> throws_,
  }) {
    final perPlayer = <String, dynamic>{};
    for (final pid in playerIds) {
      final playerThrows = throws_.where((t) => t.playerId == pid).toList();
      if (mode == 'cricket') {
        final totalMarks = playerThrows.fold<int>(
          0,
          (sum, t) => sum + (t.cricketMarksDelta ?? 0),
        );
        final rounds = playerThrows
            .map((t) => '${t.setIndex}_${t.legIndex}_${t.turnIndex}')
            .toSet()
            .length;
        final mpr = rounds > 0 ? totalMarks / rounds : 0.0;
        final closes = throws_
            .where((t) =>
                t.playerId == pid &&
                t.cricketMarksDelta != null &&
                t.cricketMarksDelta! > 0)
            .map((t) => t.cricketTarget)
            .toSet()
            .length;
        perPlayer[pid] = {'mpr': mpr, 'closes': closes};
      } else {
        final turns = <String, List<DardosThrowEntity>>{};
        for (final t in playerThrows) {
          final key = '${t.setIndex}_${t.legIndex}_${t.turnIndex}';
          turns.putIfAbsent(key, () => []).add(t);
        }
        var totalPts = 0;
        var validTurns = 0;
        var bestTurn = 0;
        var count180 = 0;
        var count140plus = 0;
        for (final turnThrows in turns.values) {
          final bustInTurn = turnThrows.any((t) => t.isBust);
          if (bustInTurn) continue;
          final turnPts = turnThrows.fold<int>(0, (s, t) => s + t.points);
          totalPts += turnPts;
          validTurns++;
          if (turnPts > bestTurn) bestTurn = turnPts;
          if (turnPts == 180) count180++;
          if (turnPts >= 140) count140plus++;
        }
        perPlayer[pid] = {
          'avg3Dart': validTurns > 0 ? totalPts / validTurns : 0.0,
          'bestTurn': bestTurn,
          'count180': count180,
          'count140plus': count140plus,
          // Raw sums consumed by the data source to accumulate
          // lifetime stats per mode on the participant doc.
          'totalPoints': totalPts,
          'validTurns': validTurns,
        };
      }
    }
    return {'perPlayer': perPlayer};
  }
}
