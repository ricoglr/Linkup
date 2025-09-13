import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_stats.dart';
import '../constant/entities.dart';

class UserStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının istatistiklerini getir
  Future<UserStats?> getUserStats(String userId) async {
    try {
      final doc = await _firestore.collection('user_stats').doc(userId).get();
      
      if (doc.exists) {
        return UserStats.fromFirestore(doc.data()!, doc.id);
      } else {
        // İlk kez istatistik oluştur
        return await _createInitialUserStats(userId);
      }
    } catch (e) {
      print('Error getting user stats: $e');
      return null;
    }
  }

  // Kullanıcının istatistiklerini güncelle
  Future<void> updateUserStats(String userId) async {
    try {
      // Kullanıcının katıldığı etkinlikleri getir
      final participatedEvents = await _getUserParticipatedEvents(userId);
      
      // Kullanıcının organize ettiği etkinlikleri getir
      final organizedEvents = await _getUserOrganizedEvents(userId);
      
      // Kullanıcının rozetlerini getir
      final userBadges = await _getUserBadgeCount(userId);
      
      // Kategori istatistiklerini hesapla
      final categoryStats = _calculateCategoryStats(participatedEvents);
      
      // Aylık istatistikleri hesapla
      final monthlyStats = _calculateMonthlyStats(participatedEvents);
      
      // Streak hesapla
      final streakData = _calculateStreaks(participatedEvents);
      
      // Ortalama rating hesapla
      final averageRating = await _calculateAverageRating(organizedEvents);
      
      // Rank pozisyonu hesapla
      final rankPosition = await _calculateUserRank(userId);

      final userStats = UserStats(
        userId: userId,
        totalEventsParticipated: participatedEvents.length,
        totalEventsOrganized: organizedEvents.length,
        totalBadgesEarned: userBadges,
        currentStreak: streakData['current'] ?? 0,
        longestStreak: streakData['longest'] ?? 0,
        lastEventDate: participatedEvents.isNotEmpty 
            ? participatedEvents.last.date 
            : null,
        categoryStats: categoryStats,
        monthlyStats: monthlyStats,
        rankPosition: rankPosition,
        averageRating: averageRating,
        lastUpdated: DateTime.now(),
      );

      await _firestore.collection('user_stats').doc(userId).set(userStats.toFirestore());
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  // İlk kez kullanıcı istatistiği oluştur
  Future<UserStats> _createInitialUserStats(String userId) async {
    final initialStats = UserStats(
      userId: userId,
      lastUpdated: DateTime.now(),
    );

    await _firestore.collection('user_stats').doc(userId).set(initialStats.toFirestore());
    return initialStats;
  }

  // Kullanıcının katıldığı etkinlikleri getir
  Future<List<Event>> _getUserParticipatedEvents(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('participants', arrayContains: userId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Event.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting participated events: $e');
      return [];
    }
  }

  // Kullanıcının organize ettiği etkinlikleri getir
  Future<List<Event>> _getUserOrganizedEvents(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('organizerId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Event.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting organized events: $e');
      return [];
    }
  }

  // Kullanıcının rozet sayısını getir
  Future<int> _getUserBadgeCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting user badge count: $e');
      return 0;
    }
  }

  // Kategori istatistiklerini hesapla
  Map<String, int> _calculateCategoryStats(List<Event> events) {
    final Map<String, int> categoryStats = {};
    
    for (var event in events) {
      categoryStats[event.category] = (categoryStats[event.category] ?? 0) + 1;
    }
    
    return categoryStats;
  }

  // Aylık istatistikleri hesapla
  Map<String, dynamic> _calculateMonthlyStats(List<Event> events) {
    final Map<String, int> monthlyStats = {};
    
    for (var event in events) {
      final monthKey = '${event.date.year}-${event.date.month.toString().padLeft(2, '0')}';
      monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + 1;
    }
    
    return Map<String, dynamic>.from(monthlyStats);
  }

  // Streak (ardışık katılım) hesapla
  Map<String, int> _calculateStreaks(List<Event> events) {
    if (events.isEmpty) return {'current': 0, 'longest': 0};

    // Etkinlikleri tarihe göre sırala (eskiden yeniye)
    events.sort((a, b) => a.date.compareTo(b.date));
    
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 1;
    
    DateTime? lastEventDate;
    
    for (var event in events) {
      if (lastEventDate != null) {
        final daysDifference = event.date.difference(lastEventDate).inDays;
        
        if (daysDifference <= 7) { // Haftalık streak
          tempStreak++;
        } else {
          longestStreak = longestStreak > tempStreak ? longestStreak : tempStreak;
          tempStreak = 1;
        }
      }
      
      lastEventDate = event.date;
    }
    
    longestStreak = longestStreak > tempStreak ? longestStreak : tempStreak;
    
    // Current streak hesapla (son etkinlikten itibaren)
    if (lastEventDate != null) {
      final daysSinceLastEvent = DateTime.now().difference(lastEventDate).inDays;
      if (daysSinceLastEvent <= 7) {
        currentStreak = tempStreak;
      }
    }
    
    return {'current': currentStreak, 'longest': longestStreak};
  }

  // Ortalama rating hesapla (şimdilik 0 döndürüyor, gelecekte rating sistemi eklenebilir)
  Future<double> _calculateAverageRating(List<Event> organizedEvents) async {
    // TODO: Event rating sistemi eklendiğinde burası implement edilecek
    return 0.0;
  }

  // Kullanıcının rank pozisyonunu hesapla
  Future<int> _calculateUserRank(String userId) async {
    try {
      // Tüm kullanıcıları aktivite puanına göre sırala
      final userStatsSnapshot = await _firestore
          .collection('user_stats')
          .orderBy('totalEventsParticipated', descending: true)
          .get();

      int rank = 1;
      for (var doc in userStatsSnapshot.docs) {
        if (doc.id == userId) {
          return rank;
        }
        rank++;
      }
      
      return rank;
    } catch (e) {
      print('Error calculating user rank: $e');
      return 0;
    }
  }

  // Leaderboard getir (en aktif kullanıcılar)
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_stats')
          .orderBy('totalEventsParticipated', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> leaderboard = [];
      
      for (var doc in querySnapshot.docs) {
        final stats = UserStats.fromFirestore(doc.data(), doc.id);
        
        // Kullanıcı bilgilerini de getir
        final userDoc = await _firestore.collection('users').doc(stats.userId).get();
        final userData = userDoc.data() ?? {};
        
        leaderboard.add({
          'userId': stats.userId,
          'username': userData['username'] ?? 'Kullanıcı',
          'photoURL': userData['photoURL'] ?? '',
          'stats': stats,
          'rank': leaderboard.length + 1,
        });
      }
      
      return leaderboard;
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  // Genel istatistikleri getir (toplam kullanıcı sayısı, etkinlik sayısı vs.)
  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final futures = await Future.wait([
        _firestore.collection('users').count().get(),
        _firestore.collection('events').count().get(),
        _firestore.collection('user_badges').count().get(),
      ]);

      final totalUsers = futures[0].count ?? 0;
      final totalEvents = futures[1].count ?? 0;
      final totalBadgesEarned = futures[2].count ?? 0;

      return {
        'totalUsers': totalUsers,
        'totalEvents': totalEvents,
        'totalBadgesEarned': totalBadgesEarned,
        'averageEventsPerUser': totalUsers > 0 ? (totalEvents / totalUsers).round() : 0,
      };
    } catch (e) {
      print('Error getting global stats: $e');
      return {
        'totalUsers': 0,
        'totalEvents': 0,
        'totalBadgesEarned': 0,
        'averageEventsPerUser': 0,
      };
    }
  }

  // Etkinlik katılımından sonra istatistikleri güncelle
  Future<void> onEventParticipation(String userId, String eventId) async {
    await updateUserStats(userId);
    
    // Badge kontrolü yap
    // Bu işlemi BadgeService ile entegre edebiliriz
  }

  // Etkinlik organize edildiğinde istatistikleri güncelle
  Future<void> onEventOrganized(String userId, String eventId) async {
    await updateUserStats(userId);
  }
}