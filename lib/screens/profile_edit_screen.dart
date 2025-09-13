import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_update_provider.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/profile_widgets.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  void _loadCurrentUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      // Diğer alanlar Firestore'dan yüklenecek
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          Consumer<ProfileUpdateProvider>(
            builder: (context, provider, child) {
              return TextButton(
                onPressed: provider.isLoading ? null : _saveProfile,
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProfileUpdateProvider>(
        builder: (context, provider, child) {
          return LoadingOverlay(
            isLoading: provider.isLoading,
            loadingText: 'Profil güncelleniyor...',
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profil fotoğrafı
                    _buildProfilePhotoSection(context, provider),
                    
                    const SizedBox(height: 32),
                    
                    // Form alanları
                    _buildFormFields(context, provider),
                    
                    const SizedBox(height: 32),
                    
                    // Güvenlik ayarları
                    _buildSecuritySection(context),
                    
                    const SizedBox(height: 32),
                    
                    // Hesap ayarları
                    _buildAccountSection(context),
                    
                    // Hata/başarı mesajları
                    if (provider.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          provider.error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                    
                    if (provider.successMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          provider.successMessage!,
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilePhotoSection(BuildContext context, ProfileUpdateProvider provider) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Center(
      child: Column(
        children: [
          ProfilePhotoWidget(
            photoUrl: user?.photoURL,
            onTap: () => _showPhotoPickerDialog(context, provider),
            radius: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Profil Fotoğrafını Değiştir',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(BuildContext context, ProfileUpdateProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Kişisel Bilgiler',
          icon: Icons.person,
        ),
        
        // Display Name
        CustomTextField(
          controller: _displayNameController,
          labelText: 'İsim Soyisim',
          hintText: 'Adınızı ve soyadınızı girin',
          prefixIcon: Icons.person,
          validator: provider.validateDisplayName,
        ),
        
        const SizedBox(height: 16),
        
        // Username
        CustomTextField(
          controller: _usernameController,
          labelText: 'Kullanıcı Adı',
          hintText: 'Benzersiz kullanıcı adınızı seçin',
          prefixIcon: Icons.alternate_email,
          validator: provider.validateUsername,
          onChanged: (value) => _checkUsernameAvailability(value, provider),
        ),
        
        const SizedBox(height: 16),
        
        // Phone
        CustomTextField(
          controller: _phoneController,
          labelText: 'Telefon Numarası',
          hintText: '+90 5XX XXX XX XX',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: provider.validatePhone,
          suffixIcon: provider.isPhoneVerified
              ? const Icon(Icons.verified, color: Colors.green)
              : IconButton(
                  onPressed: () => _verifyPhone(provider),
                  icon: const Icon(Icons.verified_user),
                ),
        ),
        
        const SizedBox(height: 16),
        
        // About
        CustomTextField(
          controller: _aboutController,
          labelText: 'Hakkında',
          hintText: 'Kendiniz hakkında birkaç kelime yazın',
          prefixIcon: Icons.info,
          maxLines: 3,
          validator: provider.validateAbout,
        ),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Güvenlik',
          icon: Icons.security,
        ),
        
        ProfileInfoCard(
          title: 'Şifreyi Değiştir',
          subtitle: 'Hesap güvenliğiniz için düzenli olarak değiştirin',
          icon: Icons.lock,
          onTap: () => _showChangePasswordDialog(context),
        ),
        
        const SizedBox(height: 8),
        
        ProfileInfoCard(
          title: 'Email Adresi',
          subtitle: FirebaseAuth.instance.currentUser?.email ?? '',
          icon: Icons.email,
          onTap: () => _showChangeEmailDialog(context),
          trailing: VerificationBadge(
            isVerified: FirebaseAuth.instance.currentUser?.emailVerified == true,
            onVerify: () => context.read<ProfileUpdateProvider>().sendEmailVerification(),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Hesap',
          icon: Icons.account_circle,
        ),
        
        ProfileInfoCard(
          title: 'Gizlilik Ayarları',
          subtitle: 'Profil görünürlüğü ve gizlilik',
          icon: Icons.privacy_tip,
          onTap: () {
            // TODO: Gizlilik ayarları sayfası
          },
        ),
        
        const SizedBox(height: 8),
        
        DangerZoneCard(
          title: 'Hesabı Sil',
          subtitle: 'Bu işlem geri alınamaz. Tüm verileriniz silinecektir.',
          buttonText: 'Hesabı Sil',
          icon: Icons.delete_forever,
          onPressed: () => _showDeleteAccountDialog(context),
        ),
      ],
    );
  }

  void _showPhotoPickerDialog(BuildContext context, ProfileUpdateProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                provider.updateProfilePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                provider.updateProfilePhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('İptal'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifreyi Değiştir'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: currentPasswordController,
                labelText: 'Mevcut Şifre',
                hintText: 'Mevcut şifrenizi girin',
                prefixIcon: Icons.lock,
                obscureText: true,
                validator: context.read<ProfileUpdateProvider>().validatePassword,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: newPasswordController,
                labelText: 'Yeni Şifre',
                hintText: 'En az 6 karakter',
                prefixIcon: Icons.lock_open,
                obscureText: true,
                validator: context.read<ProfileUpdateProvider>().validateNewPassword,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: confirmPasswordController,
                labelText: 'Yeni Şifre Tekrar',
                hintText: 'Yeni şifreyi tekrar girin',
                prefixIcon: Icons.lock_open,
                obscureText: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<ProfileUpdateProvider>().changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Adresi Değiştir'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: emailController,
                labelText: 'Yeni Email',
                hintText: 'yeni@email.com',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: context.read<ProfileUpdateProvider>().validateEmail,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: passwordController,
                labelText: 'Mevcut Şifre',
                hintText: 'Şifrenizi girin',
                prefixIcon: Icons.lock,
                obscureText: true,
                validator: context.read<ProfileUpdateProvider>().validatePassword,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<ProfileUpdateProvider>().updateEmail(
                  emailController.text,
                  passwordController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bu işlem geri alınamaz. Tüm verileriniz silinecektir.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: passwordController,
                labelText: 'Şifrenizi Girin',
                hintText: 'Hesap silme için şifrenizi girin',
                prefixIcon: Icons.lock,
                obscureText: true,
                validator: context.read<ProfileUpdateProvider>().validatePassword,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<ProfileUpdateProvider>().deleteAccount(
                  passwordController.text,
                );
                Navigator.pop(context);
                // Ana sayfa veya login'e yönlendir
              }
            },
            child: const Text('Hesabı Sil'),
          ),
        ],
      ),
    );
  }

  void _checkUsernameAvailability(String username, ProfileUpdateProvider provider) async {
    if (username.length >= 3) {
      await provider.checkUsernameAvailability(username);
      // Username availability feedback UI'da otomatik olarak gösteriliyor
    }
  }

  void _verifyPhone(ProfileUpdateProvider provider) {
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      provider.sendPhoneVerificationCode(phone);
      _showPhoneVerificationDialog(context, provider);
    }
  }

  void _showPhoneVerificationDialog(BuildContext context, ProfileUpdateProvider provider) {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Telefon Doğrulama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Telefon numaranıza gönderilen 6 haneli kodu girin'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: codeController,
              labelText: 'Doğrulama Kodu',
              hintText: '6 haneli kod',
              prefixIcon: Icons.sms,
              keyboardType: TextInputType.number,
              validator: provider.validateVerificationCode,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.verifyPhoneCode(codeController.text);
              Navigator.pop(context);
            },
            child: const Text('Doğrula'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileUpdateProvider>().updateProfile(
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim(),
        about: _aboutController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    }
  }
}