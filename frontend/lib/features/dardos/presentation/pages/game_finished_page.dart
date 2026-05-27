import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_state.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_state.dart';

class DardosGameFinishedPage extends StatefulWidget {
  final String gameId;

  const DardosGameFinishedPage({Key? key, required this.gameId})
      : super(key: key);

  @override
  State<DardosGameFinishedPage> createState() =>
      _DardosGameFinishedPageState();
}

class _DardosGameFinishedPageState extends State<DardosGameFinishedPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<DardosGameBloc>()
        .add(LoadDardosGameEvent(gameId: widget.gameId));

    final participantBloc = context.read<DardosParticipantBloc>();
    if (participantBloc.state.participants.isEmpty) {
      participantBloc.add(FetchAllParticipantsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partida terminada'),
      ),
      body: BlocBuilder<DardosGameBloc, DardosGameState>(
        builder: (context, state) {
          if (state.status == DardosGameStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final game = state.game;
          if (game == null) {
            return const Center(child: Text('Error al cargar la partida'));
          }

          return BlocBuilder<DardosParticipantBloc, DardosParticipantState>(
            builder: (context, participantState) {
              final participantNames = <String, String>{
                for (final p in participantState.participants) p.id: p.name,
              };

              final winnerId = game.winnerId;
              final winnerName = winnerId != null
                  ? (participantNames[winnerId] ?? winnerId)
                  : 'Sin ganador';

              return Column(
                children: [
                  // Winner banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: Colors.amber.shade100,
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events,
                            size: 48, color: Colors.amber),
                        const SizedBox(height: 8),
                        Text(
                          '¡Ganador: $winnerName!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${game.mode.toUpperCase()} · ${game.sets} set(s) · ${game.legs} leg(s)',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (game.mode != 'cricket')
                          Text(
                            game.doubleOut ? 'Double out' : 'Sin double out',
                            style: const TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),

                  // Metrics per player
                  if (game.computedMetrics != null) ...[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Métricas',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: game.playerIds.length,
                        itemBuilder: (context, index) {
                          final playerId = game.playerIds[index];
                          final name = participantNames[playerId] ?? playerId;
                          final isWinner = playerId == winnerId;

                          final metrics =
                              game.computedMetrics as Map<String, dynamic>?;
                          final perPlayer =
                              metrics?['perPlayer'] as Map<String, dynamic>?;
                          final playerMetrics =
                              perPlayer?[playerId] as Map<String, dynamic>?;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isWinner
                                  ? Colors.amber
                                  : Colors.grey.shade200,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isWinner
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(name),
                            subtitle: playerMetrics != null
                                ? _buildMetricsText(
                                    game.mode, playerMetrics, metrics)
                                : null,
                            trailing: isWinner
                                ? const Icon(Icons.emoji_events,
                                    color: Colors.amber)
                                : null,
                          );
                        },
                      ),
                    ),
                  ] else
                    Expanded(
                      child: ListView.builder(
                        itemCount: game.playerIds.length,
                        itemBuilder: (context, index) {
                          final playerId = game.playerIds[index];
                          final name = participantNames[playerId] ?? playerId;
                          final isWinner = playerId == winnerId;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isWinner
                                  ? Colors.amber
                                  : Colors.grey.shade200,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(name),
                            trailing: isWinner
                                ? const Icon(Icons.emoji_events,
                                    color: Colors.amber)
                                : null,
                          );
                        },
                      ),
                    ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRouteNames.dardos,
                                (route) => route.isFirst,
                              );
                            },
                            child: const Text('Volver'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showThrowsHistory(
                              context,
                              state,
                              participantNames,
                            ),
                            child: const Text('Ver tiradas'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showThrowsHistory(
    BuildContext ctx,
    DardosGameState state,
    Map<String, String> participantNames,
  ) {
    final throws = state.throws;
    if (throws.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Sin tiradas registradas')),
      );
      return;
    }
    final grouped =
        <String, List<dynamic>>{}; // key: setX_legY_turnZ_player → list of throws
    for (final t in throws) {
      final key =
          'Set ${t.setIndex + 1} · Leg ${t.legIndex + 1} · Turno ${t.turnIndex + 1} · ${participantNames[t.playerId] ?? t.playerId}';
      grouped.putIfAbsent(key, () => []).add(t);
    }
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Historial de tiradas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${throws.length} tiradas',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(8),
                    children: grouped.entries.map((entry) {
                      final darts = entry.value;
                      final turnTotal = darts.fold<int>(0, (s, t) {
                        if (t.isBust == true) return s;
                        return s + (t.points as int);
                      });
                      final hasBust =
                          darts.any((t) => t.isBust == true);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color:
                            hasBust ? Colors.red.shade50 : null,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    hasBust ? 'BUST' : 'Total: $turnTotal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: hasBust
                                          ? Colors.red
                                          : Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: darts.map<Widget>((t) {
                                  String label;
                                  Color bg;
                                  if (t.isBust == true) {
                                    label = 'BUST';
                                    bg = Colors.red.shade300;
                                  } else if (t.isMiss == true) {
                                    label = 'Miss';
                                    bg = Colors.grey.shade400;
                                  } else if (t.multiplier == 2) {
                                    label = 'D${t.number} (${t.points})';
                                    bg = Colors.blue.shade300;
                                  } else if (t.multiplier == 3) {
                                    label = 'T${t.number} (${t.points})';
                                    bg = Colors.deepPurple.shade300;
                                  } else {
                                    label = '${t.number}';
                                    bg = Colors.green.shade300;
                                  }
                                  return Chip(
                                    label: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: bg,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget? _buildMetricsText(
    String mode,
    Map<String, dynamic> playerMetrics,
    Map<String, dynamic>? allMetrics,
  ) {
    if (mode == 'cricket') {
      final perPlayerCricket = allMetrics?['perPlayerCricket'];
      // perPlayerCricket is keyed by playerId but we only have playerMetrics here
      return null; // no easy way to get playerId here; show nothing
    }
    final avg3Dart = playerMetrics['avg3Dart'] as num?;
    final bestTurn = playerMetrics['bestTurn'] as num?;
    final count180 = playerMetrics['count180'];
    final count140 = playerMetrics['count140plus'];
    return Text(
      'Avg 3 dardos: ${avg3Dart?.toStringAsFixed(1) ?? '-'} · '
      'Mejor turno: ${bestTurn != null && bestTurn > 0 ? bestTurn.toInt() : '-'} · '
      '180s: ${count180 ?? 0} · '
      '140+: ${count140 ?? 0}',
    );
  }
}
