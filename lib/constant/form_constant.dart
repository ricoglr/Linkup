import 'package:flutter/material.dart';

class FormConstants {
  static const formSections = [
    {
      'title': 'Temel Bilgiler',
      'description': 'Etkinlik adını ve türünü belirtin.',
      'icon': Icons.info,
    },
    {
      'title': 'Tarih ve Zaman',
      'description': 'Etkinliğin tarih ve saat bilgilerini girin.',
      'icon': Icons.calendar_today,
    },
    {
      'title': 'Konum',
      'description': 'Etkinlik için bir konum seçin.',
      'icon': Icons.location_on,
    },
    {
      'title': 'Ek Bilgiler',
      'description': 'Etkinlik ile ilgili ek ayrıntıları ekleyin.',
      'icon': Icons.more_horiz,
    },
  ];

  static const eventTypes = [
    'İnsan Hakları',
    'Çocuk Hakları',
    'Kadın Hakları',
    'Çevre Aktivizmi',
    'Eğitim Hakkı',
    'Sağlık Hakkı',
    'Barış ve Adalet',
    'Göçmen Hakları',
    'LGBT+ Hakları',
    'Engelli Hakları',
    'İşçi Hakları',
    'Hayvan Hakları',
    'Konferans',
    'Atölye',
    'Eğitim',
    'Seminer',
    'Protesto',
    'Gösteri',
    'Farkındalık Kampanyası',
    'Bağış Kampanyası',
    'Diğer',
  ];

  // Validation constants
  static const int minEventNameLength = 3;
  static const int maxEventNameLength = 100;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 1000;

  // Phone number validation regex
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';

  // Email validation regex
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
}
