import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand_commit.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/domain/repository/truco_game_repository.dart';
import 'package:news_app_clean_architecture/features/truco/domain/repository/truco_participant_repository.dart';

class FakeUser extends Fake implements User {
  @override
  final String? email;

  FakeUser(this.email);
}

class FakeAuth extends Fake implements FirebaseAuth {
  @override
  User? currentUser;

  FakeAuth({String? email}) : currentUser = email == null ? null : FakeUser(email);
}

class FakeTrucoParticipantRepository implements TrucoParticipantRepository {
  final List<TrucoParticipant> players;
  bool fail = false;
  var _nextId = 1;

  FakeTrucoParticipantRepository([List<TrucoParticipant>? players])
      : players = [...?players];

  DataFailed<T> _failure<T>() => DataFailed<T>(Exception('boom'));

  @override
  Future<DataState<TrucoParticipant>> createParticipant(String name) async {
    if (fail) return _failure();
    final created = TrucoParticipant(id: 'new${_nextId++}', name: name);
    players.add(created);
    return DataSuccess(created);
  }

  @override
  Future<DataState<TrucoParticipant>> updateParticipant(
    String id, {
    required String name,
  }) async {
    if (fail) return _failure();
    final index = players.indexWhere((p) => p.id == id);
    players[index] = players[index].copyWith(name: name);
    return DataSuccess(players[index]);
  }

  @override
  Future<DataState<void>> deleteParticipant(String id) async {
    if (fail) return _failure();
    players.removeWhere((p) => p.id == id);
    return const DataSuccess(null);
  }

  @override
  Future<DataState<List<TrucoParticipant>>> fetchAllParticipants() async {
    if (fail) return _failure();
    return DataSuccess([...players]);
  }
}

class FakeTrucoGameRepository implements TrucoGameRepository {
  TrucoGame? game;
  List<TrucoGame> games = [];
  final List<TrucoHandCommit> commits = [];
  final StreamController<DataState<TrucoGame>> remote =
      StreamController<DataState<TrucoGame>>.broadcast();

  /// When set, commitHand waits for it (lets tests observe the optimistic
  /// state before the write resolves).
  Completer<DataState<void>>? commitResult;
  bool failCreate = false;

  @override
  Future<DataState<TrucoGame>> createGame({
    required TrucoMode mode,
    required int targetScore,
    required TrucoTeam teamA,
    required TrucoTeam teamB,
  }) async {
    if (failCreate) return DataFailed(Exception('boom'));
    final created = TrucoGame(
      id: 'created',
      mode: mode,
      targetScore: targetScore,
      teamA: teamA,
      teamB: teamB,
      date: 1,
    );
    game = created;
    return DataSuccess(created);
  }

  @override
  Future<DataState<TrucoGame>> getGame(String gameId) async {
    final current = game;
    if (current == null) return DataFailed(Exception('Game not found'));
    return DataSuccess(current);
  }

  @override
  Stream<DataState<TrucoGame>> watchGame(String gameId) => remote.stream;

  @override
  Future<DataState<List<TrucoGame>>> getGames() async => DataSuccess(games);

  @override
  Future<DataState<void>> commitHand(TrucoHandCommit commit) async {
    commits.add(commit);
    final pending = commitResult;
    if (pending != null) return pending.future;
    return const DataSuccess(null);
  }
}
