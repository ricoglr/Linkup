import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SocialAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google ile giriş
  Future<User?> signInWithGoogle() async {
    try {
      // Google Sign-In flow'unu başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Kullanıcı işlemi iptal etti
        return null;
      }

      // Google authentication'ı al
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Firebase credential oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase'de oturum aç
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);

      // Kullanıcı bilgilerini Firestore'da sakla/güncelle
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!, 'google');
      }

      return userCredential.user;
    } catch (e) {
      print('Google Sign-In Error: $e');
      throw Exception('Google ile giriş yapılamadı: $e');
    }
  }

  // Facebook ile giriş
  Future<User?> signInWithFacebook() async {
    try {
      // Facebook login'i başlat
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Facebook access token'ı al
        final AccessToken accessToken = result.accessToken!;

        // Firebase credential oluştur
        final OAuthCredential credential = 
            FacebookAuthProvider.credential(accessToken.token);

        // Firebase'de oturum aç
        final UserCredential userCredential = 
            await _firebaseAuth.signInWithCredential(credential);

        // Kullanıcı bilgilerini Firestore'da sakla/güncelle
        if (userCredential.user != null) {
          await _saveUserToFirestore(userCredential.user!, 'facebook');
        }

        return userCredential.user;
      } else {
        print('Facebook Login Failed: ${result.status}');
        return null;
      }
    } catch (e) {
      print('Facebook Sign-In Error: $e');
      throw Exception('Facebook ile giriş yapılamadı: $e');
    }
  }

  // Kullanıcı bilgilerini Firestore'da sakla/güncelle
  Future<void> _saveUserToFirestore(User user, String loginProvider) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();

      final userData = {
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'loginProvider': loginProvider,
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      if (userSnapshot.exists) {
        // Kullanıcı zaten varsa güncelle
        await userDoc.update(userData);
      } else {
        // Yeni kullanıcı oluştur
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['username'] = user.displayName ?? 'User_${user.uid.substring(0, 6)}';
        userData['phone'] = '';
        userData['about'] = '';
        
        await userDoc.set(userData);
      }
    } catch (e) {
      print('Error saving user to Firestore: $e');
    }
  }

  // Google hesabından çıkış
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Google Sign-Out Error: $e');
    }
  }

  // Facebook hesabından çıkış
  Future<void> signOutFromFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Facebook Sign-Out Error: $e');
    }
  }

  // Genel çıkış (tüm provider'lardan)
  Future<void> signOut() async {
    try {
      // Mevcut kullanıcının giriş provider'ını kontrol et
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        for (final providerProfile in user.providerData) {
          if (providerProfile.providerId == 'google.com') {
            await _googleSignIn.signOut();
          } else if (providerProfile.providerId == 'facebook.com') {
            await FacebookAuth.instance.logOut();
          }
        }
      }
      
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Sign-Out Error: $e');
    }
  }

  // Kullanıcının hangi provider ile giriş yaptığını kontrol et
  String? getCurrentLoginProvider() {
    final user = _firebaseAuth.currentUser;
    if (user != null && user.providerData.isNotEmpty) {
      final providerId = user.providerData.first.providerId;
      switch (providerId) {
        case 'google.com':
          return 'google';
        case 'facebook.com':
          return 'facebook';
        case 'password':
          return 'email';
        default:
          return providerId;
      }
    }
    return null;
  }

  // Hesap bağlama (linking) - kullanıcı birden fazla provider ile giriş yapabilir
  Future<User?> linkWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final userCredential = await user.linkWithCredential(credential);
        return userCredential.user;
      }
      
      return null;
    } catch (e) {
      print('Link with Google Error: $e');
      throw Exception('Google hesabı bağlanamadı: $e');
    }
  }

  Future<User?> linkWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = 
            FacebookAuthProvider.credential(accessToken.token);

        final user = _firebaseAuth.currentUser;
        if (user != null) {
          final userCredential = await user.linkWithCredential(credential);
          return userCredential.user;
        }
      }
      
      return null;
    } catch (e) {
      print('Link with Facebook Error: $e');
      throw Exception('Facebook hesabı bağlanamadı: $e');
    }
  }
}