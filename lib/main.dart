import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'widgets/notification_widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'widgets/bottom_navbar.dart';

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Background message handler'ı ayarla
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      // Initial message kontrol et (app kapalıyken notification'dan açılmış mı)
      await NotificationHandler.handleInitialMessage();
      
      // Notification provider'ı başlat
      final notificationProvider = context.read<NotificationProvider>();
      await notificationProvider.initialize();
      
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'LINK UP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const BottomNavBar(),
            '/notifications': (context) => const NotificationsScreen(),
            '/notification-settings': (context) => const NotificationSettingsScreen(),
          },
        );
      },
    );
  }
}
