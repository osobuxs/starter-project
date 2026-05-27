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

    emit(state.copyWith(status: DardosGameStatus.loading));

    final result = await _repository.createGame(
      name: event.name,
      mode: event.mode,
      doubleOut: event.doubleOut,
      sets: event.sets,
      legs: event.legs,
      playerIds: event.playerIds,
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
    final points = event.isMiss ? 0 : event.number * event.multiplier;

    // Determine isBust / remainingAfter for 501/301 using the *recomputed*
    // current score (single source of truth = throws collection).
    int? remainingAfter;
    bool isBust_ = false;

    if (!event.isMiss && (mode == '501' || mode == '301')) {
      final currentRemaining = state.liveScores[playerId] ??
          (mode == '501' ? 501 : 301);
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
          : (event.number >= 15 && event.number <= 20 ? '${event.number}' : null);
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

    // 1. Optimistic local update — recompute and emit FIRST
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

    emit(optimistic.copyWith(
      annotatorOwned: state.annotatorOwned,
      bannerType: bannerType,
      bannerPayload: optimistic.game?.winnerId,
      status: bannerType == DardosBannerType.gameWon
          ? DardosGameStatus.gameFinished
          : (bannerType == DardosBannerType.bust
              ? DardosGameStatus.bustDetected
              : (bannerType == DardosBannerType.legWon
                  ? DardosGameStatus.legWon
                  : DardosGameStatus.throwRecorded)),
    ));

    // 2. Persist throw in background
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

    // 4. Update game progress (cursor + winners) in background
    final rg = optimistic.game;
    if (rg != null) {
      // Don't await — fire and let it sync. UI is already current.
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

    // 5. If game finished, persist final state + stats
    if (optimistic.game?.winnerId != null && rg != null) {
      final metrics = _computeMetrics(
        mode: rg.mode,
        playerIds: rg.playerIds,
        throws_: finalThrows,
      );
      await _repository.finishGame(
        gameId: rg.id,
        winnerId: rg.winnerId!,
        computedMetrics: metrics,
      );
      await _repository.updateParticipantStatsOnGameFinished(
        playerIds: rg.playerIds,
        winnerId: rg.winnerId!,
        mode: rg.mode,
        metricsPerPlayer:
            metrics['perPlayer'] as Map<String, dynamic>? ?? {},
      );
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
    final legStartScore =
        mode == '501' ? 501 : (mode == '301' ? 301 : 0);

    // Pre-compute which (player, set, leg, turn) tuples have a bust.
    // Used to void entire turns when summing.
    final bustedTurns = <String>{};
    for (final t in throws_) {
      if (t.isBust) {
        bustedTurns.add(
            '${t.playerId}|${t.setIndex}|${t.legIndex}|${t.turnIndex}');
      }
    }

    final legWinners = List<List<String?>>.generate(
      baseGame.sets,
      (_) => List<String?>.filled(baseGame.legs, null),
    );

    var liveScores = <String, int>{
      for (final p in baseGame.playerIds) p: legStartScore,
    };
    var cricket = CricketMarksState.empty(baseGame.playerIds);

    // Walk throws in order, applying each one.
    var currentLegSet = -1;
    var currentLegLeg = -1;
    var lastApplied = throws_.isEmpty ? null : throws_.first;

    for (final t in throws_) {
      // New leg detected → reset scores
      if (t.setIndex != currentLegSet || t.legIndex != currentLegLeg) {
        currentLegSet = t.setIndex;
        currentLegLeg = t.legIndex;
        liveScores = {
          for (final p in baseGame.playerIds) p: legStartScore,
        };
        cricket = CricketMarksState.empty(baseGame.playerIds);
      }

      // If this leg already has a winner, skip subsequent darts in same leg
      // (defensive — shouldn't normally happen).
      if (legWinners[t.setIndex][t.legIndex] != null) {
        lastApplied = t;
        continue;
      }

      if (mode == 'cricket') {
        if (t.cricketTarget != null && !t.isMiss && !t.isBust) {
          final marksForTarget = <String, int>{};
          for (final pid in baseGame.playerIds) {
            marksForTarget[pid] =
                cricket.marksByPlayer[pid]?[t.cricketTarget!] ?? 0;
          }
          final basePoints = t.cricketTarget == 'bull'
              ? 25
              : (int.tryParse(t.cricketTarget!) ?? 0);
          final earned = computePointsFromOverflow(
            playerMarksOnTarget: marksForTarget,
            playerId: t.playerId,
            target: t.cricketTarget!,
            multiplierApplied: t.multiplier,
            basePoints: basePoints,
          );
          cricket = computeMarksAfterThrow(
            currentState: cricket,
            playerId: t.playerId,
            target: t.cricketTarget!,
            multiplier: t.multiplier,
          );
          if (earned > 0) {
            final newPoints = Map<String, int>.from(cricket.pointsByPlayer);
            newPoints[t.playerId] =
                (newPoints[t.playerId] ?? 0) + earned;
            cricket = cricket.copyWith(pointsByPlayer: newPoints);
          }
          // Cricket leg-winner check
          if (isCricketWinner(
            state: cricket,
            playerId: t.playerId,
            playerIds: baseGame.playerIds,
          )) {
            legWinners[t.setIndex][t.legIndex] = t.playerId;
          }
        }
      } else {
        // 501/301: void entire turn if it contains any bust dart
        final turnKey =
            '${t.playerId}|${t.setIndex}|${t.legIndex}|${t.turnIndex}';
        final turnBusted = bustedTurns.contains(turnKey);

        if (!turnBusted && !t.isMiss) {
          final remainingBefore =
              liveScores[t.playerId] ?? legStartScore;
          final remainingAfter = remainingBefore - t.points;
          liveScores[t.playerId] = remainingAfter;

          // Leg winner: reached 0 with valid checkout
          if (remainingAfter == 0) {
            final valid = isValidCheckout(
              remainingBefore: remainingBefore,
              dartPoints: t.points,
              dartMultiplier: t.multiplier,
              doubleOut: baseGame.doubleOut,
            );
            if (valid) {
              legWinners[t.setIndex][t.legIndex] = t.playerId;
            }
          }
        }
      }

      lastApplied = t;
    }

    // Compute set winners
    final setWinners = List<String?>.filled(baseGame.sets, null);
    for (var s = 0; s < baseGame.sets; s++) {
      setWinners[s] = setWinner(legWinners[s]);
    }
    final gWinner = gameWinner(setWinners);

    // Determine current cursor
    int curSet, curLeg, curTurnIdx, curDartIdx;
    if (lastApplied == null) {
      curSet = 0;
      curLeg = 0;
      curTurnIdx = 0;
      curDartIdx = 0;
    } else {
      final last = lastApplied;
      final legWonByLast =
          legWinners[last.setIndex][last.legIndex] == last.playerId &&
              !last.isBust &&
              !last.isMiss;

      if (legWonByLast) {
        // Advance to next leg / set
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
        // Reset live scores for new leg (if within bounds)
        if (curSet < baseGame.sets) {
          liveScores = {
            for (final p in baseGame.playerIds) p: legStartScore,
          };
          cricket = CricketMarksState.empty(baseGame.playerIds);
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

    // Determine current player based on starterOrder + turn rotation
    String currentPlayerId = '';
    if (baseGame.playerIds.isNotEmpty &&
        baseGame.starterOrder.isNotEmpty &&
        curSet < baseGame.sets) {
      final globalLeg = curSet * baseGame.legs + curLeg;
      final starter = nextStarter(
        starterOrder: baseGame.starterOrder,
        globalLegIndex: globalLeg,
      );
      final starterIdx = baseGame.playerIds.indexOf(starter);
      if (starterIdx >= 0) {
        currentPlayerId = baseGame.playerIds[
            (starterIdx + curTurnIdx) % baseGame.playerIds.length];
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
          'checkouts': 0,
          'checkoutAttempts': 0,
          'checkoutPct': 0.0,
        };
      }
    }
    return {'perPlayer': perPlayer};
  }
}
