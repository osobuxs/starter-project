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
                      const SizedBox(height: 24),
                      _NumberFreqSection(numberFreq: p.numberFreq),
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
    final totalPoints = (stats['totalPoints'] as num?)?.toDouble() ?? 0;
    final validTurns = (stats['validTurns'] as num?)?.toDouble() ?? 0;
    final avg = validTurns > 0
        ? (totalPoints / validTurns).toStringAsFixed(1)
        : '-';
    return [
      _StatsRow(
          label: 'Jugadas', value: '${stats['played'] ?? 0}'),
      _StatsRow(
          label: 'Ganadas', value: '${stats['won'] ?? 0}'),
      _StatsRow(label: 'Avg 3 dardos', value: avg),
      _StatsRow(
          label: '180s', value: '${stats['count180'] ?? 0}'),
      _StatsRow(
          label: '140+', value: '${stats['count140plus'] ?? 0}'),
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

class _NumberFreqSection extends StatelessWidget {
  final Map<String, int> numberFreq;

  const _NumberFreqSection({Key? key, required this.numberFreq})
      : super(key: key);

  static const _rows = <_Row>[
    _Row(label: '0 (Miss)', number: 0),
    _Row(label: '1', number: 1),
    _Row(label: '2', number: 2),
    _Row(label: '3', number: 3),
    _Row(label: '4', number: 4),
    _Row(label: '5', number: 5),
    _Row(label: '6', number: 6),
    _Row(label: '7', number: 7),
    _Row(label: '8', number: 8),
    _Row(label: '9', number: 9),
    _Row(label: '10', number: 10),
    _Row(label: '11', number: 11),
    _Row(label: '12', number: 12),
    _Row(label: '13', number: 13),
    _Row(label: '14', number: 14),
    _Row(label: '15', number: 15),
    _Row(label: '16', number: 16),
    _Row(label: '17', number: 17),
    _Row(label: '18', number: 18),
    _Row(label: '19', number: 19),
    _Row(label: '20', number: 20),
    _Row(label: '25 (Bull)', number: 25),
  ];

  int _get(int number, int multiplier) {
    return numberFreq['${number}_$multiplier'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final total = numberFreq.values.fold<int>(0, (s, v) => s + v);
    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Frecuencia de números',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Sin datos. Las frecuencias se agregan al terminar cada partida.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    String pct(int count) {
      if (total == 0) return '-';
      return '${(count * 100 / total).toStringAsFixed(1)}%';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frecuencia de números',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Total tiros: $total',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: const [
                    _Cell(text: 'Número', isHeader: true),
                    _Cell(text: 'x1', isHeader: true),
                    _Cell(text: 'x2', isHeader: true),
                    _Cell(text: 'x3', isHeader: true),
                  ],
                ),
                for (final row in _rows)
                  TableRow(
                    children: [
                      _Cell(text: row.label, isHeader: true),
                      _FreqCell(
                          count: _get(row.number, 1), pct: pct(_get(row.number, 1))),
                      _FreqCell(
                          count: _get(row.number, 2), pct: pct(_get(row.number, 2))),
                      row.number == 0 || row.number == 25
                          ? const _Cell(text: '—')
                          : _FreqCell(
                              count: _get(row.number, 3),
                              pct: pct(_get(row.number, 3))),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row {
  final String label;
  final int number;
  const _Row({required this.label, required this.number});
}

class _Cell extends StatelessWidget {
  final String text;
  final bool isHeader;
  const _Cell({Key? key, required this.text, this.isHeader = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
}

class _FreqCell extends StatelessWidget {
  final int count;
  final String pct;
  const _FreqCell({Key? key, required this.count, required this.pct})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasData = count > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: hasData ? Colors.indigo.shade800 : Colors.grey.shade400,
            ),
          ),
          Text(
            pct,
            style: TextStyle(
              fontSize: 10,
              color: hasData ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
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
