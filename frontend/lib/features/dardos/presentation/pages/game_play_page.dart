import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/cricket_marks_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_state.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_state.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/services/dardos_audio_controller.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/annotator_lock_banner.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/auto_advance_banner.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/cricket_board.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/leg_set_indicator.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/player_dart_card.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/throw_input_grid.dart';

class DardosGamePlayPage extends StatefulWidget {
  final String gameId;

  const DardosGamePlayPage({super.key, required this.gameId});

  @override
  State<DardosGamePlayPage> createState() => _DardosGamePlayPageState();
}

class _DardosGamePlayPageState extends State<DardosGamePlayPage> {
  late final String _deviceId;
  late final DardosAudioController _audioController;
  String? _lastAnnouncedThrowKey;
  String? _lastBannerKey;
  bool _navigatedToFinished = false;

  @override
  void initState() {
    super.initState();
    _deviceId = '${DateTime.now().millisecondsSinceEpoch}';
    _audioController = DardosAudioController();

    final bloc = context.read<DardosGameBloc>();
    bloc.add(LoadDardosGameEvent(gameId: widget.gameId));
    bloc.add(AcquireAnnotatorEvent(
      gameId: widget.gameId,
      deviceId: _deviceId,
    ));

    final participantBloc = context.read<DardosParticipantBloc>();
    if (participantBloc.state.participants.isEmpty) {
      participantBloc.add(FetchAllParticipantsEvent());
    }
    participantBloc.add(CheckAdminStatusEvent());
  }

  @override
  void dispose() {
    _audioController.dispose();
    context.read<DardosGameBloc>().add(
          ReleaseAnnotatorEvent(
            gameId: widget.gameId,
            deviceId: _deviceId,
          ),
        );
    super.dispose();
  }

  String? _throwPlaybackKey(DardosThrowEntity? throw_) {
    if (throw_ == null) return null;
    return [
      throw_.playerId,
      throw_.setIndex,
      throw_.legIndex,
      throw_.turnIndex,
      throw_.dartIndex,
      throw_.timestamp,
      throw_.number,
      throw_.multiplier,
      throw_.isMiss,
      throw_.isBust,
    ].join('|');
  }

  void _handleAudioFeedback(DardosGameState state) {
    final lastThrow = state.throws.isEmpty ? null : state.throws.last;
    final throwKey = _throwPlaybackKey(lastThrow);
    if (throwKey != null && throwKey != _lastAnnouncedThrowKey) {
      _lastAnnouncedThrowKey = throwKey;
      final spokenScore = lastThrow!.isMiss ? 0 : lastThrow.points;
      _audioController.speakScore(spokenScore);
    }

    final bannerKey = '${state.bannerType}|${state.bannerPayload ?? ''}';
    if (state.bannerType != DardosBannerType.none &&
        bannerKey != _lastBannerKey) {
      _lastBannerKey = bannerKey;
      switch (state.bannerType) {
        case DardosBannerType.bust:
          _audioController.playBust();
          break;
        case DardosBannerType.legWon:
          _audioController.playLegWon();
          break;
        case DardosBannerType.gameWon:
          _audioController.playGameWon();
          break;
        case DardosBannerType.setWon:
        case DardosBannerType.none:
          break;
      }
    }

    if (state.bannerType == DardosBannerType.none) {
      _lastBannerKey = null;
    }
  }

  /// Navigates to the finished summary exactly once. Safe to call from both
  /// the BlocConsumer listener and the builder (post-frame) — the guard makes
  /// sure the user is never stuck on the "Redirigiendo…" screen.
  void _goToFinished() {
    if (_navigatedToFinished || !mounted) return;
    _navigatedToFinished = true;
    final multi = context.read<DardosMultiGameBloc>();
    final participantBloc = context.read<DardosParticipantBloc>();
    final nav = Navigator.of(context);
    multi.add(LoadGamesEvent());
    participantBloc.add(FetchAllParticipantsEvent());
    nav.pushReplacementNamed(
      AppRouteNames.dardosFinished,
      arguments: widget.gameId,
    );
  }

