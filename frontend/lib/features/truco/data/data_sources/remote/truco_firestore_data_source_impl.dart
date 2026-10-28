import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/features/truco/data/data_sources/remote/truco_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/truco/data/models/truco_game_model.dart';
import 'package:news_app_clean_architecture/features/truco/data/models/truco_hand_model.dart';
import 'package:news_app_clean_architecture/features/truco/data/models/truco_participant_model.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand_commit.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';

class TrucoFirestoreDataSourceImpl implements TrucoFirestoreDataSource {
  static const gamesCollection = 'truco_games';
  static const handsCollection = 'hands';
  static const participantsCollection = 'truco_participants';

  final FirebaseFirestore _firestore;
  final int Function() _now;

  TrucoFirestoreDataSourceImpl(this._firestore, {int Function()? now})
      : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  CollectionReference<Map<String, dynamic>> get _games =>
      _firestore.collection(gamesCollection);

  CollectionReference<Map<String, dynamic>> get _participants =>
      _firestore.collection(participantsCollection);

  @override
  Future<TrucoGame> createGame({
    required TrucoMode mode,
    required int targetScore,
    required TrucoTeam teamA,
    required TrucoTeam teamB,
  }) async {
    final ref = _games.doc();
    final game = TrucoGame(
      id: ref.id,
      mode: mode,
      targetScore: targetScore,
      teamA: teamA,
      teamB: teamB,
      date: _now(),
    );
    await ref.set(TrucoGameModel.toJson(game));
    return game;
  }

  @override
  Future<TrucoGame> getGame(String gameId) async {
    final snapshot = await _games.doc(gameId).get();
    if (!snapshot.exists) {
      throw Exception('Game not found');
    }
    final hands = await _handsQuery(gameId).get();
    return TrucoGameModel.fromFirestore(
      gameId,
      snapshot.data()!,
      _handsFrom(hands),
    );
  }

  @override
  Stream<TrucoGame> watchGame(String gameId) {
    // Combines the game document and its hands into one stream. Emits once
    // both listeners delivered their first snapshot, then on every change.
    late final StreamController<TrucoGame> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? gameSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? handsSub;
    Map<String, dynamic>? latestGame;
    List<TrucoHand>? latestHands;

    void emitIfReady() {
      final data = latestGame;
      final hands = latestHands;
      if (data == null || hands == null || controller.isClosed) return;
      try {
        controller.add(TrucoGameModel.fromFirestore(gameId, data, hands));
      } catch (e, st) {
        controller.addError(e, st);
      }
    }

    controller = StreamController<TrucoGame>(
      onListen: () {
        gameSub = _games.doc(gameId).snapshots().listen(
          (snapshot) {
            if (!snapshot.exists) {
              controller.addError(Exception('Game not found'));
              return;
            }
            latestGame = snapshot.data();
            emitIfReady();
          },
          onError: controller.addError,
        );
        handsSub = _handsQuery(gameId).snapshots().listen(
          (snapshot) {
            latestHands = _handsFrom(snapshot);
            emitIfReady();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await gameSub?.cancel();
        await handsSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<List<TrucoGame>> getGames() async {
    final snapshot = await _games.orderBy('date', descending: true).get();
    return Future.wait(snapshot.docs.map((doc) async {
      final hands = await _handsQuery(doc.id).get();
      return TrucoGameModel.fromFirestore(doc.id, doc.data(), _handsFrom(hands));
    }));
  }

  @override
  Future<void> commitHand(TrucoHandCommit commit) async {
    final gameRef = _games.doc(commit.gameId);
    final handRef = gameRef
        .collection(handsCollection)
        .doc(commit.hand.handNumber.toString());
    final batch = _firestore.batch();

    batch.set(handRef, TrucoHandModel.toJson(commit.hand));

    final gameUpdate = <String, dynamic>{
      'scoreA': commit.scoreA,
      'scoreB': commit.scoreB,
      'currentHand': commit.nextHandNumber,
    };
    final winner = commit.winner;
    if (winner != null) {
      gameUpdate['winnerTeam'] = winner.key;
      gameUpdate['status'] = TrucoGameStatus.finished.name;
    } else if (commit.isEdit) {
      // The corrected hand no longer finishes the game.
      gameUpdate['winnerTeam'] = null;
      gameUpdate['status'] = TrucoGameStatus.playing.name;
    }
    batch.update(gameRef, gameUpdate);

    _addStatsDeltas(batch, commit);

    // Applied to the local cache right away (listeners fire immediately);
    // the future completes once the server acknowledges it.
    await batch.commit();
  }

  /// Undoes the stats of the reverted finish (if any) and applies the ones
  /// of the new finish (if any), as net increments per player. A win counts
  /// for every member of the winning team.
  void _addStatsDeltas(WriteBatch batch, TrucoHandCommit commit) {
    final winner = commit.winner;
    final revert = commit.revertWinner;
    final playedDelta = (winner != null ? 1 : 0) - (revert != null ? 1 : 0);
    final winners = winner == null ? const <String>[] : commit.playersOf(winner);
    final reverted =
        revert == null ? const <String>[] : commit.playersOf(revert);

    for (final playerId in [
      ...commit.teamAPlayerIds,
      ...commit.teamBPlayerIds,
    ]) {
      final wonDelta = (winners.contains(playerId) ? 1 : 0) -
          (reverted.contains(playerId) ? 1 : 0);
      if (playedDelta == 0 && wonDelta == 0) continue;

      // Merge instead of update: a missing player doc must not make the
      // whole hand batch fail.
      batch.set(
        _participants.doc(playerId),
        {
          if (playedDelta != 0)
            'totalGamesPlayed': FieldValue.increment(playedDelta),
          if (wonDelta != 0) 'totalGamesWon': FieldValue.increment(wonDelta),
        },
        SetOptions(merge: true),
      );
    }
  }

  Query<Map<String, dynamic>> _handsQuery(String gameId) {
    return _games
        .doc(gameId)
        .collection(handsCollection)
        .orderBy('handNumber');
  }

  List<TrucoHand> _handsFrom(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => TrucoHandModel.fromFirestore(doc.data()))
        .toList();
  }

  @override
  Future<TrucoParticipant> createParticipant(String name) async {
    final ref = _participants.doc();
    final participant = TrucoParticipant(id: ref.id, name: name);
    await ref.set(TrucoParticipantModel.toJson(participant));
    return participant;
  }

  @override
  Future<TrucoParticipant> updateParticipant(
    String id, {
    required String name,
  }) async {
    final ref = _participants.doc(id);
    await ref.update({'name': name});
    final snapshot = await ref.get();
    return TrucoParticipantModel.fromFirestore(id, snapshot.data() ?? {});
  }

  @override
  Future<void> deleteParticipant(String id) async {
    // Soft delete: finished games keep pointing at the player.
    await _participants.doc(id).update({
      'isActive': false,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<TrucoParticipant>> fetchAllParticipants() async {
    final snapshot = await _participants.orderBy('name').get();
    return snapshot.docs
        .map((doc) => TrucoParticipantModel.fromFirestore(doc.id, doc.data()))
        .where((participant) => participant.isActive)
        .toList();
  }
}
