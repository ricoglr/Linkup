import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/social_login_buttons.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _error = '';
  bool _isLogin = true;
  bool _rememberMe = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        if (_isLogin) {
          await _authService.signInWithEmailAndPassword(_email, _password);
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          await _authService.registerWithEmailAndPassword(_email, _password);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kayıt başarılı! Şimdi giriş yapabilirsiniz.'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isLogin = true;
          });
        }
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Üst Kısım - Renkli Arka Plan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            color: Theme.of(context).colorScheme.primary,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo veya Uygulama İsmi

                  Text(
                    'LINK UP',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 36,
                          height: 2,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                  ),

                  const SizedBox(height: 30),
                  Text(
                    _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _isLogin
                        ? 'Bilgilerinizi Girerek Giriş Yapın'
                        : 'Bilgilerinizi Girerek Üye Olun',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondary
                              .withOpacity(0.7),
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Alt Kısım - Form
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(30),
              color: Theme.of(context).colorScheme.onSecondary,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      // Email TextField
                      CustomTextField(
                        labelText: 'Email',
                        hintText: 'mail@example.com',
                        controller: TextEditingController(text: _email),
                        validator: (value) => value!.isEmpty
                            ? 'Email alanı boş bırakılamaz'
                            : null,
                        onSaved: (value) => _email = value!,
                      ),
                      const SizedBox(height: 20),
                      // Şifre TextField
                      CustomTextField(
                        labelText: 'Şifre',
                        hintText: '••••••••',
                        controller: TextEditingController(text: _password),
                        obscureText: true,
                        validator: (value) => value!.length < 6
                            ? 'Şifre en az 6 karakter olmalı'
                            : null,
                        onSaved: (value) => _password = value!,
                      ),
                      const SizedBox(height: 20),
                      // Beni Hatırla ve Şifremi Unuttum
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                fillColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states
                                        .contains(MaterialState.selected)) {
                                      return Theme.of(context)
                                          .colorScheme
                                          .primary;
                                    }
                                    return Theme.of(context)
                                        .colorScheme
                                        .onSecondary;
                                  },
                                ),
                                checkColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                              Text(
                                'Beni Hatırla',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Şifremi Unuttum',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Giriş Yap Butonu
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      // Alternatif ile devam et
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.2)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'ya da',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                    fontSize: 16,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.2)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Sosyal medya giriş butonları
                      if (_isLogin) ...[
                        SocialLoginButtons(
                          onLoginSuccess: () {
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                          onLoginError: (error) {
                            setState(() {
                              _error = error;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 60),
                      // Kayıt Ol Linki
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Hesabınız yok mu? ',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: Text(
                              'Kayıt Ol',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
