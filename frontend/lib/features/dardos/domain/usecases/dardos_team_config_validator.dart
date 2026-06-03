
class TeamConfigurationResult {
  final List<Map<String, dynamic>>? teams;
  final Map<String, String>? playerTeamIds;
  final String? errorMessage;
  final bool isValid;

  const TeamConfigurationResult._({
    this.teams,
    this.playerTeamIds,
    this.errorMessage,
    required this.isValid,
  });

  factory TeamConfigurationResult.success(List<Map<String, dynamic>> teams, Map<String, String> playerTeamIds) {
    return TeamConfigurationResult._(teams: teams, playerTeamIds: playerTeamIds, isValid: true);
  }

  factory TeamConfigurationResult.failure(String message) {
    return TeamConfigurationResult._(errorMessage: message, isValid: false);
  }
}

class DardosTeamConfigValidator {
  TeamConfigurationResult validate({
    required int numberOfTeams,
    required int playersPerTeam,
    required Map<int, String> teamNames,
    required Map<int, List<String>> playersInTeams,
  }) {
    final List<Map<String, dynamic>> teams = [];
    final Map<String, String> playerTeamIds = {};
    final Set<String> assignedPlayers = {};

    for (int i = 0; i < numberOfTeams; i++) {
      final teamPlayers = playersInTeams[i] ?? [];
      final teamName = teamNames[i] ?? 'Equipo ${i + 1}';

      if (teamPlayers.length != playersPerTeam) {
        return TeamConfigurationResult.failure(
          'El equipo "$teamName" debe tener exactamente $playersPerTeam jugadores.'
        );
      }

      for (final playerId in teamPlayers) {
        if (assignedPlayers.contains(playerId)) {
          return TeamConfigurationResult.failure(
            'El jugador $playerId está asignado a más de un equipo.'
          );
        }
        assignedPlayers.add(playerId);
        playerTeamIds[playerId] = 'team_$i';
      }

      teams.add({
        'id': 'team_$i',
        'name': teamName,
        'playerIds': teamPlayers,
      });
    }

    return TeamConfigurationResult.success(teams, playerTeamIds);
  }
}
