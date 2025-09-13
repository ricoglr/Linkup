import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_update_service.dart';

class ProfileUpdateProvider with ChangeNotifier {
  final ProfileUpdateService _profileService = ProfileUpdateService();
  
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  String? _verificationId;
  bool _isPhoneVerified = false;
  bool _isEmailVerified = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  String? get verificationId => _verificationId;
  bool get isPhoneVerified => _isPhoneVerified;
  bool get isEmailVerified => _isEmailVerified;

  // Profil bilgilerini güncelle
  Future<void> updateProfile({
    String? displayName,
    String? username,
    String? about,
    String? phone,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      // Username benzersizlik kontrolü
      if (username != null && username.isNotEmpty) {
        final isAvailable = await _profileService.isUsernameAvailable(username);
        if (!isAvailable) {
          throw Exception('Bu kullanıcı adı zaten alınmış');
        }
      }

      await _profileService.updateProfile(
        displayName: displayName,
        username: username,
        about: about,
        phone: phone,
      );

      _setSuccessMessage('Profil başarıyla güncellendi');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Profil fotoğrafını güncelle
  Future<String?> updateProfilePhoto(ImageSource source) async {
    _setLoading(true);
    _clearMessages();

    try {
      final downloadURL = await _profileService.updateProfilePhoto(source);
      _setSuccessMessage('Profil fotoğrafı başarıyla güncellendi');
      return downloadURL;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Şifre değiştir
  Future<void> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _profileService.changePassword(currentPassword, newPassword);
      _setSuccessMessage('Şifre başarıyla değiştirildi');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Email güncelle
  Future<void> updateEmail(String newEmail, String password) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _profileService.updateEmail(newEmail, password);
      _setSuccessMessage('Email güncelleme için doğrulama kodu gönderildi');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Telefon doğrulama kodu gönder
  Future<void> sendPhoneVerificationCode(String phoneNumber) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _profileService.sendPhoneVerificationCode(
        phoneNumber,
        (verificationId) {
          _verificationId = verificationId;
          _setSuccessMessage('Doğrulama kodu gönderildi');
          _setLoading(false);
          notifyListeners();
        },
        (error) {
          _setError(error);
          _setLoading(false);
          notifyListeners();
        },
      );
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Telefon doğrulama kodunu kontrol et
  Future<void> verifyPhoneCode(String smsCode) async {
    if (_verificationId == null) {
      _setError('Doğrulama ID bulunamadı');
      return;
    }

    _setLoading(true);
    _clearMessages();

    try {
      await _profileService.verifyPhoneCode(_verificationId!, smsCode);
      _isPhoneVerified = true;
      _setSuccessMessage('Telefon numarası başarıyla doğrulandı');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Email doğrulama durumunu kontrol et
  Future<void> checkEmailVerification() async {
    try {
      final isVerified = await _profileService.checkEmailVerification();
      _isEmailVerified = isVerified;
      
      if (isVerified) {
        _setSuccessMessage('Email adresi başarıyla doğrulandı');
      }
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Email doğrulama gönder
  Future<void> sendEmailVerification() async {
    _setLoading(true);
    _clearMessages();

    try {
      await _profileService.sendEmailVerification();
      _setSuccessMessage('Doğrulama emaili gönderildi');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Username benzersizlik kontrolü
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      return await _profileService.isUsernameAvailable(username);
    } catch (e) {
      return false;
    }
  }

  // Hesap silme
  Future<void> deleteAccount(String password) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _profileService.deleteAccount(password);
      _setSuccessMessage('Hesap başarıyla silindi');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    _successMessage = message;
    _error = null;
    notifyListeners();
  }

  void _clearMessages() {
    _error = null;
    _successMessage = null;
  }

  void clearMessages() {
    _clearMessages();
    notifyListeners();
  }

  void clearVerificationId() {
    _verificationId = null;
    notifyListeners();
  }

  // Form validation helpers
  String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'İsim boş olamaz';
    }
    
    if (value.trim().length < 2) {
      return 'İsim en az 2 karakter olmalıdır';
    }
    
    if (value.trim().length > 50) {
      return 'İsim en fazla 50 karakter olabilir';
    }
    
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kullanıcı adı boş olamaz';
    }
    
    if (value.trim().length < 3) {
      return 'Kullanıcı adı en az 3 karakter olmalıdır';
    }
    
    if (value.trim().length > 20) {
      return 'Kullanıcı adı en fazla 20 karakter olabilir';
    }
    
    // Sadece alfanumerik ve alt çizgi
    final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return 'Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir';
    }
    
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Telefon opsiyonel
    }
    
    // Basit telefon validasyonu
    final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Geçerli bir telefon numarası girin (+90xxxxxxxxxx)';
    }
    
    return null;
  }

  String? validateAbout(String? value) {
    if (value != null && value.trim().length > 500) {
      return 'Hakkında bölümü en fazla 500 karakter olabilir';
    }
    
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre boş olamaz';
    }
    
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }
    
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Yeni şifre boş olamaz';
    }
    
    if (value.length < 8) {
      return 'Yeni şifre en az 8 karakter olmalıdır';
    }
    
    // En az bir büyük harf, bir küçük harf ve bir rakam
    final RegExp passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(value)) {
      return 'Şifre en az 1 büyük harf, 1 küçük harf ve 1 rakam içermelidir';
    }
    
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email boş olamaz';
    }
    
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir email adresi girin';
    }
    
    return null;
  }

  String? validateVerificationCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Doğrulama kodu boş olamaz';
    }
    
    if (value.trim().length != 6) {
      return 'Doğrulama kodu 6 haneli olmalıdır';
    }
    
    final RegExp codeRegex = RegExp(r'^\d{6}$');
    if (!codeRegex.hasMatch(value.trim())) {
      return 'Doğrulama kodu sadece rakam içermelidir';
    }
    
    return null;
  }
}