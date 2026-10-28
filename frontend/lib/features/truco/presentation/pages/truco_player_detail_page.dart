import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/domain/services/truco_stats.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_state.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/pages/truco_iniciar_tab.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/widgets/truco_game_tile.dart';

/// A player's totals and every Truco game they played: team, partners,
/// opponents and result.
class TrucoPlayerDetailPage extends StatelessWidget {
  final String playerId;

  const TrucoPlayerDetailPage({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final participantState = context.watch<TrucoParticipantBloc>().state;
    final names = participantState.namesById;
    final player = participantState.participants
        .where((p) => p.id == playerId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(player?.name ?? 'Jugador')),
      body: BlocBuilder<TrucoMultiGameBloc, TrucoMultiGameState>(
        builder: (context, state) {
          if (state.status == TrucoMultiGameStatus.loading &&
              state.allGames.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final history = trucoPlayerHistory(playerId, state.allGames);
          String namesOf(List<String> ids) =>
              ids.map((id) => names[id] ?? '…').join(', ');

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  _StatCard(label: 'Jugadas', value: '${history.played}'),
                  _StatCard(label: 'Ganadas', value: '${history.won}'),
                  _StatCard(label: 'Perdidas', value: '${history.lost}'),
                  _StatCard(
                    label: 'Winrate',
                    value: history.played == 0
                        ? '0.0%'
                        : '${(history.won / history.played * 100).toStringAsFixed(1)}%',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Partidas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (history.entries.isEmpty)
                const Text(
                  'Este jugador todavía no jugó partidas de Truco.',
                  style: TextStyle(color: Colors.grey),
                ),
              for (final entry in history.entries)
                Card(
                  key: ValueKey('truco-player-game-${entry.game.id}'),
                  child: ListTile(
                    onTap: () => openTrucoGame(context, entry.game.id),
                    leading: _ResultIcon(result: entry.result),
                    title: Text(
                      '${entry.game.teamOf(entry.side).name} '
                      '${entry.game.scoreOf(entry.side)} – '
                      '${entry.game.scoreOf(entry.side.other)} '
                      '${entry.game.teamOf(entry.side.other).name}',
                    ),
                    subtitle: Text(
                      [
                        '${entry.game.name} · '
                            '${formatTrucoDate(entry.game.date)} · '
                            '${entry.game.mode.label} · a ${entry.game.targetScore}',
                        if (entry.partnerIds.isNotEmpty)
                          'Compañeros: ${namesOf(entry.partnerIds)}',
                        'Rivales: ${namesOf(entry.opponentIds)}',
                      ].join('\n'),
                    ),
                    isThreeLine: entry.partnerIds.isNotEmpty,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text(label, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultIcon extends StatelessWidget {
  final TrucoPlayerResult result;

  const _ResultIcon({required this.result});

  @override
  Widget build(BuildContext context) {
    switch (result) {
      case TrucoPlayerResult.won:
        return const Icon(Icons.emoji_events, color: Color(0xFFF9A825));
      case TrucoPlayerResult.lost:
        return const Icon(Icons.close, color: Colors.redAccent);
      case TrucoPlayerResult.inProgress:
        return const Icon(Icons.hourglass_bottom, color: Colors.blueGrey);
    }
  }
}
