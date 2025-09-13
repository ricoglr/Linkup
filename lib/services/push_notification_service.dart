import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Push notification türleri
enum NotificationType {
  newMessage('new_message', 'Yeni Mesaj', Icons.message),
  eventInvitation('event_invitation', 'Etkinlik Davetiyesi', Icons.event),
  badgeEarned('badge_earned', 'Rozet Kazandınız', Icons.stars),
  friendRequest('friend_request', 'Arkadaşlık İsteği', Icons.person_add),
  eventUpdate('event_update', 'Etkinlik Güncelleme', Icons.update),
  systemAnnouncement('system_announcement', 'Sistem Duyurusu', Icons.announcement);

  const NotificationType(this.value, this.displayName, this.icon);
  
  final String value;
  final String displayName;
  final IconData icon;
  
  static NotificationType? fromValue(String value) {
    for (NotificationType type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Notification model
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? actionUrl;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.actionUrl,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.fromValue(map['type']) ?? NotificationType.systemAnnouncement,
      data: map['data'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.value,
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    String? actionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}

/// Push notification servis sınıfı
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  bool _isInitialized = false;

  /// Servisi başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // İzin iste
      await _requestPermission();
      
      // Local notifications başlat
      await _initializeLocalNotifications();
      
      // FCM token al
      await _getFCMToken();
      
      // Message handler'ları ayarla
      _setupMessageHandlers();
      
      _isInitialized = true;
      debugPrint('🔔 Push Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Push Notification Service initialization failed: $e');
      rethrow;
    }
  }

  /// Bildirim izni iste
  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('🔔 Notification permission status: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Local notifications başlat
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android notification channel oluştur
    const androidChannel = AndroidNotificationChannel(
      'linkup_high_importance',
      'Linkup Notifications',
      description: 'Linkup uygulaması bildirimleri',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// FCM token al ve kaydet
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('🔔 FCM Token: $_fcmToken');
      
      if (_fcmToken != null && _auth.currentUser != null) {
        await _saveFCMTokenToFirestore(_fcmToken!);
      }
      
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// FCM token'ı Firestore'a kaydet
  Future<void> _saveFCMTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('🔔 FCM token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Message handler'ları ayarla
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // App açıldığında notification'dan gelen mesaj
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Token yenilendiğinde
    _messaging.onTokenRefresh.listen((token) async {
      _fcmToken = token;
      await _saveFCMTokenToFirestore(token);
    });
  }

  /// Foreground message handler
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Foreground message received: ${message.messageId}');
    
    // Local notification göster
    await _showLocalNotification(message);
    
    // Firestore'a kaydet
    await _saveNotificationToFirestore(message);
  }

  /// Background message handler
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Background message received: ${message.messageId}');
    // Background'da otomatik olarak notification gösterilir
  }

  /// App açıldığında notification'dan gelen mesaj
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('🔔 App opened from notification: ${message.messageId}');
    
    // Navigation veya action handling burada yapılabilir
    _handleNotificationAction(message);
  }

  /// Local notification göster
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'linkup_high_importance',
      'Linkup Notifications',
      channelDescription: 'Linkup uygulaması bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Linkup',
      message.notification?.body ?? 'Yeni bildirim',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Notification'ı Firestore'a kaydet
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final notificationType = NotificationType.fromValue(
        message.data['type'] ?? 'system_announcement'
      ) ?? NotificationType.systemAnnouncement;

      final notification = AppNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Linkup',
        body: message.notification?.body ?? 'Yeni bildirim',
        type: notificationType,
        data: message.data,
        timestamp: DateTime.now(),
        imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
        actionUrl: message.data['actionUrl'],
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      debugPrint('🔔 Notification saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving notification: $e');
    }
  }

  /// Notification tıklandığında
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // Navigation veya action handling
  }

  /// Notification action handling
  void _handleNotificationAction(RemoteMessage message) {
    final actionUrl = message.data['actionUrl'];
    final type = message.data['type'];
    
    debugPrint('🔔 Handling notification action - Type: $type, URL: $actionUrl');
    
    // Router ile navigation yapılabilir
    // Get.toNamed(actionUrl);
  }

  /// Test notification gönder
  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      debugPrint('❌ Service not initialized');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'linkup_high_importance',
      'Linkup Notifications',
      channelDescription: 'Test notification',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Test Notification',
      'Bu bir test bildirimidir.',
      notificationDetails,
    );
  }

  /// Kullanıcının bildirimlerini getir
  Stream<List<AppNotification>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotification.fromMap(doc.data());
      }).toList();
    });
  }

  /// Bildirimi okundu olarak işaretle
  Future<void> markNotificationAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllNotificationsAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  /// Okunmamış bildirim sayısını getir
  Stream<int> getUnreadNotificationCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// FCM Token'ı getir
  String? get fcmToken => _fcmToken;

  /// Service başlatıldı mı kontrol et
  bool get isInitialized => _isInitialized;

  /// Service'i temizle
  Future<void> dispose() async {
    _isInitialized = false;
    _fcmToken = null;
  }
}