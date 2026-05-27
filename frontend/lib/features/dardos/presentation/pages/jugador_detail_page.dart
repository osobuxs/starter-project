import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_state.dart';

class DardosJugadorDetailPage extends StatefulWidget {
  final String participantId;

  const DardosJugadorDetailPage({
    Key? key,
    required this.participantId,
  }) : super(key: key);

  @override
  State<DardosJugadorDetailPage> createState() =>
      _DardosJugadorDetailPageState();
}

class _DardosJugadorDetailPageState extends State<DardosJugadorDetailPage> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<DardosParticipantBloc>();
    if (bloc.state.participants.isEmpty) {
      bloc.add(FetchAllParticipantsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DardosParticipantBloc, DardosParticipantState>(
      builder: (context, state) {
        final isLoading = state.status == DardosParticipantStatus.loading ||
            (state.participants.isEmpty &&
                state.status == DardosParticipantStatus.initial);
        if (isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle de Jugador')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        DardosParticipantEntity? participant;
        try {
          participant = state.participants
              .firstWhere((p) => p.id == widget.participantId);
        } catch (_) {
          participant = null;
        }

        if (participant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle de Jugador')),
            body: const Center(child: Text('Jugador no encontrado')),
          );
        }

        final p = participant;

        return Scaffold(
          appBar: AppBar(title: Text(p.name)),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // General stats
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatColumn(
                                label: 'Partidas',
                                value: '${p.totalGamesPlayed}',
                              ),
                              _StatColumn(
                                label: 'Ganadas',
                                value: '${p.totalGamesWon}',
                              ),
                              _StatColumn(
                                label: 'Win rate',
                                value: p.totalGamesPlayed > 0
                                    ? '${(p.totalGamesWon / p.totalGamesPlayed * 100).toStringAsFixed(1)}%'
                                    : '0.0%',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Estadísticas por modo',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      if (p.statsByMode.isEmpty)
                        const Text(
                          'Aún no hay partidas registradas para este jugador.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...p.statsByMode.entries.map((entry) {
                          final mode = entry.key;
                          final stats = entry.value;
                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mode.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Divider(),
                                  ..._statsRows(mode, stats),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _statsRows(String mode, Map<String, dynamic> stats) {
    if (mode == 'cricket') {
      return [
        _StatsRow(
            label: 'Jugadas', value: '${stats['played'] ?? 0}'),
        _StatsRow(
            label: 'Ganadas', value: '${stats['won'] ?? 0}'),
        _StatsRow(
            label: 'MPR',
            value: '${(stats['mpr'] as num?)?.toStringAsFixed(2) ?? '-'}'),
        _StatsRow(
            label: 'Cierres', value: '${stats['closes'] ?? '-'}'),
      ];
    }
    return [
      _StatsRow(
          label: 'Jugadas', value: '${stats['played'] ?? 0}'),
      _StatsRow(
          label: 'Ganadas', value: '${stats['won'] ?? 0}'),
      _StatsRow(
          label: 'Avg 3 dardos',
          value:
              '${(stats['avg3Dart'] as num?)?.toStringAsFixed(1) ?? '-'}'),
      _StatsRow(
          label: '180s', value: '${stats['best180s'] ?? 0}'),
      _StatsRow(
          label: 'Checkout %',
          value: stats['checkoutPct'] != null
              ? '${((stats['checkoutPct'] as num) * 100).toStringAsFixed(1)}%'
              : '-'),
    ];
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatsRow({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
