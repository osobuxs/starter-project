import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/domain/services/truco_game_config_validator.dart';

void main() {
  String? validate({
    String name = 'Truco 28/10',
    TrucoMode mode = TrucoMode.twoVsTwo,
    int target = 30,
    TrucoTeam teamA =
        const TrucoTeam(name: 'Nosotros', playerIds: ['a1', 'a2']),
    TrucoTeam teamB = const TrucoTeam(name: 'Ellos', playerIds: ['b1', 'b2']),
    String? firstDealerId = 'a1',
  }) {
    return validateTrucoGameConfig(
      name: name,
      firstDealerId: firstDealerId,
      mode: mode,
      targetScore: target,
      teamA: teamA,
      teamB: teamB,
    );
  }

  test('a complete 2 vs 2 at 30 is valid', () {
    expect(validate(), isNull);
  });

  test('the game needs a name', () {
    expect(validate(name: '   '), 'La partida necesita un nombre.');
  });

  test('the first dealer must be seated at the table', () {
    expect(validate(firstDealerId: 'zz'), 'Elija quién reparte primero.');
    expect(validate(firstDealerId: null), 'Elija quién reparte primero.');
    expect(validate(firstDealerId: 'b2'), isNull);
  });

  test('only 18 or 30 are valid targets', () {
    expect(validate(target: 24), 'El objetivo debe ser de 18 o 30 puntos.');
  });

  test('both teams need a name', () {
    expect(
      validate(teamB: const TrucoTeam(name: '  ', playerIds: ['b1', 'b2'])),
      'Cada equipo necesita un nombre.',
    );
  });

  test('each team needs exactly the players of the mode', () {
    expect(
      validate(teamA: const TrucoTeam(name: 'Nosotros', playerIds: ['a1'])),
      'Cada equipo debe tener 2 jugadores.',
    );
    expect(
      validate(
        mode: TrucoMode.oneVsOne,
        teamA: const TrucoTeam(name: 'Nosotros'),
        teamB: const TrucoTeam(name: 'Ellos', playerIds: ['b1']),
      ),
      'Cada equipo debe tener 1 jugador.',
    );
  });

  test('a player cannot be in both teams or twice in one team', () {
    expect(
      validate(teamB: const TrucoTeam(name: 'Ellos', playerIds: ['a1', 'b2'])),
      'Un jugador no puede estar dos veces en la mesa.',
    );
    expect(
      validate(
        teamA: const TrucoTeam(name: 'Nosotros', playerIds: ['a1', 'a1']),
      ),
      'Un jugador no puede estar dos veces en la mesa.',
    );
  });
}
