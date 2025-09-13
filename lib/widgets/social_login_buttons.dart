import 'package:flutter/material.dart';
import '../services/social_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialLoginButtons extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final Function(String)? onLoginError;

  const SocialLoginButtons({
    Key? key,
    this.onLoginSuccess,
    this.onLoginError,
  }) : super(key: key);

  @override
  State<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends State<SocialLoginButtons> {
  final SocialAuthService _socialAuthService = SocialAuthService();
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final User? user = await _socialAuthService.signInWithGoogle();
      if (user != null) {
        widget.onLoginSuccess?.call();
      }
    } catch (e) {
      widget.onLoginError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isFacebookLoading = true;
    });

    try {
      final User? user = await _socialAuthService.signInWithFacebook();
      if (user != null) {
        widget.onLoginSuccess?.call();
      }
    } catch (e) {
      widget.onLoginError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isFacebookLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Sign-In Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isGoogleLoading || _isFacebookLoading 
                ? null 
                : _handleGoogleSignIn,
            icon: _isGoogleLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.account_circle,
                        color: Colors.red,
                      );
                    },
                  ),
            label: Text(
              _isGoogleLoading 
                  ? 'Google ile giriş yapılıyor...' 
                  : 'Google ile Giriş Yap',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Facebook Sign-In Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isGoogleLoading || _isFacebookLoading 
                ? null 
                : _handleFacebookSignIn,
            icon: _isFacebookLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.facebook,
                    color: Colors.white,
                    size: 24,
                  ),
            label: Text(
              _isFacebookLoading 
                  ? 'Facebook ile giriş yapılıyor...' 
                  : 'Facebook ile Giriş Yap',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2), // Facebook mavi
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SocialLoginDivider extends StatelessWidget {
  const SocialLoginDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              thickness: 1,
              color: Colors.grey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'veya',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              thickness: 1,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// Hesap bağlama için widget
class AccountLinkingButtons extends StatefulWidget {
  final VoidCallback? onLinkSuccess;
  final Function(String)? onLinkError;

  const AccountLinkingButtons({
    Key? key,
    this.onLinkSuccess,
    this.onLinkError,
  }) : super(key: key);

  @override
  State<AccountLinkingButtons> createState() => _AccountLinkingButtonsState();
}

class _AccountLinkingButtonsState extends State<AccountLinkingButtons> {
  final SocialAuthService _socialAuthService = SocialAuthService();
  bool _isGoogleLinking = false;
  bool _isFacebookLinking = false;

  Future<void> _handleGoogleLink() async {
    setState(() {
      _isGoogleLinking = true;
    });

    try {
      final User? user = await _socialAuthService.linkWithGoogle();
      if (user != null) {
        widget.onLinkSuccess?.call();
      }
    } catch (e) {
      widget.onLinkError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLinking = false;
        });
      }
    }
  }

  Future<void> _handleFacebookLink() async {
    setState(() {
      _isFacebookLinking = true;
    });

    try {
      final User? user = await _socialAuthService.linkWithFacebook();
      if (user != null) {
        widget.onLinkSuccess?.call();
      }
    } catch (e) {
      widget.onLinkError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isFacebookLinking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hesap Bağlama',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Google Hesap Bağlama
        SizedBox(
          width: double.infinity,
          height: 45,
          child: OutlinedButton.icon(
            onPressed: _isGoogleLinking || _isFacebookLinking 
                ? null 
                : _handleGoogleLink,
            icon: _isGoogleLinking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link, size: 20),
            label: Text(
              _isGoogleLinking 
                  ? 'Google hesabı bağlanıyor...' 
                  : 'Google Hesabı Bağla',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Facebook Hesap Bağlama
        SizedBox(
          width: double.infinity,
          height: 45,
          child: OutlinedButton.icon(
            onPressed: _isGoogleLinking || _isFacebookLinking 
                ? null 
                : _handleFacebookLink,
            icon: _isFacebookLinking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link, size: 20),
            label: Text(
              _isFacebookLinking 
                  ? 'Facebook hesabı bağlanıyor...' 
                  : 'Facebook Hesabı Bağla',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}