import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
