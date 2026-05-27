import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/repository/dardos_participant_repository.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_state.dart';

@GenerateNiceMocks([
  MockSpec<DardosParticipantRepository>(),
  MockSpec<FirebaseAuth>(),
  MockSpec<User>(),
])
import 'dardos_participant_bloc_test.mocks.dart';

// ---------------------------------------------------------------------------
// Fixture
// ---------------------------------------------------------------------------
DardosParticipantEntity makeParticipant({
  String id = 'p1',
  String name = 'Test Player',
}) {
  return DardosParticipantEntity(
    id: id,
    name: name,
    isActive: true,
    createdAt: 1000,
    totalGamesPlayed: 0,
    totalGamesWon: 0,
    statsByMode: const {},
  );
}

void main() {
  late MockDardosParticipantRepository mockRepo;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockRepo = MockDardosParticipantRepository();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
  });

  DardosParticipantBloc buildBloc() =>
      DardosParticipantBloc(mockRepo, mockAuth);

  // -----------------------------------------------------------------------
  // FetchAllParticipantsEvent
  // -----------------------------------------------------------------------
  group('FetchAllParticipantsEvent', () {
    blocTest<DardosParticipantBloc, DardosParticipantState>(
      'emits loading then success with participant list',
      build: () {
        when(mockRepo.fetchAllParticipants()).thenAnswer((_) async =>
            DataSuccess([makeParticipant(), makeParticipant(id: 'p2')]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(FetchAllParticipantsEvent()),
      expect: () => [
        isA<DardosParticipantState>().having(
          (s) => s.status,
          'status',
          DardosParticipantStatus.loading,
        ),
        isA<DardosParticipantState>()
            .having((s) => s.status, 'status', DardosParticipantStatus.success)
            .having((s) => s.participants.length, 'count', 2),
      ],
    );

    blocTest<DardosParticipantBloc, DardosParticipantState>(
      'emits loading then error when repo fails',
      build: () {
        when(mockRepo.fetchAllParticipants()).thenAnswer(
            (_) async => DataFailed(Exception('fetch error')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(FetchAllParticipantsEvent()),
      expect: () => [
        isA<DardosParticipantState>()
            .having((s) => s.status, 'status', DardosParticipantStatus.loading),
        isA<DardosParticipantState>()
            .having((s) => s.status, 'status', DardosParticipantStatus.error),
      ],
    );
  });

  // -----------------------------------------------------------------------
  // CreateParticipantEvent — admin gate
  // -----------------------------------------------------------------------
  group('CreateParticipantEvent', () {
    blocTest<DardosParticipantBloc, DardosParticipantState>(
      'admin user: calls repo and emits success',
      build: () {
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('lfexevega95@gmail.com');
        when(mockRepo.createParticipant(any))
            .thenAnswer((_) async => DataSuccess(makeParticipant()));
        when(mockRepo.fetchAllParticipants()).thenAnswer(
            (_) async => DataSuccess([makeParticipant()]));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(CreateParticipantEvent(participant: makeParticipant())),
      expect: () => [
        isA<DardosParticipantState>()
            .having((s) => s.status, 'status', DardosParticipantStatus.loading),
        isA<DardosParticipantState>()
            .having((s) => s.status, 'status', DardosParticipantStatus.success),
      ],
      verify: (_) => verify(mockRepo.createParticipant(any)).called(1),
    );

    blocTest<DardosParticipantBloc, DardosParticipantState>(
      'non-admin user: emits error, repo NOT called',
      build: () {
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('notadmin@example.com');
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(CreateParticipantEvent(participant: makeParticipant())),
      expect: () => [
        isA<DardosParticipantState>()
            .having((s) => s.status, 'status', DardosParticipantStatus.error),
      ],
      verify: (_) => verifyNever(mockRepo.createParticipant(any)),
    );

    blocTest<DardosParticipantBloc, DardosParticipantState>(
      'unauthenticated user: emits error, repo NOT called',
      build: () {
        when(mockAuth.currentUser).thenReturn(null);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(CreateParticipantEvent(participant: makeParticipant())),
      expect: () => [
        isA<DardosParticipantState>()
            .having((s) => s.status, 'status', DardosParticipantStatus.error),
      ],
      verify: (_) => verifyNever(mockRepo.createParticipant(any)),
    );
  });

  // -----------------------------------------------------------------------
  // DeleteParticipantEvent — admin gate
  // -----------------------------------------------------------------------
  group('DeleteParticipantEvent', () {
    blocTest<DardosParticipantBloc, DardosParticipantState>(
      'admin: calls repo soft-delete and emits success',
      build: () {
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('lfexevega95@gmail.com');
        when(mockRepo.deleteParticipant(any))
            .thenAnswer((_) async => const DataSuccess(null));
        when(mockRepo.fetchAllParticipants())
            .thenAnswer((_) async => DataSuccess([makeParticipant()]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(DeleteParticipantEvent(participantId: 'p1')),
      expect: () => [
        isA<DardosParticipantState>()
            .having((s) => s.status, 'status', DardosParticipantStatus.loading),
        isA<DardosParticipantState>()
            .having((s) => s.status, 'status', DardosParticipantStatus.success),
      ],
      verify: (_) => verify(mockRepo.deleteParticipant('p1')).called(1),
    );

    blocTest<DardosParticipantBloc, DardosParticipantState>(
      'non-admin: emits error, repo NOT called',
      build: () {
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('notadmin@example.com');
        return buildBloc();
      },
      act: (bloc) => bloc.add(DeleteParticipantEvent(participantId: 'p1')),
      expect: () => [
        isA<DardosParticipantState>()
            .having((s) => s.status, 'status', DardosParticipantStatus.error),
      ],
      verify: (_) => verifyNever(mockRepo.deleteParticipant(any)),
    );
  });

  // -----------------------------------------------------------------------
  // CheckAdminStatusEvent
  // -----------------------------------------------------------------------
  group('CheckAdminStatusEvent', () {
    blocTest<DardosParticipantBloc, DardosParticipantState>(
      'admin email -> isAdmin = true',
      build: () {
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('lfexevega95@gmail.com');
        return buildBloc();
      },
      act: (bloc) => bloc.add(CheckAdminStatusEvent()),
      expect: () => [
        isA<DardosParticipantState>().having(
          (s) => s.isAdmin,
          'isAdmin',
          isTrue,
        ),
      ],
    );

    blocTest<DardosParticipantBloc, DardosParticipantState>(
      'non-admin email -> isAdmin = false',
      build: () {
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('someone@else.com');
        return buildBloc();
      },
      act: (bloc) => bloc.add(CheckAdminStatusEvent()),
      expect: () => [
        isA<DardosParticipantState>().having(
          (s) => s.isAdmin,
          'isAdmin',
          isFalse,
        ),
      ],
    );
  });
}
