import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  final String userId;
  final int totalEventsParticipated;
  final int totalEventsOrganized;
  final int totalBadgesEarned;
  final int currentStreak; // Ardışık etkinlik katılım serisi
  final int longestStreak; // En uzun ardışık katılım serisi
  final DateTime? lastEventDate;
  final Map<String, int> categoryStats; // Kategori bazında katılım sayıları
  final Map<String, dynamic> monthlyStats; // Aylık istatistikler
  final int rankPosition; // Kullanıcının genel sıralaması
  final double averageRating; // Organize ettiği etkinliklerin ortalama puanı
  final DateTime lastUpdated;

  UserStats({
    required this.userId,
    this.totalEventsParticipated = 0,
    this.totalEventsOrganized = 0,
    this.totalBadgesEarned = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastEventDate,
    this.categoryStats = const {},
    this.monthlyStats = const {},
    this.rankPosition = 0,
    this.averageRating = 0.0,
    required this.lastUpdated,
  });

  factory UserStats.fromFirestore(Map<String, dynamic> data, String id) {
    return UserStats(
      userId: id,
      totalEventsParticipated: data['totalEventsParticipated'] ?? 0,
      totalEventsOrganized: data['totalEventsOrganized'] ?? 0,
      totalBadgesEarned: data['totalBadgesEarned'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastEventDate: data['lastEventDate']?.toDate(),
      categoryStats: Map<String, int>.from(data['categoryStats'] ?? {}),
      monthlyStats: Map<String, dynamic>.from(data['monthlyStats'] ?? {}),
      rankPosition: data['rankPosition'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalEventsParticipated': totalEventsParticipated,
      'totalEventsOrganized': totalEventsOrganized,
      'totalBadgesEarned': totalBadgesEarned,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastEventDate': lastEventDate != null ? Timestamp.fromDate(lastEventDate!) : null,
      'categoryStats': categoryStats,
      'monthlyStats': monthlyStats,
      'rankPosition': rankPosition,
      'averageRating': averageRating,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // En sevilen kategoriyi getir
  String get favoriteCategory {
    if (categoryStats.isEmpty) return 'Henüz yok';
    
    String maxCategory = categoryStats.keys.first;
    int maxCount = categoryStats[maxCategory] ?? 0;
    
    for (var entry in categoryStats.entries) {
      if (entry.value > maxCount) {
        maxCategory = entry.key;
        maxCount = entry.value;
      }
    }
    
    return maxCategory;
  }

  // Toplam aktivite puanı (basit bir algoritma)
  int get activityScore {
    return (totalEventsParticipated * 10) + 
           (totalEventsOrganized * 25) + 
           (totalBadgesEarned * 15) + 
           (currentStreak * 5);
  }

  // Bu ay katıldığı etkinlik sayısı
  int get thisMonthEvents {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return monthlyStats[currentMonth] ?? 0;
  }

  // Geçen ay katıldığı etkinlik sayısı
  int get lastMonthEvents {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthKey = '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';
    return monthlyStats[lastMonthKey] ?? 0;
  }

  // Aylık büyüme oranı
  double get monthlyGrowthRate {
    if (lastMonthEvents == 0) return 0.0;
    return ((thisMonthEvents - lastMonthEvents) / lastMonthEvents) * 100;
  }

  // Kullanıcının seviyesi (basit level sistemi)
  int get userLevel {
    return (activityScore / 100).floor() + 1;
  }

  // Bir sonraki seviyeye kadar gereken puan
  int get pointsToNextLevel {
    final nextLevelScore = userLevel * 100;
    return nextLevelScore - activityScore;
  }

  // Kullanıcının başarı yüzdesi
  double get achievementPercentage {
    final maxPossibleScore = 1000; // Maksimum hedef puan
    return (activityScore / maxPossibleScore * 100).clamp(0, 100);
  }

  UserStats copyWith({
    String? userId,
    int? totalEventsParticipated,
    int? totalEventsOrganized,
    int? totalBadgesEarned,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastEventDate,
    Map<String, int>? categoryStats,
    Map<String, dynamic>? monthlyStats,
    int? rankPosition,
    double? averageRating,
    DateTime? lastUpdated,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      totalEventsParticipated: totalEventsParticipated ?? this.totalEventsParticipated,
      totalEventsOrganized: totalEventsOrganized ?? this.totalEventsOrganized,
      totalBadgesEarned: totalBadgesEarned ?? this.totalBadgesEarned,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastEventDate: lastEventDate ?? this.lastEventDate,
      categoryStats: categoryStats ?? this.categoryStats,
      monthlyStats: monthlyStats ?? this.monthlyStats,
      rankPosition: rankPosition ?? this.rankPosition,
      averageRating: averageRating ?? this.averageRating,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}