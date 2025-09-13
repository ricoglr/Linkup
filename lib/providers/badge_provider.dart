import 'package:flutter/foundation.dart';
import '../models/badge.dart';
import '../services/badge_service.dart';
import '../constant/entities.dart';

class BadgeProvider with ChangeNotifier {
  final BadgeService _badgeService = BadgeService();
  
  List<Badge> _allBadges = [];
  List<Badge> _userBadges = [];
  bool _isLoading = false;
  String? _error;

  List<Badge> get allBadges => _allBadges;
  List<Badge> get userBadges => _userBadges;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Tüm rozetleri yükle
  Future<void> loadAllBadges() async {
    _setLoading(true);
    _error = null;
    
    try {
      _allBadges = await _badgeService.getAllBadges();
      notifyListeners();
    } catch (e) {
      _error = 'Rozetler yüklenirken hata oluştu: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Kullanıcının rozetlerini yükle
  Future<void> loadUserBadges(String userId) async {
    _setLoading(true);
    _error = null;
    
    try {
      _userBadges = await _badgeService.getUserBadges(userId);
      notifyListeners();
    } catch (e) {
      _error = 'Kullanıcı rozetleri yüklenirken hata oluştu: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Kullanıcıya rozet ver
  Future<void> awardBadge(String userId, String badgeId) async {
    try {
      await _badgeService.awardBadge(userId, badgeId);
      // Kullanıcının rozetlerini güncelle
      await loadUserBadges(userId);
    } catch (e) {
      _error = 'Rozet verirken hata oluştu: $e';
      notifyListeners();
    }
  }

  // Kullanıcının etkinlik katılımına göre rozet kontrol et
  Future<void> checkAndAwardBadges(String userId, List<Event> participatedEvents) async {
    try {
      await _badgeService.checkAndAwardBadges(userId, participatedEvents);
      // Kullanıcının rozetlerini güncelle
      await loadUserBadges(userId);
    } catch (e) {
      _error = 'Rozet kontrolü sırasında hata oluştu: $e';
      notifyListeners();
    }
  }

  // Varsayılan rozetleri başlat
  Future<void> initializeDefaultBadges() async {
    try {
      await _badgeService.initializeDefaultBadges();
      await loadAllBadges();
    } catch (e) {
      _error = 'Varsayılan rozetler başlatılırken hata oluştu: $e';
      notifyListeners();
    }
  }

  // Kullanıcının belirli bir rozeti var mı kontrol et
  bool hasUserBadge(String badgeId) {
    return _userBadges.any((badge) => badge.id == badgeId);
  }

  // Kullanıcının rozet sayısını getir
  int get userBadgeCount => _userBadges.length;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}