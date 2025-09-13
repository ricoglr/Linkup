import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../services/push_notification_service.dart';
import '../widgets/notification_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
        title: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            return Row(
              children: [
                const Text('Bildirimler'),
                if (provider.unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      provider.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'mark_all_read':
                      await provider.markAllAsRead();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tüm bildirimler okundu olarak işaretlendi'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      break;
                    case 'settings':
                      Navigator.of(context).pushNamed('/notification-settings');
                      break;
                    case 'refresh':
                      await provider.refreshNotifications();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (provider.unreadCount > 0)
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: ListTile(
                        leading: Icon(Icons.mark_email_read),
                        title: Text('Tümünü Okundu İşaretle'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Bildirim Ayarları'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Yenile'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Bildirimler yükleniyor...'),
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
                    'Bildirimler yüklenemedi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      provider.clearError();
                      provider.initialize();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (!provider.hasPermission) {
            return _buildPermissionRequired(context, provider);
          }

          if (provider.notifications.isEmpty) {
            return const EmptyNotificationsWidget();
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshNotifications(),
            child: Column(
              children: [
                // Filter chips
                _buildFilterChips(context, provider),
                
                // Notifications list
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = provider.notifications[index];
                      return NotificationListItem(
                        notification: notification,
                        onTap: () => _handleNotificationTap(context, notification, provider),
                        onMarkAsRead: () => provider.markAsRead(notification.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (!provider.hasPermission || provider.notifications.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: () => provider.sendTestNotification(),
            tooltip: 'Test Bildirimi Gönder',
            child: const Icon(Icons.notification_add),
          );
        },
      ),
    );
  }

  Widget _buildPermissionRequired(BuildContext context, NotificationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              'Bildirim İzni Gerekli',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Bildirimleri görebilmek için önce bildirim izni vermeniz gerekiyor. '
              'Bu sayede yeni mesajlar, etkinlik davetleri ve önemli güncellemelerden haberdar olabilirsiniz.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final granted = await provider.requestPermission();
                  if (!granted && context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => NotificationPermissionDialog(
                        onRequestPermission: () {
                          Navigator.of(context).pop();
                          provider.requestPermission();
                        },
                        onSkip: () => Navigator.of(context).pop(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notifications),
                label: const Text('İzin Ver'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/notification-settings'),
              child: const Text('Bildirim Ayarları'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, NotificationProvider provider) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('Tümü'),
            selected: true, // TODO: Implement filter logic
            onSelected: (selected) {
              // TODO: Implement filter functionality
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Okunmamış'),
            selected: false,
            onSelected: (selected) {
              // TODO: Implement filter functionality
            },
          ),
          const SizedBox(width: 8),
          ...NotificationType.values.map((type) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(type.icon, size: 16),
              label: Text(type.displayName),
              selected: false,
              onSelected: (selected) {
                // TODO: Implement filter functionality
              },
            ),
          )),
        ],
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification, NotificationProvider provider) {
    // Mark as read if not already read
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // Handle notification action based on type
    _handleNotificationAction(context, notification);
  }

  void _handleNotificationAction(BuildContext context, AppNotification notification) {
    // Show notification detail dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(notification.type.icon),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
            if (notification.data != null && notification.data!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Ek Bilgiler:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...notification.data!.entries.map(
                (entry) => Text('${entry.key}: ${entry.value}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          if (notification.actionUrl != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to action URL
                debugPrint('Navigate to: ${notification.actionUrl}');
              },
              child: const Text('Git'),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }
}