import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/domain/services/truco_dealer_rules.dart';

void main() {
  const seats = ['a1', 'b1', 'a2', 'b2'];

  group('trucoNextSeat', () {
    test('moves one seat around the table', () {
      expect(trucoNextSeat(seats, 'a1'), 'b1');
      expect(trucoNextSeat(seats, 'b1'), 'a2');
      expect(trucoNextSeat(seats, 'a2'), 'b2');
    });

    test('wraps from the last seat to the first', () {
      expect(trucoNextSeat(seats, 'b2'), 'a1');
      expect(trucoNextSeat(const ['a1', 'b1'], 'b1'), 'a1');
    });

    test('an unknown or missing player starts at the first seat', () {
      expect(trucoNextSeat(seats, 'zz'), 'a1');
      expect(trucoNextSeat(seats, null), 'a1');
    });

    test('an empty table has no seat', () {
      expect(trucoNextSeat(const [], 'a1'), isNull);
    });
  });

  group('trucoPreviousSeat', () {
    test('moves one seat back and wraps to the last seat', () {
      expect(trucoPreviousSeat(seats, 'b1'), 'a1');
      expect(trucoPreviousSeat(seats, 'a1'), 'b2');
    });

    test('an unknown player or empty table falls back safely', () {
      expect(trucoPreviousSeat(seats, 'zz'), 'b2');
      expect(trucoPreviousSeat(const [], 'a1'), isNull);
    });
  });

  test('the mano is the seat after the dealer', () {
    expect(trucoManoOf(seats, 'a1'), 'b1');
    expect(trucoManoOf(seats, 'b2'), 'a1');
  });

  test('the first dealer defaults to the first seat when not seated', () {
    expect(trucoFirstDealer(seats, 'a2'), 'a2');
    expect(trucoFirstDealer(seats, 'zz'), 'a1');
    expect(trucoFirstDealer(seats, null), 'a1');
    expect(trucoFirstDealer(const [], null), isNull);
  });
}
