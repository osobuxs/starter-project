import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/domain/services/truco_stats.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_state.dart';

/// Players ranked by wins, win rate and name (same order as La Loba and
/// Dardos).
class TrucoRankingTab extends StatelessWidget {
  final void Function(String playerId)? onOpenPlayer;

  const TrucoRankingTab({super.key, this.onOpenPlayer});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrucoParticipantBloc, TrucoParticipantState>(
      builder: (context, state) {
        if (state.status == TrucoParticipantStatus.loading &&
            state.participants.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final ranking = buildTrucoRanking(state.participants);
        if (ranking.isEmpty) {
          return const Center(
            child: Text(
              'No hay jugadores para mostrar',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: ranking.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = ranking[index];
            return ListTile(
              key: ValueKey('truco-rank-${entry.playerId}'),
              leading: _Position(position: index + 1),
              title: Text(entry.name),
              subtitle: Text(
                'Jugadas: ${entry.played} · Ganadas: ${entry.won} · '
                'Winrate: ${entry.winRateLabel}',
              ),
              onTap: onOpenPlayer == null
                  ? null
                  : () => onOpenPlayer!(entry.playerId),
            );
          },
        );
      },
    );
  }
}

class _Position extends StatelessWidget {
  final int position;

  const _Position({required this.position});

  static const _medals = [
    Color(0xFFF9A825),
    Color(0xFF9E9E9E),
    Color(0xFF8D6E63),
  ];

  @override
  Widget build(BuildContext context) {
    final color =
        position <= _medals.length ? _medals[position - 1] : Colors.blueGrey;
    return CircleAvatar(
      backgroundColor: color,
      foregroundColor: Colors.white,
      child: Text('$position'),
    );
  }
}
