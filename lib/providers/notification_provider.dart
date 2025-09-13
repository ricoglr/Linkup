import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/push_notification_service.dart';

/// Bildirim ayarları modeli
class NotificationSettings {
  final bool enabled;
  final bool newMessage;
  final bool eventInvitation;
  final bool badgeEarned;
  final bool friendRequest;
  final bool eventUpdate;
  final bool systemAnnouncement;
  final bool sound;
  final bool vibration;
  final bool badge;

  NotificationSettings({
    this.enabled = true,
    this.newMessage = true,
    this.eventInvitation = true,
    this.badgeEarned = true,
    this.friendRequest = true,
    this.eventUpdate = true,
    this.systemAnnouncement = true,
    this.sound = true,
    this.vibration = true,
    this.badge = true,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      enabled: map['enabled'] ?? true,
      newMessage: map['newMessage'] ?? true,
      eventInvitation: map['eventInvitation'] ?? true,
      badgeEarned: map['badgeEarned'] ?? true,
      friendRequest: map['friendRequest'] ?? true,
      eventUpdate: map['eventUpdate'] ?? true,
      systemAnnouncement: map['systemAnnouncement'] ?? true,
      sound: map['sound'] ?? true,
      vibration: map['vibration'] ?? true,
      badge: map['badge'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'newMessage': newMessage,
      'eventInvitation': eventInvitation,
      'badgeEarned': badgeEarned,
      'friendRequest': friendRequest,
      'eventUpdate': eventUpdate,
      'systemAnnouncement': systemAnnouncement,
      'sound': sound,
      'vibration': vibration,
      'badge': badge,
    };
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? newMessage,
    bool? eventInvitation,
    bool? badgeEarned,
    bool? friendRequest,
    bool? eventUpdate,
    bool? systemAnnouncement,
    bool? sound,
    bool? vibration,
    bool? badge,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      newMessage: newMessage ?? this.newMessage,
      eventInvitation: eventInvitation ?? this.eventInvitation,
      badgeEarned: badgeEarned ?? this.badgeEarned,
      friendRequest: friendRequest ?? this.friendRequest,
      eventUpdate: eventUpdate ?? this.eventUpdate,
      systemAnnouncement: systemAnnouncement ?? this.systemAnnouncement,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      badge: badge ?? this.badge,
    );
  }

  /// Belirli bir bildirim türü için ayarı kontrol et
  bool isTypeEnabled(NotificationType type) {
    if (!enabled) return false;
    
    switch (type) {
      case NotificationType.newMessage:
        return newMessage;
      case NotificationType.eventInvitation:
        return eventInvitation;
      case NotificationType.badgeEarned:
        return badgeEarned;
      case NotificationType.friendRequest:
        return friendRequest;
      case NotificationType.eventUpdate:
        return eventUpdate;
      case NotificationType.systemAnnouncement:
        return systemAnnouncement;
    }
  }
}

/// Push notification state management provider
class NotificationProvider extends ChangeNotifier {
  final PushNotificationService _notificationService = PushNotificationService();
  
