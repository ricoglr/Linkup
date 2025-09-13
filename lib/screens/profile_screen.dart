import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_update_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/user_stats_provider.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/badge_display.dart';
import '../widgets/user_stats_display.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Null ise current user

  const ProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  void _loadUserData() {
    try {
      final profileProvider = context.read<ProfileUpdateProvider>();
      final badgeProvider = context.read<BadgeProvider>();
      final statsProvider = context.read<UserStatsProvider>();

      if (widget.userId != null) {
        // Başka kullanıcının profilini yükle
        badgeProvider.loadUserBadges(widget.userId!);
        statsProvider.loadUserStats(widget.userId!);
      } else {
        // Mevcut kullanıcının profilini yükle
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          badgeProvider.loadUserBadges(currentUserId);
          statsProvider.loadUserStats(currentUserId);
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  bool get _isCurrentUser => widget.userId == null || 
      widget.userId == FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCurrentUser ? 'Profilim' : 'Profil'),
        actions: [
          if (_isCurrentUser)
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen(),
                ),
              ),
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: Consumer3<ProfileUpdateProvider, BadgeProvider, UserStatsProvider>(
        builder: (context, profileProvider, badgeProvider, statsProvider, child) {
          final user = FirebaseAuth.instance.currentUser;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profil Başlığı
                _buildProfileHeader(context, user),
                
                const SizedBox(height: 24),
                
                // İstatistikler
                _buildStatsSection(context, statsProvider),
                
                const SizedBox(height: 24),
                
                // Rozetler
                _buildBadgesSection(context, badgeProvider),
                
                const SizedBox(height: 24),
                
                // Kişisel Bilgiler
                _buildPersonalInfoSection(context, user),
                
                const SizedBox(height: 24),
                
                // Güvenlik Bilgileri (sadece current user için)
                if (_isCurrentUser) _buildSecurityInfoSection(context, user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ProfilePhotoWidget(
              photoUrl: user?.photoURL,
              onTap: _isCurrentUser ? () => _navigateToEdit() : () {},
              radius: 50,
              showEditIcon: _isCurrentUser,
            ),
            const SizedBox(height: 16),
            
            Text(
              user?.displayName ?? 'İsimsiz Kullanıcı',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Katılım',
                  value: _formatJoinDate(user?.metadata.creationTime),
                ),
                _buildInfoItem(
                  icon: Icons.email,
                  label: 'Email',
                  value: user?.emailVerified == true ? 'Doğrulandı' : 'Doğrulanmadı',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, UserStatsProvider statsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'İstatistikler',
          icon: Icons.bar_chart,
        ),
        
        if (statsProvider.userStats != null)
          UserStatsDisplay(
            userId: widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
          )
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('İstatistik verisi bulunamadı.'),
            ),
          ),
      ],
    );
  }

  Widget _buildBadgesSection(BuildContext context, BadgeProvider badgeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Rozetler',
          icon: Icons.stars,
        ),
        
        if (badgeProvider.userBadges.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: badgeProvider.userBadges.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: BadgeDisplay(
                    userId: widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
                  ),
                );
              },
            ),
          )
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('Henüz rozet kazanılmamış.'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context, User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Kişisel Bilgiler',
          icon: Icons.person,
        ),
        
        ProfileField(
          label: 'Email',
          value: user?.email ?? '',
          icon: Icons.email,
          isVerified: user?.emailVerified ?? false,
          onTap: _isCurrentUser ? () => _navigateToEdit() : null,
        ),
        
        const SizedBox(height: 8),
        
        ProfileField(
          label: 'Telefon',
          value: '', // TODO: Firestore'dan alınacak
          icon: Icons.phone,
          isVerified: false,
          onTap: _isCurrentUser ? () => _navigateToEdit() : null,
        ),
      ],
    );
  }

  Widget _buildSecurityInfoSection(BuildContext context, User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Güvenlik',
          icon: Icons.security,
        ),
        
        ProfileInfoCard(
          title: 'Son Giriş',
          subtitle: _formatLastSignIn(user?.metadata.lastSignInTime),
          icon: Icons.login,
        ),
        
        const SizedBox(height: 8),
        
        ProfileInfoCard(
          title: 'Hesap Güvenliği',
          subtitle: 'Şifre ve doğrulama ayarları',
          icon: Icons.shield,
          onTap: () => _navigateToEdit(),
        ),
      ],
    );
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return 'Bilinmiyor';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} yıl önce';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ay önce';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else {
      return 'Bugün';
    }
  }

  String _formatLastSignIn(DateTime? date) {
    if (date == null) return 'Bilinmiyor';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileEditScreen(),
      ),
    ).then((_) {
      // Profil düzenleme ekranından döndükten sonra verileri yenile
      _loadUserData();
    });
  }
}
