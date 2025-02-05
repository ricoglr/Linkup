import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constant/entities.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Kullanıcı durumu stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email/Şifre ile kayıt
  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw 'Bu email adresi zaten kullanımda';
        case 'invalid-email':
          throw 'Geçersiz email formatı';
        case 'weak-password':
          throw 'Şifre en az 6 karakter olmalıdır';
        default:
          throw 'Kayıt olma hatası: ${e.message}';
      }
    }
  }

  // Email/Şifre ile giriş
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
          throw 'Email veya şifre hatalı';
        case 'user-not-found':
          throw 'Bu email ile kayıtlı kullanıcı bulunamadı';
        case 'wrong-password':
          throw 'Şifre hatalı';
        case 'invalid-email':
          throw 'Geçersiz email formatı';
        default:
          throw 'Giriş hatası: ${e.message}';
      }
    }
  }

  Future<void> registerWithDetails(
    String email,
    String password,
    String username,
    String phone,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'username': username,
      'phone': phone,
      'email': email,
      'about': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserData({String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateUserAbout(String about) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'about': about,
    });
  }

  Future<List<AppUser>> searchUsers(String query) async {
    final snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: query + 'z')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AppUser(
        id: doc.id,
        username: data['username'],
        email: data['email'],
        phone: data['phone'],
        about: data['about'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).toList();
  }
}
