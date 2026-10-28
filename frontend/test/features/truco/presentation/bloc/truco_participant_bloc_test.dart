import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_state.dart';

import '../../support/truco_fakes.dart';

const _admin = 'lfexevega95@gmail.com';

void main() {
  late FakeTrucoParticipantRepository repository;

  setUp(() {
    repository = FakeTrucoParticipantRepository(const [
      TrucoParticipant(id: 'p1', name: 'Ana'),
    ]);
  });

  TrucoParticipantBloc build({String? email}) =>
      TrucoParticipantBloc(repository, FakeAuth(email: email));

  blocTest<TrucoParticipantBloc, TrucoParticipantState>(
    'the configured admin email is admin',
    build: () => build(email: _admin),
    act: (bloc) => bloc.add(const CheckTrucoAdminStatusEvent()),
    expect: () => [const TrucoParticipantState(isAdmin: true)],
  );

  blocTest<TrucoParticipantBloc, TrucoParticipantState>(
    'any other user, or nobody signed in, is not admin',
    build: () => build(email: 'other@example.com'),
    act: (bloc) => bloc.add(const CheckTrucoAdminStatusEvent()),
    expect: () => [const TrucoParticipantState(isAdmin: false)],
  );

  blocTest<TrucoParticipantBloc, TrucoParticipantState>(
    'fetch loads the registered players',
    build: () => build(),
    act: (bloc) => bloc.add(const FetchTrucoParticipantsEvent()),
    expect: () => [
      const TrucoParticipantState(status: TrucoParticipantStatus.loading),
      const TrucoParticipantState(
        status: TrucoParticipantStatus.loaded,
        participants: [TrucoParticipant(id: 'p1', name: 'Ana')],
      ),
    ],
  );

  blocTest<TrucoParticipantBloc, TrucoParticipantState>(
    'non admins cannot create players',
    build: () => build(email: 'other@example.com'),
    act: (bloc) => bloc
      ..add(const CheckTrucoAdminStatusEvent())
      ..add(const CreateTrucoParticipantEvent('Beto')),
    expect: () => [const TrucoParticipantState(isAdmin: false)],
    verify: (_) => expect(repository.players, hasLength(1)),
  );

  blocTest<TrucoParticipantBloc, TrucoParticipantState>(
    'admin creates a player with a trimmed name',
    build: () => build(email: _admin),
    act: (bloc) => bloc
      ..add(const CheckTrucoAdminStatusEvent())
      ..add(const CreateTrucoParticipantEvent('  Beto ')),
    skip: 2,
    expect: () => [
      const TrucoParticipantState(
        status: TrucoParticipantStatus.created,
        isAdmin: true,
        participants: [TrucoParticipant(id: 'new1', name: 'Beto')],
      ),
    ],
  );

  blocTest<TrucoParticipantBloc, TrucoParticipantState>(
    'an empty name is rejected without calling the repository',
    build: () => build(email: _admin),
    act: (bloc) => bloc
      ..add(const CheckTrucoAdminStatusEvent())
      ..add(const CreateTrucoParticipantEvent('   ')),
    skip: 1,
    expect: () => [
      const TrucoParticipantState(
        status: TrucoParticipantStatus.error,
        isAdmin: true,
        error: 'El nombre no puede estar vacío.',
      ),
    ],
  );

  blocTest<TrucoParticipantBloc, TrucoParticipantState>(
    'admin renames and deletes players',
    build: () => build(email: _admin),
    seed: () => const TrucoParticipantState(
      isAdmin: true,
      participants: [TrucoParticipant(id: 'p1', name: 'Ana')],
    ),
    act: (bloc) => bloc
      ..add(const UpdateTrucoParticipantEvent('p1', 'Ana María'))
      ..add(const DeleteTrucoParticipantEvent('p1')),
    expect: () => [
      const TrucoParticipantState(
        status: TrucoParticipantStatus.loading,
        isAdmin: true,
        participants: [TrucoParticipant(id: 'p1', name: 'Ana')],
      ),
      const TrucoParticipantState(
        status: TrucoParticipantStatus.updated,
        isAdmin: true,
        participants: [TrucoParticipant(id: 'p1', name: 'Ana María')],
      ),
      const TrucoParticipantState(
        status: TrucoParticipantStatus.loading,
        isAdmin: true,
        participants: [TrucoParticipant(id: 'p1', name: 'Ana María')],
      ),
      const TrucoParticipantState(
        status: TrucoParticipantStatus.deleted,
        isAdmin: true,
      ),
    ],
  );

  blocTest<TrucoParticipantBloc, TrucoParticipantState>(
    'repository failures surface as an error',
    build: () {
      repository.fail = true;
      return build();
    },
    act: (bloc) => bloc.add(const FetchTrucoParticipantsEvent()),
    skip: 1,
    expect: () => [
      isA<TrucoParticipantState>()
          .having((s) => s.status, 'status', TrucoParticipantStatus.error)
          .having((s) => s.error, 'error', isNotNull),
    ],
  );
}
