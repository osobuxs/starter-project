import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/models/participant_model.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/participant.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/participant_repository.dart';

class ParticipantRepositoryImpl implements ParticipantRepository {
  final FirebaseFirestore _firestore;

  ParticipantRepositoryImpl(this._firestore);

  @override
  Future<DataState<ParticipantEntity>> createParticipant(
    String name,
    String? email,
  ) async {
    try {
      final docRef = _firestore.collection('participants').doc();
      final model = ParticipantModel(
        id: docRef.id,
        name: name,
        email: email,
        totalGamesPlayed: 0,
        totalGamesWon: 0,
        isActive: true,
      );

      await docRef.set(model.toJson());
      return DataSuccess(model);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<ParticipantEntity>> updateParticipant(
    String id, {
    String? name,
    String? email,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;

      if (updates.isNotEmpty) {
        await _firestore.collection('participants').doc(id).update(updates);
      }

      final snapshot =
          await _firestore.collection('participants').doc(id).get();
      return DataSuccess(
        ParticipantModel.fromFirestore(snapshot.data() ?? {}, id),
      );
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> deleteParticipant(String id) async {
    try {
      await _firestore.collection('participants').doc(id).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<ParticipantEntity>>> fetchAllParticipants() async {
    try {
      final snapshot =
          await _firestore.collection('participants').orderBy('name').get();

      final participants = snapshot.docs
          .map((doc) => ParticipantModel.fromFirestore(doc.data(), doc.id))
          .where((participant) => participant.isActive)
          .toList();

      return DataSuccess(participants);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<ParticipantEntity>> fetchParticipantById(String id) async {
    try {
      final snapshot =
          await _firestore.collection('participants').doc(id).get();

      if (!snapshot.exists) {
        throw Exception('Participant not found');
      }

      return DataSuccess(
        ParticipantModel.fromFirestore(snapshot.data() ?? {}, id),
      );
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }
}
