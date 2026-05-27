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
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/annotator_lock_banner.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/auto_advance_banner.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/cricket_board.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/leg_set_indicator.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/player_dart_card.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/throw_input_grid.dart';

class DardosGamePlayPage extends StatefulWidget {
  final String gameId;

  const DardosGamePlayPage({Key? key, required this.gameId}) : super(key: key);

  @override
  State<DardosGamePlayPage> createState() => _DardosGamePlayPageState();
}

class _DardosGamePlayPageState extends State<DardosGamePlayPage> {
  late final String _deviceId;

  @override
  void initState() {
    super.initState();
    _deviceId = '${DateTime.now().millisecondsSinceEpoch}';

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
    context.read<DardosGameBloc>().add(
          ReleaseAnnotatorEvent(
            gameId: widget.gameId,
            deviceId: _deviceId,
          ),
        );
    super.dispose();
  }

  List<DardosThrowEntity> _currentTurnDarts(
    DardosGameState state,
    String playerId,
  ) {
    final game = state.game;
    if (game == null) return [];
    return state.throws
        .where((t) =>
            t.playerId == playerId &&
            t.setIndex == game.currentSet &&
            t.legIndex == game.currentLeg &&
            t.turnIndex == game.currentTurnIndex)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.read<DardosGameBloc>().add(
              ReleaseAnnotatorEvent(
                gameId: widget.gameId,
                deviceId: _deviceId,
              ),
            );
        return true;
      },
      child: BlocConsumer<DardosGameBloc, DardosGameState>(
        listener: (context, state) {
          final gameFinished = state.status ==
                  DardosGameStatus.gameFinished ||
              (state.game?.winnerId != null && state.game?.winnerId != '');
          if (gameFinished) {
            if (!mounted) return;
            context.read<DardosMultiGameBloc>().add(LoadGamesEvent());
            context
                .read<DardosParticipantBloc>()
                .add(FetchAllParticipantsEvent());
            Navigator.of(context).pushReplacementNamed(
              AppRouteNames.dardosFinished,
              arguments: widget.gameId,
            );
          }
          if (state.status == DardosGameStatus.error &&
              state.error != null) {
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
            body: (state.status == DardosGameStatus.loading ||
                    game == null)
                ? const Center(child: CircularProgressIndicator())
                : (game.winnerId != null)
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events,
                                  size: 72, color: Colors.amber),
                              SizedBox(height: 12),
                              Text(
                                'Partida terminada',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Redirigiendo al resumen…',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : BlocBuilder<DardosParticipantBloc, DardosParticipantState>(
                    builder: (context, participantState) {
                      final participantNames = <String, String>{
                        for (final p in participantState.participants)
                          p.id: p.name,
                      };

                      return Stack(
                        children: [
                          Column(
                            children: [
                              LegSetIndicator(
                                currentSet: game.currentSet,
                                totalSets: game.sets,
                                currentLeg: game.currentLeg,
                                totalLegs: game.legs,
                                playerIds: game.playerIds,
                                playerNames: participantNames,
                                legWinners: game.legWinners,
                                setWinners: game.setWinners,
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
                                            playerIds: game.playerIds,
                                            playerNames: participantNames,
                                            cricketState:
                                                state.cricketState ??
                                                    CricketMarksState.empty(
                                                        game.playerIds),
                                            currentPlayerId:
                                                game.currentTurnPlayerId,
                                            enabled: state.annotatorOwned,
                                            onThrow: (target, mult) {
                                              final number = target == 'bull'
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
                                      icon: const Icon(Icons.undo, size: 20),
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
                                  children: game.playerIds.map((playerId) {
                                    final isCurrentTurn = playerId ==
                                        game.currentTurnPlayerId;
                                    final turnDarts = isCurrentTurn
                                        ? _currentTurnDarts(state, playerId)
                                        : <DardosThrowEntity>[];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 4),
                                      child: PlayerDartCard(
                                        name: participantNames[playerId] ??
                                            playerId,
                                        isCurrentTurn: isCurrentTurn,
                                        mode: game.mode,
                                        remainingScore:
                                            state.liveScores[playerId],
                                        cricketPoints: state
                                            .cricketState
                                            ?.pointsByPlayer[playerId],
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
