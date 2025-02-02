import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constant/entities.dart';
import '../services/badge_service.dart';
import '../theme/theme_provider.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final BadgeService _badgeService = BadgeService();
  final AuthService _authService = AuthService();

  // Temsili veriler aynı kalacak
  final Map<String, dynamic> _userData = {
    'name': 'Kullanıcı Adı',
    'email': 'kullanici@email.com',
    'phone': '5XX XXX XX XX',
    'joinedEvents': 12,
    'createdEvents': 5,
  };

  // Temsili geçmiş etkinlikler aynı kalacak
  final List<Event> _pastEvents = [
    Event(
      id: '1',
      title: 'Çocuk Hakları Konferansı',
      description: 'Çocuk hakları üzerine farkındalık konferansı',
      date: DateTime.now().subtract(const Duration(days: 5)),
      time: '14:00',
      location: 'Ankara',
      category: 'Çocuk Hakları',
      imageUrl: '',
      organizerId: 'org1',
      createdAt: DateTime.now(),
      contactPhone: '555-0001',
      organizationInfo: 'UNICEF Türkiye',
    ),
    Event(
      id: '2',
      title: 'Kadın Hakları Paneli',
      description: 'Kadın hakları ve eşitlik paneli',
      date: DateTime.now().subtract(const Duration(days: 10)),
      time: '15:30',
      location: 'İstanbul',
      category: 'Kadın Hakları',
      imageUrl: '',
      organizerId: 'org2',
      createdAt: DateTime.now(),
      contactPhone: '555-0002',
      organizationInfo: 'UN Women',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _userData['name'],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.person,
                  size: 80,
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.24),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatsCard(),
                _buildBadgesSection(),
                _buildProfileSection(),
                _buildPastEventsSection(),
                _buildSettingsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Katıldığı\nEtkinlikler', _userData['joinedEvents']),
            _buildStatItem(
                'Oluşturduğu\nEtkinlikler', _userData['createdEvents']),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection() {
    final badges = _badgeService.getUserBadges("current_user_id");

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.military_tech,
                    size: 24, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Rozetlerim',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  '${badges.length} / ${_badgeService.getAllBadges().length}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          if (badges.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Henüz rozet kazanılmadı.\nEtkinliklere katılarak rozetler kazanabilirsiniz!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: [
                            Text(
                              badge.icon,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                badge.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badge.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kategori: ${badge.category}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Tamam',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .shadow
                                    .withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            badge.icon,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            badge.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Profil Bilgileri',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: Icon(Icons.person,
                color: Theme.of(context).colorScheme.primary),
            title: Text(_userData['name'],
                style: Theme.of(context).textTheme.bodyLarge),
            trailing:
                Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
            onTap: () {
              // TODO: İsim düzenleme
            },
          ),
          ListTile(
            leading:
                Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
            title: Text(_userData['email'],
                style: Theme.of(context).textTheme.bodyLarge),
            trailing:
                Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
            onTap: () {
              // TODO: Email düzenleme
            },
          ),
          ListTile(
            leading:
                Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
            title: Text(_userData['phone'],
                style: Theme.of(context).textTheme.bodyLarge),
            trailing:
                Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
            onTap: () {
              // TODO: Telefon düzenleme
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPastEventsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Katıldığım Etkinlikler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (_pastEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Henüz bir etkinliğe katılmadınız.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pastEvents.length,
              itemBuilder: (context, index) {
                final event = _pastEvents[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      event.category.substring(0, 1),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(event.title,
                      style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text(
                    '${event.date.day}/${event.date.month}/${event.date.year} - ${event.location}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.verified,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Ayarlar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: Icon(Icons.notifications,
                color: Theme.of(context).colorScheme.primary),
            title: Text('Bildirimler',
                style: Theme.of(context).textTheme.bodyLarge),
            trailing: Switch(
              value: true,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) {
                // TODO: Bildirim ayarları
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.dark_mode,
                color: Theme.of(context).colorScheme.primary),
            title: Text('Karanlık Mod',
                style: Theme.of(context).textTheme.bodyLarge),
            trailing: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Switch(
                  value: themeProvider.isDarkMode,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                );
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.language,
                color: Theme.of(context).colorScheme.primary),
            title: Text('Dil', style: Theme.of(context).textTheme.bodyLarge),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.primary),
            onTap: () {
              // TODO: Dil seçimi
            },
          ),
          ListTile(
            leading:
                Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Çıkış Yap',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      'Çıkış Yap',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    content: Text(
                      'Çıkış yapmak üzeresiniz. Çıkmak istediğinize emin misiniz?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'İptal',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Text(
                          'Evet',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary),
                        ),
                      ),
                    ],
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
