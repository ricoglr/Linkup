import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge.dart';
import '../constant/entities.dart';

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tüm rozetleri getir
  Future<List<Badge>> getAllBadges() async {
    final snapshot = await _firestore.collection('badges').get();
    return snapshot.docs.map((doc) {
      return Badge.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  // Kullanıcının rozetlerini getir
  Future<List<Badge>> getUserBadges(String userId) async {
    try {
      final userBadgesSnapshot = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .get();

      if (userBadgesSnapshot.docs.isEmpty) {
        return [];
      }

      List<Badge> userBadges = [];
      
      for (var doc in userBadgesSnapshot.docs) {
        final data = doc.data();
        final badgeId = data['badgeId'];
        
        // Badge detaylarını al
        final badgeDoc = await _firestore.collection('badges').doc(badgeId).get();
        if (badgeDoc.exists) {
          userBadges.add(Badge.fromFirestore(badgeDoc.data()!, badgeDoc.id));
        }
      }

      return userBadges;
    } catch (e) {
      print('Error getting user badges: $e');
      return [];
    }
  }

  // Kullanıcıya rozet ver
  Future<void> awardBadge(String userId, String badgeId) async {
    try {
      // Önce kullanıcının bu rozeti zaten alıp almadığını kontrol et
      final existingBadge = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .where('badgeId', isEqualTo: badgeId)
          .get();

      if (existingBadge.docs.isEmpty) {
        await _firestore.collection('user_badges').add({
          'userId': userId,
          'badgeId': badgeId,
          'awardedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error awarding badge: $e');
    }
  }

  // Kullanıcının etkinlik katılımına göre rozet kontrol et ve ver
  Future<void> checkAndAwardBadges(String userId, List<Event> participatedEvents) async {
    try {
      final allBadges = await getAllBadges();
      final userBadges = await getUserBadges(userId);
      final userBadgeIds = userBadges.map((b) => b.id).toList();

      final categoryCount = <String, int>{};

      // Etkinlik kategorilerine göre sayım yap
      for (var event in participatedEvents) {
        categoryCount[event.category] = (categoryCount[event.category] ?? 0) + 1;
      }

      // Her rozet için kontrol et
      for (var badge in allBadges) {
        if (!userBadgeIds.contains(badge.id)) {
          // Bu rozetin koşullarını kontrol et
          if (_shouldAwardBadge(badge, categoryCount, participatedEvents)) {
            await awardBadge(userId, badge.id);
          }
        }
      }
    } catch (e) {
      print('Error checking badges: $e');
    }
  }

  // Rozet verilmesi gerekip gerekmediğini kontrol et
  bool _shouldAwardBadge(Badge badge, Map<String, int> categoryCount, List<Event> events) {
    // Badge name'e göre koşulları kontrol et
    switch (badge.name) {
      case 'İlk Adım':
        return events.length >= 1;
      case 'Düzenli Katılımcı':
        return events.length >= 5;
      case 'Etkinlik Ustası':
        return events.length >= 10;
      case 'Kategorik Uzman':
        // Herhangi bir kategoride 3 veya daha fazla etkinliğe katıldıysa
        return categoryCount.values.any((count) => count >= 3);
      case 'Sosyal Aktivist':
        return events.length >= 15;
      default:
        return false;
    }
  }

  // Varsayılan rozetleri Firestore'a ekle (sadece ilk kurulumda)
  Future<void> initializeDefaultBadges() async {
    try {
      final existingBadges = await _firestore.collection('badges').get();
      
      if (existingBadges.docs.isEmpty) {
        final defaultBadges = [
          {
            'name': 'İlk Adım',
            'description': 'İlk etkinliğine katıldın!',
            'icon': 'star',
            'requirement': 1,
            'color': 0xFF4CAF50,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Düzenli Katılımcı',
            'description': '5 etkinliğe katıldın!',
            'icon': 'favorite',
            'requirement': 5,
            'color': 0xFF2196F3,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Etkinlik Ustası',
            'description': '10 etkinliğe katıldın!',
            'icon': 'emoji_events',
            'requirement': 10,
            'color': 0xFFFF9800,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Kategorik Uzman',
            'description': 'Aynı kategoride 3 etkinliğe katıldın!',
            'icon': 'category',
            'requirement': 3,
            'color': 0xFF9C27B0,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Sosyal Aktivist',
            'description': '15 etkinliğe katıldın!',
            'icon': 'groups',
            'requirement': 15,
            'color': 0xFFF44336,
            'createdAt': FieldValue.serverTimestamp(),
          },
        ];

        for (var badgeData in defaultBadges) {
          await _firestore.collection('badges').add(badgeData);
        }
      }
    } catch (e) {
      print('Error initializing badges: $e');
    }
  }
}