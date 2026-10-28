import 'package:equatable/equatable.dart';

/// The two sides of a Truco table.
enum TrucoTeamSide {
  a,
  b;

  TrucoTeamSide get other => this == TrucoTeamSide.a ? TrucoTeamSide.b : a;

  /// Persisted value ('a' / 'b').
  String get key => name;

  static TrucoTeamSide? fromKey(Object? value) {
    for (final side in TrucoTeamSide.values) {
      if (side.key == value) return side;
    }
    return null;
  }
}

/// A team: its display name and its members in seating order.
class TrucoTeam extends Equatable {
  static const defaultNameA = 'Nosotros';
  static const defaultNameB = 'Ellos';

  final String name;
  final List<String> playerIds;

  const TrucoTeam({required this.name, this.playerIds = const []});

  TrucoTeam copyWith({String? name, List<String>? playerIds}) {
    return TrucoTeam(
      name: name ?? this.name,
      playerIds: playerIds ?? this.playerIds,
    );
  }

  @override
  List<Object?> get props => [name, playerIds];
}