  List<DardosThrowEntity> _displayDartsForOwner(
    DardosGameState state,
    String ownerId,
  ) {
    final game = state.game;
    if (game == null) return const [];
    final isCurrentTurn =
        ownerId == game.scoreOwnerForPlayer(game.currentTurnPlayerId);
    final playerIds = game.teamMode
        ? (game.teams.firstWhere(
              (t) => t['id'] == ownerId,
              orElse: () => const <String, dynamic>{},
            )['playerIds'] as List?)
                ?.whereType<String>()
                .toList() ??
            const <String>[]
        : [ownerId];
    final matchingThrows = state.throws
        .where((t) =>
            playerIds.contains(t.playerId) &&
            t.setIndex == game.currentSet &&
            t.legIndex == game.currentLeg)
        .toList();

    if (matchingThrows.isEmpty) return const [];

    // If the owner is currently on turn, show the active player's darts.
    // Otherwise show the most recent completed turn for that owner/team.
    if (isCurrentTurn) {
      final currentPlayerThrows = matchingThrows
          .where((t) =>
              t.playerId == game.currentTurnPlayerId &&
              t.turnIndex == game.currentTurnIndex)
          .toList();
      if (currentPlayerThrows.isNotEmpty) return currentPlayerThrows;
    }

    // Not on turn (or on turn but hasn't thrown yet): show this owner's
    // most recent COMPLETED turn — the HIGHEST turnIndex they own.
    // turnIndex is GLOBAL/sequential across all players, so each owner
    // holds a sparse set of indexes (0,2,4… / 1,3,5…). Take the max of
    // THIS owner's throws — never offset it.
    final lastTurnIdx = matchingThrows
        .map((t) => t.turnIndex)
        .reduce((a, b) => a > b ? a : b);
    return matchingThrows.where((t) => t.turnIndex == lastTurnIdx).toList();
  }

  int? _displayTurnIndexForOwner(
    DardosGameState state,
    String ownerId,
  ) {
    final game = state.game;
    if (game == null) return null;
    final playerIds = game.teamMode
        ? (game.teams.firstWhere(
              (t) => t['id'] == ownerId,
              orElse: () => const <String, dynamic>{},
            )['playerIds'] as List?)
                ?.whereType<String>()
                .toList() ??
            const <String>[]
        : [ownerId];
    final matchingThrows = state.throws
        .where((t) =>
            playerIds.contains(t.playerId) &&
            t.setIndex == game.currentSet &&
            t.legIndex == game.currentLeg)
        .toList();
    if (matchingThrows.isEmpty) return null;
    final isCurrentTurn =
        ownerId == game.scoreOwnerForPlayer(game.currentTurnPlayerId);
    // Keep this in lock-step with _displayDartsForOwner so the label
    // always matches the darts shown.
    if (isCurrentTurn) {
      final hasCurrentThrows = matchingThrows.any((t) =>
          t.playerId == game.currentTurnPlayerId &&
          t.turnIndex == game.currentTurnIndex);
      if (hasCurrentThrows) return game.currentTurnIndex;
    }
    return matchingThrows
        .map((t) => t.turnIndex)
        .reduce((a, b) => a > b ? a : b);
  }

  String _teamName(Map<String, dynamic> team) =>
      team['name'] as String? ?? team['id'] as String? ?? 'Equipo';

  Map<String, String> _scoreOwnerNames(
    DardosGameState state,
    Map<String, String> participantNames,
  ) {
    final game = state.game;
    if (game == null || !game.teamMode) return participantNames;
    return {
      for (final team in game.teams) team['id'] as String: _teamName(team),
    };
  }

  String _teamCardSubtitle(
    Map<String, dynamic> team,
    Map<String, String> participantNames,
  ) {
    final players = List<String>.from((team['playerIds'] as List?) ?? []);
    return players.map((id) => participantNames[id] ?? id).join(' / ');
  }

