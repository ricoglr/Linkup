import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/notification_provider.dart';
import '../services/push_notification_service.dart';

/// Notification handler - specific action handling için
class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  /// App açıldığında notification'dan gelen initial message kontrol et
  static Future<void> handleInitialMessage() async {
    try {
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 App opened from notification: ${initialMessage.messageId}');
        await _handleNotificationAction(initialMessage);
      }
    } catch (e) {
      debugPrint('❌ Error handling initial message: $e');
    }
  }

  /// Notification action handling
  static Future<void> _handleNotificationAction(RemoteMessage message) async {
    final type = message.data['type'];
    final actionUrl = message.data['actionUrl'];
    final data = message.data;

    debugPrint('🔔 Handling notification action - Type: $type');

    switch (type) {
      case 'new_message':
        await _handleNewMessageAction(data);
        break;
      case 'event_invitation':
        await _handleEventInvitationAction(data);
        break;
      case 'badge_earned':
        await _handleBadgeEarnedAction(data);
        break;
      case 'friend_request':
        await _handleFriendRequestAction(data);
        break;
      case 'event_update':
        await _handleEventUpdateAction(data);
        break;
      case 'system_announcement':
        await _handleSystemAnnouncementAction(data);
        break;
      default:
        debugPrint('🔔 Unknown notification type: $type');
    }

    // General URL navigation
    if (actionUrl != null && actionUrl.isNotEmpty) {
      // Router ile navigation yapılabilir
      debugPrint('🔔 Would navigate to: $actionUrl');
      // Get.toNamed(actionUrl);
    }
  }

  /// Yeni mesaj notification action
  static Future<void> _handleNewMessageAction(Map<String, dynamic> data) async {
    final chatId = data['chatId'];
    final senderId = data['senderId'];
    
    debugPrint('🔔 New message from $senderId in chat $chatId');
    
    // Chat sayfasına git
    // Get.toNamed('/chat', arguments: {'chatId': chatId, 'senderId': senderId});
  }

  /// Etkinlik davetiyesi notification action
  static Future<void> _handleEventInvitationAction(Map<String, dynamic> data) async {
    final eventId = data['eventId'];
    final inviterId = data['inviterId'];
    
    debugPrint('🔔 Event invitation for event $eventId from $inviterId');
    
    // Etkinlik detay sayfasına git
    // Get.toNamed('/event-detail', arguments: {'eventId': eventId});
  }

  /// Rozet kazanma notification action
  static Future<void> _handleBadgeEarnedAction(Map<String, dynamic> data) async {
    final badgeId = data['badgeId'];
    final badgeName = data['badgeName'];
    
    debugPrint('🔔 Badge earned: $badgeName ($badgeId)');
    
    // Badge detay veya profil sayfasına git
    // Get.toNamed('/profile', arguments: {'showBadge': badgeId});
  }

  /// Arkadaşlık isteği notification action
  static Future<void> _handleFriendRequestAction(Map<String, dynamic> data) async {
    final requesterId = data['requesterId'];
    final requesterName = data['requesterName'];
    
    debugPrint('🔔 Friend request from $requesterName ($requesterId)');
    
    // Arkadaşlık istekleri sayfasına git
    // Get.toNamed('/friend-requests');
  }

  /// Etkinlik güncelleme notification action
  static Future<void> _handleEventUpdateAction(Map<String, dynamic> data) async {
    final eventId = data['eventId'];
    final updateType = data['updateType'];
    
    debugPrint('🔔 Event update: $updateType for event $eventId');
    
    // Etkinlik detay sayfasına git
    // Get.toNamed('/event-detail', arguments: {'eventId': eventId});
  }

  /// Sistem duyurusu notification action
  static Future<void> _handleSystemAnnouncementAction(Map<String, dynamic> data) async {
    final announcementId = data['announcementId'];
    
    debugPrint('🔔 System announcement: $announcementId');
    
    // Duyurular sayfasına git
    // Get.toNamed('/announcements');
  }
}

/// Notification badge widget - unread count gösterir
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final double? badgeSize;
  final Color? badgeColor;
  final TextStyle? textStyle;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeSize = 18,
    this.badgeColor,
    this.textStyle,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final unreadCount = notificationProvider.unreadCount;
        
        if (unreadCount == 0 && !showZero) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                width: badgeSize ?? 18,
                height: badgeSize ?? 18,
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular((badgeSize ?? 18) / 2),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: textStyle ?? const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Notification list item widget
class NotificationListItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;

  const NotificationListItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: notification.isRead ? 1 : 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead 
              ? theme.colorScheme.surfaceVariant 
              : theme.colorScheme.primary,
          child: Icon(
            notification.type.icon,
            color: notification.isRead 
                ? theme.colorScheme.onSurfaceVariant 
                : theme.colorScheme.onPrimary,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            color: notification.isRead 
                ? theme.colorScheme.onSurfaceVariant 
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              style: TextStyle(
                color: notification.isRead 
                    ? theme.colorScheme.onSurfaceVariant 
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? IconButton(
                icon: Icon(
                  Icons.mark_email_read,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                onPressed: onMarkAsRead,
              )
            : null,
        onTap: onTap,
        isThreeLine: true,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
}

/// Notification type settings widget
class NotificationTypeCard extends StatelessWidget {
  final NotificationType type;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const NotificationTypeCard({
    super.key,
    required this.type,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: SwitchListTile(
        secondary: Icon(
          type.icon,
          color: isEnabled ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        title: Text(
          type.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isEnabled ? theme.colorScheme.onSurface : theme.colorScheme.outline,
          ),
        ),
        subtitle: Text(
          _getTypeDescription(type),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        value: isEnabled,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  String _getTypeDescription(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return 'Yeni mesaj aldığınızda bildirim alın';
      case NotificationType.eventInvitation:
        return 'Etkinlik davetiyesi aldığınızda bildirim alın';
      case NotificationType.badgeEarned:
        return 'Yeni rozet kazandığınızda bildirim alın';
      case NotificationType.friendRequest:
        return 'Arkadaşlık isteği aldığınızda bildirim alın';
      case NotificationType.eventUpdate:
        return 'Katıldığınız etkinliklerde güncelleme olduğunda bildirim alın';
      case NotificationType.systemAnnouncement:
        return 'Sistem duyuruları ve önemli güncellemeler';
    }
  }
}

/// Permission request dialog
class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback onRequestPermission;
  final VoidCallback onSkip;

  const NotificationPermissionDialog({
    super.key,
    required this.onRequestPermission,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.notifications_active, size: 48),
      title: const Text('Bildirim İzni'),
      content: const Text(
        'Linkup uygulamasından bildirim alabilmek için izin vermeniz gerekiyor. '
        'Bu sayede yeni mesajlar, etkinlik davetleri ve önemli güncellemelerden haberdar olabilirsiniz.',
      ),
      actions: [
        TextButton(
          onPressed: onSkip,
          child: const Text('Şimdi Değil'),
        ),
        FilledButton(
          onPressed: onRequestPermission,
          child: const Text('İzin Ver'),
        ),
      ],
    );
  }
}

/// Empty notifications widget
class EmptyNotificationsWidget extends StatelessWidget {
  const EmptyNotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz bildirim yok',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bildirimler burada görünecek',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}