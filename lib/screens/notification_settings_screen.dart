import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../services/push_notification_service.dart';
import '../widgets/notification_widgets.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      if (!provider.isInitialized) {
        provider.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => _showHelpDialog(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !provider.isInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Bildirim ayarları yükleniyor...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Hata: ${provider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.initialize();
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.initialize(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Permission Status Card
                _buildPermissionCard(context, provider),
                const SizedBox(height: 16),

                // Master Switch
                _buildMasterSwitchCard(context, provider),
                const SizedBox(height: 16),

                // Notification Types
                if (provider.hasPermission && provider.settings.enabled) ...[
                  _buildSectionHeader('Bildirim Türleri'),
                  const SizedBox(height: 8),
                  ...NotificationType.values.map((type) => 
                    _buildNotificationTypeCard(context, provider, type)
                  ),
                  const SizedBox(height: 16),

                  // Sound & Vibration Settings
                  _buildSectionHeader('Ses ve Titreşim'),
                  const SizedBox(height: 8),
                  _buildSoundVibrationCard(context, provider),
                  const SizedBox(height: 16),
                ],

                // Test Section
                if (provider.hasPermission) ...[
                  _buildSectionHeader('Test'),
                  const SizedBox(height: 8),
                  _buildTestCard(context, provider),
                  const SizedBox(height: 16),
                ],

                // Token Info (Debug)
                if (provider.fcmToken != null) ...[
                  _buildSectionHeader('Geliştirici Bilgileri'),
                  const SizedBox(height: 8),
                  _buildTokenCard(context, provider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionCard(BuildContext context, NotificationProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  provider.hasPermission ? Icons.check_circle : Icons.warning,
                  color: provider.hasPermission ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bildirim İzni',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              provider.hasPermission
                  ? 'Bildirim izni verildi. Bildirimler aktif.'
                  : 'Bildirim izni verilmedi. Bildirim alamazsınız.',
              style: theme.textTheme.bodyMedium,
            ),
            if (!provider.hasPermission) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.isLoading ? null : () async {
                    final granted = await provider.requestPermission();
                    if (!granted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bildirim izni reddedildi. Ayarlardan izin verebilirsiniz.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.notifications),
                  label: const Text('İzin Ver'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMasterSwitchCard(BuildContext context, NotificationProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      child: SwitchListTile(
        secondary: Icon(
          Icons.notifications,
          color: provider.settings.enabled && provider.hasPermission
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
        title: const Text(
          'Tüm Bildirimler',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          provider.settings.enabled
              ? 'Bildirimler aktif'
              : 'Tüm bildirimler kapalı',
        ),
        value: provider.settings.enabled,
        onChanged: provider.hasPermission && !provider.isLoading
            ? (value) => provider.toggleAllNotifications(value)
            : null,
      ),
    );
  }

  Widget _buildNotificationTypeCard(BuildContext context, NotificationProvider provider, NotificationType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NotificationTypeCard(
        type: type,
        isEnabled: provider.settings.isTypeEnabled(type),
        onChanged: provider.isLoading
            ? (_) {}
            : (value) => provider.toggleNotificationType(type, value),
      ),
    );
  }

  Widget _buildSoundVibrationCard(BuildContext context, NotificationProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.volume_up),
              title: const Text('Ses'),
              subtitle: const Text('Bildirim geldiğinde ses çıkar'),
              value: provider.settings.sound,
              onChanged: provider.isLoading
                  ? null
                  : provider.toggleSound,
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: const Text('Titreşim'),
              subtitle: const Text('Bildirim geldiğinde telefon titrer'),
              value: provider.settings.vibration,
              onChanged: provider.isLoading
                  ? null
                  : provider.toggleVibration,
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.circle_notifications),
              title: const Text('Badge'),
              subtitle: const Text('Uygulama simgesinde bildirim sayısı göster'),
              value: provider.settings.badge,
              onChanged: provider.isLoading
                  ? null
                  : provider.toggleBadge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, NotificationProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report),
                const SizedBox(width: 8),
                Text(
                  'Test Bildirimi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Bildirim sisteminin çalışıp çalışmadığını test edin.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        await provider.sendTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test bildirimi gönderildi!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.send),
                label: const Text('Test Bildirimi Gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCard(BuildContext context, NotificationProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.token),
                const SizedBox(width: 8),
                Text(
                  'FCM Token',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                provider.fcmToken ?? 'Token bulunamadı',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Clipboard'a kopyala
                      // Clipboard.setData(ClipboardData(text: provider.fcmToken ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Token kopyalandı')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Kopyala'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.initialize(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Yenile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirim Ayarları Yardımı'),
        content: const Text(
          'Bu sayfada bildirim tercihlerinizi yönetebilirsiniz:\n\n'
          '• Tüm bildirimleri açıp kapatabilirsiniz\n'
          '• Hangi türde bildirimler almak istediğinizi seçebilirsiniz\n'
          '• Ses, titreşim ve badge ayarlarını değiştirebilirsiniz\n'
          '• Test bildirimi göndererek sistemi kontrol edebilirsiniz\n\n'
          'Bildirim almak için önce sistem izni vermeniz gerekiyor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}