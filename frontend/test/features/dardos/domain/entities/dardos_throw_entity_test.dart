import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

void main() {
  group('DardosThrowEntity', () {
    const throwEntity = DardosThrowEntity(
      id: 't1',
      playerId: 'p1',
      setIndex: 0,
      legIndex: 0,
      turnIndex: 2,
      dartIndex: 1,
      number: 20,
      multiplier: 3,
      points: 60,
      isMiss: false,
      isBust: false,
      remainingAfter: 441,
      cricketTarget: null,
      cricketMarksDelta: null,
      cricketPointsScored: 0,
      timestamp: 1716000000000,
      createdBy: 'uid-1',
    );

    group('equality (Equatable)', () {
      test('two instances with same fields are equal', () {
        const other = DardosThrowEntity(
          id: 't1',
          playerId: 'p1',
          setIndex: 0,
          legIndex: 0,
          turnIndex: 2,
          dartIndex: 1,
          number: 20,
          multiplier: 3,
          points: 60,
          isMiss: false,
          isBust: false,
          remainingAfter: 441,
          cricketTarget: null,
          cricketMarksDelta: null,
          cricketPointsScored: 0,
          timestamp: 1716000000000,
          createdBy: 'uid-1',
        );
        expect(throwEntity, equals(other));
      });

      test('different id makes them not equal', () {
        const other = DardosThrowEntity(
          id: 't2',
          playerId: 'p1',
          setIndex: 0,
          legIndex: 0,
          turnIndex: 2,
          dartIndex: 1,
          number: 20,
          multiplier: 3,
          points: 60,
          isMiss: false,
          isBust: false,
          remainingAfter: 441,
          cricketTarget: null,
          cricketMarksDelta: null,
          cricketPointsScored: 0,
          timestamp: 1716000000000,
          createdBy: 'uid-1',
        );
        expect(throwEntity, isNot(equals(other)));
      });
    });

    group('copyWith', () {
      test('returns same values when nothing is overridden', () {
        final copy = throwEntity.copyWith();
        expect(copy, equals(throwEntity));
      });

      test('changes id', () {
        final copy = throwEntity.copyWith(id: 't99');
        expect(copy.id, 't99');
        expect(copy.playerId, throwEntity.playerId);
      });

      test('changes isBust', () {
        final copy = throwEntity.copyWith(isBust: true);
        expect(copy.isBust, true);
      });

      test('changes remainingAfter', () {
        final copy = throwEntity.copyWith(remainingAfter: 200);
        expect(copy.remainingAfter, 200);
      });

      test('changes dartIndex', () {
        final copy = throwEntity.copyWith(dartIndex: 2);
        expect(copy.dartIndex, 2);
      });
    });

    group('dartIndex range semantics', () {
      test('dartIndex 0 is valid', () {
        const t = DardosThrowEntity(
          id: 't0',
          playerId: 'p1',
          setIndex: 0,
          legIndex: 0,
          turnIndex: 0,
          dartIndex: 0,
          number: 1,
          multiplier: 1,
          points: 1,
          isMiss: false,
          isBust: false,
          cricketPointsScored: 0,
          timestamp: 0,
          createdBy: 'uid',
        );
        expect(t.dartIndex, 0);
      });

      test('dartIndex 2 is valid (last dart)', () {
        const t = DardosThrowEntity(
          id: 't2',
          playerId: 'p1',
          setIndex: 0,
          legIndex: 0,
          turnIndex: 0,
          dartIndex: 2,
          number: 20,
          multiplier: 2,
          points: 40,
          isMiss: false,
          isBust: false,
          cricketPointsScored: 0,
          timestamp: 0,
          createdBy: 'uid',
        );
        expect(t.dartIndex, 2);
      });
    });

    group('cricket-specific fields', () {
      test('cricketTarget and cricketMarksDelta can be null for 501 throws', () {
        expect(throwEntity.cricketTarget, isNull);
        expect(throwEntity.cricketMarksDelta, isNull);
      });

      test('cricket throw has target and marks', () {
        const t = DardosThrowEntity(
          id: 'tc1',
          playerId: 'p1',
          setIndex: 0,
          legIndex: 0,
          turnIndex: 0,
          dartIndex: 0,
          number: 19,
          multiplier: 3,
          points: 57,
          isMiss: false,
          isBust: false,
          cricketTarget: '19',
          cricketMarksDelta: 3,
          cricketPointsScored: 0,
          timestamp: 0,
          createdBy: 'uid',
        );
        expect(t.cricketTarget, '19');
        expect(t.cricketMarksDelta, 3);
      });
    });
  });
}
