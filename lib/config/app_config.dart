class AppConfig {
  // App Information
  static const String appName = 'LinkUp';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Aktivistleri bir araya getiren platform';

  // API Configuration
  static const String apiBaseUrl = 'https://api.linkup.com';
  static const int apiTimeoutSeconds = 30;

  // Firebase Configuration
  static const String firebaseProjectId = 'linkup-app-3d672';

  // Storage Configuration
  static const String imageStorageBucket = 'event-images';
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp'
  ];

  // Pagination
  static const int eventsPerPage = 20;
  static const int usersPerPage = 15;

  // Cache Configuration
  static const int cacheExpirationHours = 24;

  // Feature Flags
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableDarkMode = true;

  // Social Media
  static const String websiteUrl = 'https://linkup.com';
  static const String supportEmail = 'support@linkup.com';
  static const String privacyPolicyUrl = 'https://linkup.com/privacy';
  static const String termsOfServiceUrl = 'https://linkup.com/terms';

  // Event Configuration
  static const int maxEventTitleLength = 100;
  static const int maxEventDescriptionLength = 1000;
  static const int maxParticipants = 10000;

  // Badge Configuration
  static const Map<String, int> badgeRequirements = {
    'Yeni Başlayan': 1,
    'Aktif Katılımcı': 5,
    'Deneyimli Aktivist': 15,
    'Topluluk Lideri': 30,
    'Değişim Elçisi': 50,
  };
}