  // State variables
  bool _isInitialized = false;
  bool _hasPermission = false;
  String? _fcmToken;
  NotificationSettings _settings = NotificationSettings();
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;
  String? get fcmToken => _fcmToken;
  NotificationSettings get settings => _settings;
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Provider'ı başlat
  Future<void> initialize() async {
    _setLoading(true);
    _setError(null);

    try {
      debugPrint('🔔 Initializing NotificationProvider...');
      
      // Notification service'i başlat
      await _notificationService.initialize();
      
      // Permission durumunu kontrol et
      await _checkPermissionStatus();
      
      // FCM token al
      _fcmToken = _notificationService.fcmToken;
      
      // Ayarları yükle
      await _loadSettings();
      
      // Bildirimleri dinlemeye başla
      _setupNotificationListeners();
      
      _isInitialized = true;
      debugPrint('✅ NotificationProvider initialized successfully');
      
    } catch (e) {
      _setError('Bildirim servisi başlatılamadı: $e');
      debugPrint('❌ NotificationProvider initialization failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Permission durumunu kontrol et
  Future<void> _checkPermissionStatus() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      _hasPermission = settings.authorizationStatus == AuthorizationStatus.authorized ||
                      settings.authorizationStatus == AuthorizationStatus.provisional;
      
      debugPrint('🔔 Permission status: $_hasPermission');
    } catch (e) {
      debugPrint('❌ Error checking permission status: $e');
      _hasPermission = false;
    }
  }

  /// Notification permission iste
  Future<bool> requestPermission() async {
    try {
      _setLoading(true);
      
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _hasPermission = settings.authorizationStatus == AuthorizationStatus.authorized ||
                      settings.authorizationStatus == AuthorizationStatus.provisional;

      if (_hasPermission) {
        // Service'i yeniden başlat
        await _notificationService.initialize();
        _fcmToken = _notificationService.fcmToken;
      }

      notifyListeners();
      return _hasPermission;
      
    } catch (e) {
      _setError('Permission isteği başarısız: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Ayarları SharedPreferences'tan yükle
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('notification_settings');
      
      if (settingsJson != null) {
        // JSON parse etme logic'i burada olacak
        // Şimdilik default settings kullan
        _settings = NotificationSettings();
      } else {
        _settings = NotificationSettings();
      }
      
      debugPrint('🔔 Notification settings loaded');
    } catch (e) {
      debugPrint('❌ Error loading settings: $e');
      _settings = NotificationSettings();
    }
  }

  /// Ayarları kaydet
  Future<void> saveSettings(NotificationSettings newSettings) async {
    try {
      _setLoading(true);
      
      final prefs = await SharedPreferences.getInstance();
      // JSON encode etme logic'i burada olacak
      await prefs.setString('notification_settings', newSettings.toMap().toString());
      
      _settings = newSettings;
      
      debugPrint('🔔 Notification settings saved');
      notifyListeners();
      
    } catch (e) {
      _setError('Ayarlar kaydedilemedi: $e');
      debugPrint('❌ Error saving settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Belirli bir bildirim türünü aç/kapat
  Future<void> toggleNotificationType(NotificationType type, bool enabled) async {
    NotificationSettings newSettings;
    
    switch (type) {
      case NotificationType.newMessage:
        newSettings = _settings.copyWith(newMessage: enabled);
        break;
      case NotificationType.eventInvitation:
        newSettings = _settings.copyWith(eventInvitation: enabled);
        break;
      case NotificationType.badgeEarned:
        newSettings = _settings.copyWith(badgeEarned: enabled);
        break;
      case NotificationType.friendRequest:
        newSettings = _settings.copyWith(friendRequest: enabled);
        break;
      case NotificationType.eventUpdate:
        newSettings = _settings.copyWith(eventUpdate: enabled);
        break;
      case NotificationType.systemAnnouncement:
        newSettings = _settings.copyWith(systemAnnouncement: enabled);
        break;
    }
    
    await saveSettings(newSettings);
  }

  /// Tüm bildirimleri aç/kapat
  Future<void> toggleAllNotifications(bool enabled) async {
    final newSettings = _settings.copyWith(enabled: enabled);
    await saveSettings(newSettings);
  }

  /// Ses ayarını değiştir
  Future<void> toggleSound(bool enabled) async {
    final newSettings = _settings.copyWith(sound: enabled);
    await saveSettings(newSettings);
  }

  /// Titreşim ayarını değiştir
  Future<void> toggleVibration(bool enabled) async {
    final newSettings = _settings.copyWith(vibration: enabled);
    await saveSettings(newSettings);
  }

  /// Badge ayarını değiştir
  Future<void> toggleBadge(bool enabled) async {
    final newSettings = _settings.copyWith(badge: enabled);
    await saveSettings(newSettings);
  }

  /// Notification listener'ları ayarla
  void _setupNotificationListeners() {
    // Kullanıcının bildirimlerini dinle
    _notificationService.getUserNotifications().listen(
      (notifications) {
        _notifications = notifications;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Error listening to notifications: $error');
        _setError('Bildirimler yüklenemedi: $error');
      },
    );

    // Okunmamış bildirim sayısını dinle
    _notificationService.getUnreadNotificationCount().listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Error listening to unread count: $error');
      },
    );
  }

  /// Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      
      // Local state'i güncelle
      final notificationIndex = _notifications.indexWhere((n) => n.id == notificationId);
      if (notificationIndex != -1) {
        _notifications[notificationIndex] = _notifications[notificationIndex].copyWith(isRead: true);
        notifyListeners();
      }
      
    } catch (e) {
      _setError('Bildirim güncellenemedi: $e');
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead() async {
    try {
      _setLoading(true);
      await _notificationService.markAllNotificationsAsRead();
      
      // Local state'i güncelle
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      
      debugPrint('🔔 All notifications marked as read');
      
    } catch (e) {
      _setError('Bildirimler güncellenemedi: $e');
      debugPrint('❌ Error marking all notifications as read: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Test bildirimi gönder
  Future<void> sendTestNotification() async {
    try {
      await _notificationService.sendTestNotification();
      debugPrint('🔔 Test notification sent');
    } catch (e) {
      _setError('Test bildirimi gönderilemedi: $e');
      debugPrint('❌ Error sending test notification: $e');
    }
  }

  /// Bildirimleri yenile
  Future<void> refreshNotifications() async {
    try {
      _setLoading(true);
      // Listener zaten aktif olduğu için manual refresh gerekmez
      // Sadım loading durumunu göster
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      _setLoading(false);
    }
  }

  /// Loading durumunu ayarla
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Error durumunu ayarla
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  /// Error'ı temizle
  void clearError() {
    _setError(null);
  }

  /// Provider'ı temizle
  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}