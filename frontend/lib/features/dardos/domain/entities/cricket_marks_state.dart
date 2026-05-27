import 'package:equatable/equatable.dart';

class CricketMarksState extends Equatable {
  static const List<String> cricketTargets = [
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    'bull',
  ];

  final Map<String, Map<String, int>> marksByPlayer;
  final Map<String, int> pointsByPlayer;

  const CricketMarksState({
    required this.marksByPlayer,
    required this.pointsByPlayer,
  });

  factory CricketMarksState.empty(List<String> playerIds) {
    final marksByPlayer = <String, Map<String, int>>{};
    final pointsByPlayer = <String, int>{};

    for (final pid in playerIds) {
      marksByPlayer[pid] = {
        for (final t in cricketTargets) t: 0,
      };
      pointsByPlayer[pid] = 0;
    }

    return CricketMarksState(
      marksByPlayer: marksByPlayer,
      pointsByPlayer: pointsByPlayer,
    );
  }

  CricketMarksState copyWith({
    Map<String, Map<String, int>>? marksByPlayer,
    Map<String, int>? pointsByPlayer,
  }) {
    return CricketMarksState(
      marksByPlayer: marksByPlayer ?? this.marksByPlayer,
      pointsByPlayer: pointsByPlayer ?? this.pointsByPlayer,
    );
  }

  @override
  List<Object?> get props => [marksByPlayer, pointsByPlayer];
}
