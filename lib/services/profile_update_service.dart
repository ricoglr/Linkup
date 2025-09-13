import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';

class ProfileUpdateService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Profil bilgilerini güncelle
  Future<void> updateProfile({
    String? displayName,
    String? username,
    String? about,
    String? phone,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final updates = <String, dynamic>{};
      
      // Firebase Auth'da display name güncelle
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        updates['displayName'] = displayName;
      }

      // Firestore'da kullanıcı bilgilerini güncelle
      if (username != null) updates['username'] = username;
      if (about != null) updates['about'] = about;
      if (phone != null) updates['phone'] = phone;
      
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      throw Exception('Profil güncellenirken hata oluştu: $e');
    }
  }

  // Profil fotoğrafını güncelle
  Future<String> updateProfilePhoto(ImageSource source) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Fotoğraf seç
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image == null) throw Exception('Fotoğraf seçilmedi');

      // Storage'a yükle
      final String fileName = 'profile_photos/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(fileName);
      
      final UploadTask uploadTask = storageRef.putFile(File(image.path));
      final TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state != TaskState.success) {
        throw Exception('Fotoğraf yüklenemedi');
      }

      // Download URL al
      final String downloadURL = await storageRef.getDownloadURL();

      // Firebase Auth'da profil fotoğrafını güncelle
      await user.updatePhotoURL(downloadURL);

      // Firestore'da da güncelle
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': downloadURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return downloadURL;
    } catch (e) {
      throw Exception('Profil fotoğrafı güncellenirken hata oluştu: $e');
    }
  }

  // Şifre değiştir
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Mevcut şifreyi doğrula
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Yeni şifreyi ayarla
      await user.updatePassword(newPassword);

      // Firestore'da şifre değişiklik tarihini kaydet
      await _firestore.collection('users').doc(user.uid).update({
        'passwordChangedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            throw Exception('Mevcut şifre yanlış');
          case 'weak-password':
            throw Exception('Yeni şifre çok zayıf');
          case 'requires-recent-login':
            throw Exception('Güvenlik nedeniyle yeniden giriş yapmanız gerekiyor');
          default:
            throw Exception('Şifre değiştirirken hata oluştu: ${e.message}');
        }
      }
      throw Exception('Şifre değiştirirken hata oluştu: $e');
    }
  }

  // Email değiştir (doğrulama gerekli)
  Future<void> updateEmail(String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Mevcut şifreyi doğrula
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Email değişikliği için doğrulama gönder
      await user.verifyBeforeUpdateEmail(newEmail);

      // Firestore'da pending email olarak kaydet
      await _firestore.collection('users').doc(user.uid).update({
        'pendingEmail': newEmail,
        'emailUpdateRequestedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            throw Exception('Şifre yanlış');
          case 'email-already-in-use':
            throw Exception('Bu email adresi zaten kullanımda');
          case 'invalid-email':
            throw Exception('Geçersiz email adresi');
          default:
            throw Exception('Email güncellenirken hata oluştu: ${e.message}');
        }
      }
      throw Exception('Email güncellenirken hata oluştu: $e');
    }
  }

  // Telefon numarası doğrulama kodu gönder
  Future<void> sendPhoneVerificationCode(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(String) onError,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Otomatik doğrulama tamamlandı (Android'de SMS'i otomatik okuyabilir)
          await _linkPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'Telefon doğrulama başarısız';
          
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Geçersiz telefon numarası';
              break;
            case 'too-many-requests':
              errorMessage = 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota aşıldı';
              break;
          }
          
          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Otomatik kod alma zaman aşımı
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError('Doğrulama kodu gönderilirken hata oluştu: $e');
    }
  }

  // Telefon doğrulama kodunu kontrol et
  Future<void> verifyPhoneCode(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _linkPhoneCredential(credential);
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            throw Exception('Geçersiz doğrulama kodu');
          case 'invalid-verification-id':
            throw Exception('Geçersiz doğrulama ID');
          default:
            throw Exception('Telefon doğrulanırken hata oluştu: ${e.message}');
        }
      }
      throw Exception('Telefon doğrulanırken hata oluştu: $e');
    }
  }

  // Telefon credential'ını hesaba bağla
  Future<void> _linkPhoneCredential(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

    try {
      await user.linkWithCredential(credential);
      
      // Firestore'da telefon numarasını güncelle
      await _firestore.collection('users').doc(user.uid).update({
        'phone': user.phoneNumber,
        'phoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'provider-already-linked') {
        // Telefon zaten bağlı, sadece Firestore'u güncelle
        await _firestore.collection('users').doc(user.uid).update({
          'phone': user.phoneNumber, // credential'dan değil user'dan al
          'phoneVerified': true,
          'phoneVerifiedAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw e;
      }
    }
  }

  // Email doğrulama durumunu kontrol et
  Future<bool> checkEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    final updatedUser = _auth.currentUser;
    
    if (updatedUser?.emailVerified == true) {
      // Email doğrulandıysa Firestore'u güncelle
      await _firestore.collection('users').doc(updatedUser!.uid).update({
        'emailVerified': true,
        'emailVerifiedAt': FieldValue.serverTimestamp(),
      });

      // Pending email varsa güncelle
      final userDoc = await _firestore.collection('users').doc(updatedUser.uid).get();
      final userData = userDoc.data();
      
      if (userData?['pendingEmail'] != null) {
        await _firestore.collection('users').doc(updatedUser.uid).update({
          'email': userData!['pendingEmail'],
          'pendingEmail': FieldValue.delete(),
          'emailUpdateRequestedAt': FieldValue.delete(),
        });
      }

      return true;
    }

    return false;
  }

  // Email doğrulama gönder
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

    if (user.emailVerified) {
      throw Exception('Email adresi zaten doğrulanmış');
    }

    try {
      await user.sendEmailVerification();
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'too-many-requests':
            throw Exception('Çok fazla doğrulama emaili gönderildi. Lütfen daha sonra tekrar deneyin');
          default:
            throw Exception('Doğrulama emaili gönderilirken hata oluştu: ${e.message}');
        }
      }
      throw Exception('Doğrulama emaili gönderilirken hata oluştu: $e');
    }
  }

  // Kullanıcı adı benzersizlik kontrolü
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      // Eğer sonuç varsa ve bu kullanıcının kendisi değilse, username alınmış
      for (var doc in querySnapshot.docs) {
        if (doc.id != user.uid) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Random verification code oluştur (telefon için backup)
  String generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Hesap silme
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Şifreyi doğrula
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Kullanıcı verilerini Firestore'dan sil
      await _deleteUserData(user.uid);

      // Profil fotoğrafını Storage'dan sil
      await _deleteUserProfilePhoto(user.uid);

      // Firebase Auth'dan hesabı sil
      await user.delete();
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            throw Exception('Şifre yanlış');
          case 'requires-recent-login':
            throw Exception('Güvenlik nedeniyle yeniden giriş yapmanız gerekiyor');
          default:
            throw Exception('Hesap silinirken hata oluştu: ${e.message}');
        }
      }
      throw Exception('Hesap silinirken hata oluştu: $e');
    }
  }

  // Kullanıcı verilerini Firestore'dan sil
  Future<void> _deleteUserData(String userId) async {
    final batch = _firestore.batch();

    // Kullanıcı dökümanını sil
    batch.delete(_firestore.collection('users').doc(userId));

    // Kullanıcının istatistiklerini sil
    batch.delete(_firestore.collection('user_stats').doc(userId));

    // Kullanıcının rozetlerini sil
    final userBadges = await _firestore
        .collection('user_badges')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in userBadges.docs) {
      batch.delete(doc.reference);
    }

    // Kullanıcının organize ettiği etkinlikleri sil veya sahipliği devret
    final organizedEvents = await _firestore
        .collection('events')
        .where('organizerId', isEqualTo: userId)
        .get();

    for (var doc in organizedEvents.docs) {
      // Etkinliği sil veya başka birine devret (iş kuralına göre)
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Profil fotoğrafını Storage'dan sil
  Future<void> _deleteUserProfilePhoto(String userId) async {
    try {
      final listResult = await _storage.ref('profile_photos').listAll();
      
      for (var item in listResult.items) {
        if (item.name.startsWith(userId)) {
          await item.delete();
        }
      }
    } catch (e) {
      // Storage'da fotoğraf yoksa hata vermesin
      print('Profile photo deletion error: $e');
    }
  }
}