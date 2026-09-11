import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  /// Profil (rola) uzytkownika trzymany osobno w kolekcji `users` - konta
  /// zaklada admin recznie w konsoli Firebase, wiec brak tu rejestracji.
  Stream<AppUser?> watchAppUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  /// Wszyscy uzytkownicy z przypisana rola - widoczne tylko dla admina
  /// (reguly Firestore odrzuca zapytanie dla kogokolwiek innego).
  Stream<List<AppUser>> watchAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AppUser.fromFirestore).toList());
  }

  Future<void> updateUserRole(String uid, AppRole role) async {
    await _firestore.collection('users').doc(uid).update({'role': role.name});
  }
}
