import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/social_auth_service.dart';

class SocialAuthProvider with ChangeNotifier {
  final SocialAuthService _socialAuthService = SocialAuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _loginProvider;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get loginProvider => _loginProvider;
  bool get isLoggedIn => _user != null;

  SocialAuthProvider() {
    // Firebase Auth durumunu dinle
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      _loginProvider = _socialAuthService.getCurrentLoginProvider();
      notifyListeners();
    });
  }

  // Google ile giriş yap
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _socialAuthService.signInWithGoogle();
      if (user != null) {
        _user = user;
        _loginProvider = 'google';
        return true;
      }
      return false;
    } catch (e) {
      _setError('Google ile giriş yapılamadı: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Facebook ile giriş yap
  Future<bool> signInWithFacebook() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _socialAuthService.signInWithFacebook();
      if (user != null) {
        _user = user;
        _loginProvider = 'facebook';
        return true;
      }
      return false;
    } catch (e) {
      _setError('Facebook ile giriş yapılamadı: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Google hesabı bağla
  Future<bool> linkWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _socialAuthService.linkWithGoogle();
      if (user != null) {
        _user = user;
        return true;
      }
      return false;
    } catch (e) {
      _setError('Google hesabı bağlanamadı: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Facebook hesabı bağla
  Future<bool> linkWithFacebook() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _socialAuthService.linkWithFacebook();
      if (user != null) {
        _user = user;
        return true;
      }
      return false;
    } catch (e) {
      _setError('Facebook hesabı bağlanamadı: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _socialAuthService.signOut();
      _user = null;
      _loginProvider = null;
    } catch (e) {
      _setError('Çıkış yapılamadı: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Kullanıcının bağlı provider'larını al
  List<String> getLinkedProviders() {
    if (_user == null) return [];
    
    return _user!.providerData.map((provider) {
      switch (provider.providerId) {
        case 'google.com':
          return 'Google';
        case 'facebook.com':
          return 'Facebook';
        case 'password':
          return 'Email';
        default:
          return provider.providerId;
      }
    }).toList();
  }

  // Provider bilgilerini al
  Map<String, String> getProviderInfo() {
    if (_user == null) return {};
    
    final info = <String, String>{};
    
    for (final provider in _user!.providerData) {
      switch (provider.providerId) {
        case 'google.com':
          info['Google'] = provider.email ?? '';
          break;
        case 'facebook.com':
          info['Facebook'] = provider.email ?? '';
          break;
        case 'password':
          info['Email'] = provider.email ?? '';
          break;
      }
    }
    
    return info;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}