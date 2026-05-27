import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';

void main() {
  group('DardosParticipantEntity', () {
    const participant = DardosParticipantEntity(
      id: 'p1',
      name: 'Exe',
      email: 'exe@example.com',
      uid: 'uid-123',
      isActive: true,
      deletedAt: null,
      createdAt: 1716000000000,
      totalGamesPlayed: 10,
      totalGamesWon: 3,
      statsByMode: {},
    );

    group('equality (Equatable)', () {
      test('two instances with same fields are equal', () {
        const other = DardosParticipantEntity(
          id: 'p1',
          name: 'Exe',
          email: 'exe@example.com',
          uid: 'uid-123',
          isActive: true,
          deletedAt: null,
          createdAt: 1716000000000,
          totalGamesPlayed: 10,
          totalGamesWon: 3,
          statsByMode: {},
        );
        expect(participant, equals(other));
      });

      test('different id makes them not equal', () {
        const other = DardosParticipantEntity(
          id: 'p2',
          name: 'Exe',
          email: 'exe@example.com',
          uid: 'uid-123',
          isActive: true,
          deletedAt: null,
          createdAt: 1716000000000,
          totalGamesPlayed: 10,
          totalGamesWon: 3,
          statsByMode: {},
        );
        expect(participant, isNot(equals(other)));
      });
    });

    group('copyWith', () {
      test('copyWith returns same values when nothing is overridden', () {
        final copy = participant.copyWith();
        expect(copy, equals(participant));
      });

      test('copyWith changes id', () {
        final copy = participant.copyWith(id: 'p99');
        expect(copy.id, 'p99');
        expect(copy.name, participant.name);
      });

      test('copyWith changes name', () {
        final copy = participant.copyWith(name: 'Juan');
        expect(copy.name, 'Juan');
      });

      test('copyWith changes email', () {
        final copy = participant.copyWith(email: 'other@x.com');
        expect(copy.email, 'other@x.com');
      });

      test('copyWith changes uid', () {
        final copy = participant.copyWith(uid: 'uid-999');
        expect(copy.uid, 'uid-999');
      });

      test('copyWith changes isActive', () {
        final copy = participant.copyWith(isActive: false);
        expect(copy.isActive, false);
      });

      test('copyWith changes deletedAt', () {
        final copy = participant.copyWith(deletedAt: 9999999);
        expect(copy.deletedAt, 9999999);
      });

      test('copyWith changes totalGamesPlayed', () {
        final copy = participant.copyWith(totalGamesPlayed: 99);
        expect(copy.totalGamesPlayed, 99);
      });

      test('copyWith changes totalGamesWon', () {
        final copy = participant.copyWith(totalGamesWon: 5);
        expect(copy.totalGamesWon, 5);
      });

      test('copyWith changes statsByMode', () {
        final newStats = {
          '501': {'played': 3},
        };
        final copy = participant.copyWith(statsByMode: newStats);
        expect(copy.statsByMode, newStats);
      });
    });

    group('nullable fields', () {
      test('email can be null', () {
        const p = DardosParticipantEntity(
          id: 'p2',
          name: 'Guest',
          isActive: true,
          createdAt: 0,
          totalGamesPlayed: 0,
          totalGamesWon: 0,
          statsByMode: {},
        );
        expect(p.email, isNull);
        expect(p.uid, isNull);
        expect(p.deletedAt, isNull);
      });
    });
  });
}
