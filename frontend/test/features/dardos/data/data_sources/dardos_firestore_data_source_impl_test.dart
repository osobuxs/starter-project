import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/features/dardos/data/data_sources/remote/dardos_firestore_data_source_impl.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(
      as: #MockCollectionReference),
  MockSpec<DocumentReference<Map<String, dynamic>>>(
      as: #MockDocumentReference),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(
      as: #MockDocumentSnapshot),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(
      as: #MockQuerySnapshot),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(
      as: #MockQueryDocumentSnapshot),
  MockSpec<Transaction>(),
  MockSpec<Query<Map<String, dynamic>>>(as: #MockQuery),
])
import 'dardos_firestore_data_source_impl_test.mocks.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
DardosThrowEntity makeThrow({
  String id = 't1',
  String playerId = 'p1',
  int setIndex = 0,
  int legIndex = 0,
  int turnIndex = 0,
  int dartIndex = 0,
}) {
  return DardosThrowEntity(
    id: id,
    playerId: playerId,
    setIndex: setIndex,
    legIndex: legIndex,
    turnIndex: turnIndex,
    dartIndex: dartIndex,
    number: 20,
    multiplier: 1,
    points: 20,
    isMiss: false,
    isBust: false,
    remainingAfter: 481,
    cricketPointsScored: 0,
    timestamp: 1000,
    createdBy: 'uid',
  );
}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockGamesCollection;
  late MockDocumentReference mockGameDoc;
  late MockCollectionReference mockThrowsCollection;
  late MockDocumentReference mockThrowDoc;
  late DardosFirestoreDataSourceImpl dataSource;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockGamesCollection = MockCollectionReference();
    mockGameDoc = MockDocumentReference();
    mockThrowsCollection = MockCollectionReference();
    mockThrowDoc = MockDocumentReference();

    when(mockFirestore.collection('dardos_games'))
        .thenReturn(mockGamesCollection);
    when(mockGamesCollection.doc(any)).thenReturn(mockGameDoc);
    when(mockGameDoc.collection('throws')).thenReturn(mockThrowsCollection);
    when(mockThrowsCollection.doc()).thenReturn(mockThrowDoc);
    when(mockThrowDoc.id).thenReturn('new-throw-id');

    dataSource = DardosFirestoreDataSourceImpl(mockFirestore);
  });

  // -----------------------------------------------------------------------
  // acquireAnnotator
  // -----------------------------------------------------------------------
  group('acquireAnnotator', () {
    test(
      'returns true when activeAnnotator is null (lock is free)',
      () async {
        final mockTransaction = MockTransaction();
        final mockSnap = MockDocumentSnapshot();

        when(mockFirestore.runTransaction<bool>(any)).thenAnswer((inv) async {
          final handler = inv.positionalArguments[0]
              as Future<bool> Function(Transaction);
          // Simulate: snap.data returns null for activeAnnotator
          when(mockSnap.data()).thenReturn({'activeAnnotator': null});
          when(mockTransaction.get(mockGameDoc))
              .thenAnswer((_) async => mockSnap);
          return handler(mockTransaction);
        });

        final result = await dataSource.acquireAnnotator(
          gameId: 'g1',
          deviceId: 'deviceA',
        );

        expect(result, isTrue);
      },
    );

    test(
      'returns true when activeAnnotator equals our deviceId (idempotent re-acquire)',
      () async {
        final mockTransaction = MockTransaction();
        final mockSnap = MockDocumentSnapshot();

        when(mockFirestore.runTransaction<bool>(any)).thenAnswer((inv) async {
          final handler = inv.positionalArguments[0]
              as Future<bool> Function(Transaction);
          when(mockSnap.data()).thenReturn({'activeAnnotator': 'deviceA'});
          when(mockTransaction.get(mockGameDoc))
              .thenAnswer((_) async => mockSnap);
          return handler(mockTransaction);
        });

        final result = await dataSource.acquireAnnotator(
          gameId: 'g1',
          deviceId: 'deviceA',
        );

        expect(result, isTrue);
      },
    );

    test(
      'returns false when activeAnnotator is occupied by a different device',
      () async {
        final mockTransaction = MockTransaction();
        final mockSnap = MockDocumentSnapshot();

        when(mockFirestore.runTransaction<bool>(any)).thenAnswer((inv) async {
          final handler = inv.positionalArguments[0]
              as Future<bool> Function(Transaction);
          when(mockSnap.data()).thenReturn({'activeAnnotator': 'deviceB'});
          when(mockTransaction.get(mockGameDoc))
              .thenAnswer((_) async => mockSnap);
          return handler(mockTransaction);
        });

        final result = await dataSource.acquireAnnotator(
          gameId: 'g1',
          deviceId: 'deviceA',
        );

        expect(result, isFalse);
      },
    );
  });

  // -----------------------------------------------------------------------
  // releaseAnnotator
  // -----------------------------------------------------------------------
  group('releaseAnnotator', () {
    test('releases lock when owned by our deviceId', () async {
      final mockTransaction = MockTransaction();
      final mockSnap = MockDocumentSnapshot();

      when(mockFirestore.runTransaction<void>(any)).thenAnswer((inv) async {
        final handler =
            inv.positionalArguments[0] as Future<void> Function(Transaction);
        when(mockSnap.data()).thenReturn({'activeAnnotator': 'deviceA'});
        when(mockTransaction.get(mockGameDoc))
            .thenAnswer((_) async => mockSnap);
        await handler(mockTransaction);
      });

      // Should not throw
      await dataSource.releaseAnnotator(gameId: 'g1', deviceId: 'deviceA');

      verify(mockFirestore.runTransaction<void>(any)).called(1);
    });

    test('does NOT clear lock when owned by a different device', () async {
      final mockTransaction = MockTransaction();
      final mockSnap = MockDocumentSnapshot();

      when(mockFirestore.runTransaction<void>(any)).thenAnswer((inv) async {
        final handler =
            inv.positionalArguments[0] as Future<void> Function(Transaction);
        when(mockSnap.data()).thenReturn({'activeAnnotator': 'deviceB'});
        when(mockTransaction.get(mockGameDoc))
            .thenAnswer((_) async => mockSnap);
        await handler(mockTransaction);
      });

      await dataSource.releaseAnnotator(gameId: 'g1', deviceId: 'deviceA');

      // transaction.update should NOT be called
      verifyNever(mockTransaction.update(any, any));
    });
  });

  // -----------------------------------------------------------------------
  // appendThrow
  // -----------------------------------------------------------------------
  group('appendThrow', () {
    test('writes throw to throws subcollection and returns with assigned id',
        () async {
      final throw_ = makeThrow();
      when(mockThrowDoc.set(any)).thenAnswer((_) async {});
      when(mockThrowDoc.id).thenReturn('assigned-throw-id');

      final result = await dataSource.appendThrow(
        gameId: 'g1',
        throw_: throw_,
      );

      verify(mockThrowsCollection.doc()).called(1);
      verify(mockThrowDoc.set(any)).called(1);
      expect(result.id, 'assigned-throw-id');
    });
  });

  // -----------------------------------------------------------------------
  // deleteLastThrow
  // -----------------------------------------------------------------------
  group('deleteLastThrow', () {
    test('queries throws ordered desc and deletes last document', () async {
      final mockQuery1 = MockQuery();
      final mockQuery2 = MockQuery();
      final mockQuery3 = MockQuery();
      final mockQuery4 = MockQuery();
      final mockQuerySnap = MockQuerySnapshot();
      final mockDoc = MockQueryDocumentSnapshot();
      final mockDocRef = MockDocumentReference();

      when(mockThrowsCollection.orderBy('setIndex', descending: true))
          .thenReturn(mockQuery1);
      when(mockQuery1.orderBy('legIndex', descending: true))
          .thenReturn(mockQuery2);
      when(mockQuery2.orderBy('turnIndex', descending: true))
          .thenReturn(mockQuery3);
      when(mockQuery3.orderBy('dartIndex', descending: true))
          .thenReturn(mockQuery4);
      when(mockQuery4.limit(1)).thenReturn(mockQuery4);
      when(mockQuery4.get()).thenAnswer((_) async => mockQuerySnap);
      when(mockQuerySnap.docs).thenReturn([mockDoc]);
      when(mockDoc.reference).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await dataSource.deleteLastThrow('g1');

      verify(mockDocRef.delete()).called(1);
    });

    test('does nothing when throws subcollection is empty', () async {
      final mockQuery1 = MockQuery();
      final mockQuery2 = MockQuery();
      final mockQuery3 = MockQuery();
      final mockQuery4 = MockQuery();
      final mockQuerySnap = MockQuerySnapshot();

      when(mockThrowsCollection.orderBy('setIndex', descending: true))
          .thenReturn(mockQuery1);
      when(mockQuery1.orderBy('legIndex', descending: true))
          .thenReturn(mockQuery2);
      when(mockQuery2.orderBy('turnIndex', descending: true))
          .thenReturn(mockQuery3);
      when(mockQuery3.orderBy('dartIndex', descending: true))
          .thenReturn(mockQuery4);
      when(mockQuery4.limit(1)).thenReturn(mockQuery4);
      when(mockQuery4.get()).thenAnswer((_) async => mockQuerySnap);
      when(mockQuerySnap.docs).thenReturn([]);

      // Should not throw
      await dataSource.deleteLastThrow('g1');
    });
  });
}
