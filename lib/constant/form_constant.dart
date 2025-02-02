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
    'Konferans',
    'Atölye',
    'Eğitim',
    'Seminer',
    'Diğer',
  ];
}
