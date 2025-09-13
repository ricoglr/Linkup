import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_stats.dart';
import '../services/user_stats_service.dart';

class UserStatsProvider with ChangeNotifier {
  final UserStatsService _userStatsService = UserStatsService();
  
  UserStats? _userStats;
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, dynamic> _globalStats = {};
  bool _isLoading = false;
  String? _error;

  UserStats? get userStats => _userStats;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  Map<String, dynamic> get globalStats => _globalStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Kullanıcı istatistiklerini yükle
  Future<void> loadUserStats(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _userStats = await _userStatsService.getUserStats(userId);
      notifyListeners();
    } catch (e) {
      _setError('Kullanıcı istatistikleri yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Kullanıcı istatistiklerini güncelle
  Future<void> updateUserStats(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _userStatsService.updateUserStats(userId);
      // Güncellemeden sonra yeniden yükle
      await loadUserStats(userId);
    } catch (e) {
      _setError('Kullanıcı istatistikleri güncellenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Leaderboard yükle
  Future<void> loadLeaderboard({int limit = 10}) async {
    try {
      _leaderboard = await _userStatsService.getLeaderboard(limit: limit);
      notifyListeners();
    } catch (e) {
      _setError('Liderlik tablosu yüklenirken hata oluştu: $e');
    }
  }

  // Global istatistikleri yükle
  Future<void> loadGlobalStats() async {
    try {
      _globalStats = await _userStatsService.getGlobalStats();
      notifyListeners();
    } catch (e) {
      _setError('Global istatistikler yüklenirken hata oluştu: $e');
    }
  }

  // Etkinlik katılımı sonrası güncelleme
  Future<void> onEventParticipation(String userId, String eventId) async {
    try {
      await _userStatsService.onEventParticipation(userId, eventId);
      await loadUserStats(userId);
    } catch (e) {
      _setError('Etkinlik katılımı güncellenirken hata oluştu: $e');
    }
  }

  // Etkinlik organize edildiğinde güncelleme
  Future<void> onEventOrganized(String userId, String eventId) async {
    try {
      await _userStatsService.onEventOrganized(userId, eventId);
      await loadUserStats(userId);
    } catch (e) {
      _setError('Organize edilen etkinlik güncellenirken hata oluştu: $e');
    }
  }

  // Kullanıcının seviye ilerlemesi için gereken puan
  String getProgressText() {
    if (_userStats == null) return '';
    
    return 'Seviye ${_userStats!.userLevel} • ${_userStats!.pointsToNextLevel} puan kaldı';
  }

  // Kullanıcının başarı durumu
  String getAchievementText() {
    if (_userStats == null) return '';
    
    return '%${_userStats!.achievementPercentage.round()} başarı oranı';
  }

  // Kullanıcının en iyi kategorisi
  String getBestCategoryText() {
    if (_userStats == null || _userStats!.categoryStats.isEmpty) {
      return 'Henüz kategori verisi yok';
    }
    
    return 'En sevilen: ${_userStats!.favoriteCategory}';
  }

  // Streak durumu
  String getStreakText() {
    if (_userStats == null) return '';
    
    if (_userStats!.currentStreak == 0) {
      return 'Henüz streak yok';
    }
    
    return '${_userStats!.currentStreak} haftalık streak!';
  }

  // Bu ay vs geçen ay karşılaştırması
  String getMonthlyComparisonText() {
    if (_userStats == null) return '';
    
    final thisMonth = _userStats!.thisMonthEvents;
    final lastMonth = _userStats!.lastMonthEvents;
    
    if (lastMonth == 0) {
      return 'Bu ay $thisMonth etkinlik';
    }
    
    final growth = _userStats!.monthlyGrowthRate;
    final growthText = growth > 0 ? '+${growth.round()}%' : '${growth.round()}%';
    
    return 'Bu ay $thisMonth etkinlik ($growthText)';
  }

  // Ranking durumu
  String getRankingText() {
    if (_userStats == null) return '';
    
    if (_userStats!.rankPosition == 0) {
      return 'Henüz sıralama yok';
    }
    
    return '#${_userStats!.rankPosition} sırada';
  }

  // İstatistik özeti kartları için veri
  List<Map<String, dynamic>> getStatsSummaryCards() {
    if (_userStats == null) return [];
    
    return [
      {
        'title': 'Katıldığı Etkinlikler',
        'value': _userStats!.totalEventsParticipated.toString(),
        'subtitle': 'Toplam katılım',
        'icon': '🎉',
        'color': const Color(0xFF4CAF50),
      },
      {
        'title': 'Organize Ettiği',
        'value': _userStats!.totalEventsOrganized.toString(),
        'subtitle': 'Düzenlediği etkinlik',
        'icon': '📅',
        'color': const Color(0xFF2196F3),
      },
      {
        'title': 'Kazandığı Rozetler',
        'value': _userStats!.totalBadgesEarned.toString(),
        'subtitle': 'Başarı rozeti',
        'icon': '🏆',
        'color': const Color(0xFFFF9800),
      },
      {
        'title': 'Aktivite Seviyesi',
        'value': _userStats!.userLevel.toString(),
        'subtitle': 'Mevcut seviye',
        'icon': '⭐',
        'color': const Color(0xFF9C27B0),
      },
    ];
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}