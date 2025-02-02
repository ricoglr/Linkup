import '../constant/entities.dart';

class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  // Temsili rozet listesi
  final List<Badge> _badges = [
    Badge(
      id: '1',
      name: 'İnsan Hakları Savunucusu',
      description: '5 insan hakları etkinliğine katıldınız',
      icon: '🏆',
      requiredEvents: 5,
      category: 'İnsan Hakları',
    ),
    Badge(
      id: '2',
      name: 'Eşitlik Öncüsü',
      description: '10 eşitlik temalı etkinliğe katıldınız',
      icon: '⚖️',
      requiredEvents: 10,
      category: 'Eşitlik',
    ),
    Badge(
      id: '3',
      name: 'Barış Elçisi',
      description: 'Barış temalı etkinliklere katıldınız',
      icon: '🕊️',
      requiredEvents: 3,
      category: 'Barış',
    ),
    Badge(
      id: '4',
      name: 'Çocuk Hakları Gönüllüsü',
      description: 'Çocuk hakları etkinliklerine katıldınız',
      icon: '👶',
      requiredEvents: 3,
      category: 'Çocuk Hakları',
    ),
    Badge(
      id: '5',
      name: 'Kadın Hakları Savunucusu',
      description: 'Kadın hakları etkinliklerine katıldınız',
      icon: '👩',
      requiredEvents: 3,
      category: 'Kadın Hakları',
    ),
    Badge(
      id: '6',
      name: 'Engelli Hakları Destekçisi',
      description: 'Engelli hakları etkinliklerine katıldınız',
      icon: '♿',
      requiredEvents: 3,
      category: 'Engelli Hakları',
    ),
  ];

  // Kullanıcının rozetlerini tutan map
  final Map<String, List<Badge>> _userBadges = {};

  // Kullanıcının rozetlerini getir
  List<Badge> getUserBadges(String userId) {
    return _userBadges[userId] ?? [];
  }

  // Yeni rozet ekle
  void addBadge(String userId, Badge badge) {
    _userBadges[userId] = [...(getUserBadges(userId)), badge];
  }

  // Tüm rozetleri getir
  List<Badge> getAllBadges() => List.unmodifiable(_badges);

  // Kullanıcının rozet durumunu kontrol et
  void checkAndAwardBadges(String userId, List<Event> participatedEvents) {
    final categoryCount = <String, int>{};

    // Etkinlik kategorilerine göre sayım yap
    for (var event in participatedEvents) {
      categoryCount[event.category] = (categoryCount[event.category] ?? 0) + 1;
    }

    // Her rozet için kontrol et
    for (var badge in _badges) {
      if ((categoryCount[badge.category] ?? 0) >= badge.requiredEvents) {
        // Kullanıcı bu rozeti henüz almamışsa ekle
        if (!getUserBadges(userId).contains(badge)) {
          addBadge(userId, badge);
        }
      }
    }
  }
}
