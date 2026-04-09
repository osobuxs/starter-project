import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:news_app_clean_architecture/features/auth/data/models/user_model.dart';

abstract class AuthFirebaseDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  });
  Future<UserModel> signInWithGoogle();
  Future<void> logout();
  UserModel? getCurrentUser();
}

class AuthFirebaseDataSourceImpl implements AuthFirebaseDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthFirebaseDataSourceImpl(
    this._firebaseAuth,
    this._googleSignIn,
    this._firestore,
  );

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserModel.fromFirebaseUser(credential.user!);
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(displayName);
    await credential.user!.reload();
    final updatedUser = _firebaseAuth.currentUser!;
    await _ensureUserProfile(
      uid: updatedUser.uid,
      email: updatedUser.email ?? email,
      displayName: updatedUser.displayName ?? displayName,
    );
    return UserModel.fromFirebaseUser(updatedUser);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception('Google sign-in did not return an ID token');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user!;
    await _ensureUserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Usuario',
    );
    return UserModel.fromFirebaseUser(userCredential.user!);
  }

  @override
  Future<void> logout() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.disconnect()]);
  }

  @override
  UserModel? getCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return UserModel.fromFirebaseUser(user);
  }

  Future<void> _ensureUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      return;
    }

    final now = DateTime.now();
    await userRef.set({
      'name': displayName,
      'email': email,
      'age': null,
      'photoUrl': null,
      'createdAt': now,
      'updatedAt': now,
    });
  }
}