  String? _liveAverageText(
    DardosGameState state,
    String ownerId,
  ) {
    final game = state.game;
    if (game == null) return null;
    final playerIds = game.teamMode
        ? (game.teams.firstWhere(
              (t) => t['id'] == ownerId,
              orElse: () => const <String, dynamic>{},
            )['playerIds'] as List?)
                ?.whereType<String>()
                .toList() ??
            const <String>[]
        : [ownerId];
    final throwsInLeg = state.throws.where((t) {
      return playerIds.contains(t.playerId) &&
          t.setIndex == game.currentSet &&
          t.legIndex == game.currentLeg &&
          !t.isBust;
    }).toList();
    if (throwsInLeg.isEmpty) return null;

    final turns = <String, List<DardosThrowEntity>>{};
    for (final t in throwsInLeg) {
      turns.putIfAbsent('${t.playerId}_${t.turnIndex}', () => []).add(t);
    }

    var totalPoints = 0;
    var validTurns = 0;
    for (final turnThrows in turns.values) {
      if (turnThrows.any((t) => t.isBust)) continue;
      totalPoints += turnThrows.fold<int>(0, (sum, t) => sum + t.points);
      validTurns++;
    }
    if (validTurns == 0) return null;
    return 'Avg ${(totalPoints / validTurns).toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        context.read<DardosGameBloc>().add(
              ReleaseAnnotatorEvent(
                gameId: widget.gameId,
                deviceId: _deviceId,
              ),
            );
      },
      child: BlocConsumer<DardosGameBloc, DardosGameState>(
        listenWhen: (prev, curr) {
          final prevThrowKey =
              prev.throws.isEmpty ? null : _throwPlaybackKey(prev.throws.last);
          final currThrowKey =
              curr.throws.isEmpty ? null : _throwPlaybackKey(curr.throws.last);
          if (prevThrowKey != currThrowKey) {
            return true;
          }
          if (prev.bannerType != curr.bannerType ||
              prev.bannerPayload != curr.bannerPayload) {
            return true;
          }
          // 1) If state arrives ALREADY with a winner (came back to a
          //    finished game, no banner shown) → navigate.
          final hadWinnerBefore = prev.game?.winnerId != null;
          final hasWinnerNow = curr.game?.winnerId != null;
          if (!hadWinnerBefore &&
              hasWinnerNow &&
              curr.bannerType != DardosBannerType.gameWon) {
            return true;
          }
          // 2) Banner just dismissed AFTER gameWon → navigate.
          if (prev.bannerType == DardosBannerType.gameWon &&
              curr.bannerType != DardosBannerType.gameWon &&
              hasWinnerNow) {
            return true;
          }
          return curr.status == DardosGameStatus.error;
        },
        listener: (context, state) {
          _handleAudioFeedback(state);
          if (state.game?.winnerId != null) {
            // If the victory banner is still visible, wait for it to
            // dismiss so the final writes have time to land.
            if (state.bannerType == DardosBannerType.gameWon) {
              return;
            }
            if (!mounted) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _goToFinished();
            });
            return;
          }
          if (state.status == DardosGameStatus.error && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          final game = state.game;

          return Scaffold(
            appBar: AppBar(
              title: Text(game?.name ?? 'Dardos'),
            ),
            body: (state.status == DardosGameStatus.loading || game == null)
                ? const Center(child: CircularProgressIndicator())
                : (game.winnerId != null)
                    ? Builder(
                        builder: (context) {
                          // Fallback: if the listener transition never fired,
                          // navigate from here so the user is never stuck.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (state.bannerType != DardosBannerType.gameWon) {
                              _goToFinished();
                            }
                          });
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.emoji_events,
                                      size: 72, color: Colors.amber),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Partida terminada',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Redirigiendo al resumen…',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 24),
                                  TextButton.icon(
                                    onPressed: _goToFinished,
                                    icon: const Icon(Icons.arrow_forward),
                                    label: const Text('Ver resumen ahora'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : BlocBuilder<DardosParticipantBloc,
                        DardosParticipantState>(
                        builder: (context, participantState) {
                          final participantNames = <String, String>{
                            for (final p in participantState.participants)
                              p.id: p.name,
                          };
                          final scoreOwnerIds = game.scoreOwnerIds;
                          final scoreOwnerNames =
                              _scoreOwnerNames(state, participantNames);

                          return Stack(
                            children: [
                              Column(
                                children: [
                                  LegSetIndicator(
                                    currentSet: game.currentSet,
                                    totalSets: game.sets,
                                    currentLeg: game.currentLeg,
                                    totalLegs: game.legs,
                                    playerIds: scoreOwnerIds,
                                    playerNames: scoreOwnerNames,
                                    legWinners: game.legWinners,
                                    setWinners: game.setWinners,
                                    mode: game.mode,
                                    doubleOut: game.doubleOut,
                                  ),
                                  AnnotatorLockBanner(
                                    annotatorOwned: state.annotatorOwned,
                                    onTakeControl: () {
                                      context.read<DardosGameBloc>().add(
                                            AcquireAnnotatorEvent(
                                              gameId: widget.gameId,
                                              deviceId: _deviceId,
                                            ),
                                          );
                                    },
                                  ),
                                  if (participantState.isAdmin &&
                                      !state.annotatorOwned)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 4),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            context
                                                .read<DardosGameBloc>()
                                                .add(ReleaseAnnotatorEvent(
                                                  gameId: widget.gameId,
                                                  deviceId: _deviceId,
                                                ));
                                          },
                                          child: const Text(
                                              'Forzar liberación de anotador'),
                                        ),
                                      ),
                                    ),
                                  // Grid takes the upper half of the screen
                                  Expanded(
                                    flex: 6,
                                    child: game.mode == 'cricket'
                                        ? SingleChildScrollView(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: CricketBoard(
                                                playerIds: scoreOwnerIds,
                                                playerNames: scoreOwnerNames,
                                                cricketState:
                                                    state.cricketState ??
                                                        CricketMarksState.empty(
                                                            scoreOwnerIds),
                                                currentPlayerId: game
                                                    .scoreOwnerForPlayer(game
                                                        .currentTurnPlayerId),
                                                enabled: state.annotatorOwned,
                                                onThrow: (target, mult) {
                                                  final number =
                                                      target == 'bull'
                                                          ? 25
                                                          : target == '0'
                                                              ? 0
                                                              : (int.tryParse(
                                                                      target) ??
                                                                  0);
                                                  context
                                                      .read<DardosGameBloc>()
                                                      .add(RecordThrowEvent(
                                                        number: number,
                                                        multiplier: mult,
                                                        isMiss: target == '0',
                                                      ));
                                                },
                                              ),
                                            ),
                                          )
                                        : ThrowInputGrid(
                                            enabled: state.annotatorOwned,
                                            onThrow: (number, mult) {
                                              context
                                                  .read<DardosGameBloc>()
                                                  .add(RecordThrowEvent(
                                                    number: number,
                                                    multiplier: mult,
                                                    isMiss: number == 0,
                                                  ));
                                            },
                                          ),
                                  ),
                                  // Undo button — between grid and scoreboards
                                  if (state.annotatorOwned &&
                                      state.throws.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 40,
                                        child: OutlinedButton.icon(
                                          icon:
                                              const Icon(Icons.undo, size: 20),
                                          label: const Text(
                                            'Deshacer último dardo',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onPressed: () {
                                            context
                                                .read<DardosGameBloc>()
                                                .add(UndoLastThrowEvent());
                                          },
                                        ),
                                      ),
                                    ),
                                  // Player scoreboards — bottom portion
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: scoreOwnerIds.map((ownerId) {
                                        final isCurrentTurn = ownerId ==
                                            game.scoreOwnerForPlayer(
                                                game.currentTurnPlayerId);
                                        final currentPlayerId =
                                            game.currentTurnPlayerId;
                                        final turnDarts = _displayDartsForOwner(
                                            state, ownerId);
                                        final displayTurnIndex =
                                            _displayTurnIndexForOwner(
                                                state, ownerId);
                                        final team = game.teamMode
                                            ? game.teams.firstWhere(
                                                (t) => t['id'] == ownerId,
                                                orElse: () =>
                                                    const <String, dynamic>{},
                                              )
                                            : const <String, dynamic>{};
                                        final baseName =
                                            scoreOwnerNames[ownerId] ?? ownerId;
                                        final currentPlayerName =
                                            participantNames[currentPlayerId] ??
                                                currentPlayerId;
                                        final name = game.teamMode
                                            ? (isCurrentTurn
                                                ? '$baseName · Juega: $currentPlayerName'
                                                : '$baseName · ${_teamCardSubtitle(team, participantNames)}')
                                            : baseName;
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: PlayerDartCard(
                                            name: name,
                                            isCurrentTurn: isCurrentTurn,
                                            mode: game.mode,
                                            remainingScore:
                                                state.liveScores[ownerId],
                                            cricketPoints: state.cricketState
                                                ?.pointsByPlayer[ownerId],
                                            liveMetricText: _liveAverageText(
                                                state, ownerId),
                                            turnIndex: displayTurnIndex,
                                            currentTurnDarts: turnDarts,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                              if (state.bannerType != DardosBannerType.none)
                                Positioned.fill(
                                  child: AutoAdvanceBanner(
                                    bannerType: state.bannerType,
                                    bannerPayload: state.bannerPayload,
                                    onDismiss: () {
                                      context
                                          .read<DardosGameBloc>()
                                          .add(AcknowledgeBannerEvent());
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
          );
        },
      ),
    );
  }
}
