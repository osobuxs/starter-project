import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_state.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_state.dart';

class RankingTab extends StatefulWidget {
  const RankingTab({super.key});

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _modes = ['501', '301', 'cricket'];
  static const _modeLabels = ['501', '301', 'Cricket'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DardosMultiGameBloc, DardosMultiGameState>(
      builder: (context, gameState) {
        return BlocBuilder<DardosParticipantBloc, DardosParticipantState>(
          builder: (context, participantState) {
            return Scaffold(
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        'Ranking',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      tabs:
                          _modeLabels.map((label) => Tab(text: label)).toList(),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: _modes.map((mode) {
                          return _RankingModeTab(
                            mode: mode,
                            games: gameState.games
                                .where((g) =>
                                    g.mode == mode && g.status == 'finished')
                                .toList(),
                            participantNames: {
                              for (final p in participantState.participants)
                                p.id: p.name,
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RankingModeTab extends StatelessWidget {
  final String mode;
  final List<DardosGameEntity> games;
  final Map<String, String> participantNames;

  const _RankingModeTab({
    required this.mode,
    required this.games,
    required this.participantNames,
  });

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Sin datos para este modo todavía.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final byId = <String, _RankingStat>{};

    for (final game in games) {
      for (final playerId in game.playerIds) {
        byId.putIfAbsent(
          playerId,
          () => _RankingStat(
            name: participantNames[playerId] ?? playerId,
          ),
        );
        byId[playerId]!.gamesPlayed++;
      }
      final winnerId = game.winnerId;
      if (winnerId != null) {
        final winnerPlayerIds =
            game.teamMode ? game.playersForWinner(winnerId) : [winnerId];
        for (final playerId in winnerPlayerIds) {
          if (byId.containsKey(playerId)) {
            byId[playerId]!.gamesWon++;
          }
        }
      }
    }

    final ranking = byId.values.toList()
      ..sort((a, b) {
        final winsCmp = b.gamesWon.compareTo(a.gamesWon);
        if (winsCmp != 0) return winsCmp;
        final rateCmp = b.winRate.compareTo(a.winRate);
        if (rateCmp != 0) return rateCmp;
        return a.name.compareTo(b.name);
      });

    return ListView.separated(
      itemCount: ranking.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = ranking[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.indigo.shade50,
            child: Text(
              '#${index + 1}',
              style: TextStyle(
                color: Colors.indigo.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            'Jugadas: ${item.gamesPlayed} · Ganadas: ${item.gamesWon} · Winrate: ${item.winRateLabel}',
          ),
        );
      },
    );
  }
}

class _RankingStat {
  final String name;
  int gamesPlayed;
  int gamesWon;

  _RankingStat({required this.name})
      : gamesPlayed = 0,
        gamesWon = 0;

  double get winRate => gamesPlayed > 0 ? gamesWon / gamesPlayed : 0;
  String get winRateLabel => '${(winRate * 100).toStringAsFixed(1)}%';
}
