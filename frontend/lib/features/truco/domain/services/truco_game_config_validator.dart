import '../entities/truco_game.dart';
import '../entities/truco_team.dart';
import '../services/truco_score_rules.dart';

/// Returns the first problem that prevents creating the game, or null when
/// the table is ready to start.
String? validateTrucoGameConfig({
  required String name,
  required String? firstDealerId,
  required TrucoMode mode,
  required int targetScore,
  required TrucoTeam teamA,
  required TrucoTeam teamB,
}) {
  if (name.trim().isEmpty) {
    return 'La partida necesita un nombre.';
  }
  if (!trucoTargetScores.contains(targetScore)) {
    return 'El objetivo debe ser de 18 o 30 puntos.';
  }
  if (teamA.name.trim().isEmpty || teamB.name.trim().isEmpty) {
    return 'Cada equipo necesita un nombre.';
  }
  final size = mode.playersPerTeam;
  if (teamA.playerIds.length != size || teamB.playerIds.length != size) {
    return 'Cada equipo debe tener $size ${size == 1 ? 'jugador' : 'jugadores'}.';
  }
  final all = [...teamA.playerIds, ...teamB.playerIds];
  if (all.toSet().length != all.length) {
    return 'Un jugador no puede estar dos veces en la mesa.';
  }
  final seats = trucoSeatingOrder(teamA.playerIds, teamB.playerIds);
  if (firstDealerId == null || !seats.contains(firstDealerId)) {
    return 'Elija quién reparte primero.';
  }
  return null;
}
