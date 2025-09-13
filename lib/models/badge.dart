import 'package:flutter/material.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int requirement;
  final Color color;
  final DateTime createdAt;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requirement,
    required this.color,
    required this.createdAt,
  });

  factory Badge.fromFirestore(Map<String, dynamic> data, String id) {
    return Badge(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: _getIconFromString(data['icon'] ?? 'star'),
      requirement: data['requirement'] ?? 0,
      color: Color(data['color'] ?? 0xFF2196F3),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': _getStringFromIcon(icon),
      'requirement': requirement,
      'color': color.value,
      'createdAt': createdAt,
    };
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'group':
        return Icons.group;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'campaign':
        return Icons.campaign;
      case 'eco':
        return Icons.eco;
      case 'school':
        return Icons.school;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'balance':
        return Icons.balance;
      case 'diversity_3':
        return Icons.diversity_3;
      case 'work':
        return Icons.work;
      case 'pets':
        return Icons.pets;
      default:
        return Icons.star;
    }
  }

  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.star) return 'star';
    if (icon == Icons.favorite) return 'favorite';
    if (icon == Icons.group) return 'group';
    if (icon == Icons.volunteer_activism) return 'volunteer_activism';
    if (icon == Icons.campaign) return 'campaign';
    if (icon == Icons.eco) return 'eco';
    if (icon == Icons.school) return 'school';
    if (icon == Icons.health_and_safety) return 'health_and_safety';
    if (icon == Icons.balance) return 'balance';
    if (icon == Icons.diversity_3) return 'diversity_3';
    if (icon == Icons.work) return 'work';
    if (icon == Icons.pets) return 'pets';
    return 'star';
  }
}

class UserBadge {
  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final int eventCount;

  UserBadge({
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    required this.eventCount,
  });

  factory UserBadge.fromFirestore(Map<String, dynamic> data) {
    return UserBadge(
      userId: data['userId'] ?? '',
      badgeId: data['badgeId'] ?? '',
      earnedAt: data['earnedAt']?.toDate() ?? DateTime.now(),
      eventCount: data['eventCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'badgeId': badgeId,
      'earnedAt': earnedAt,
      'eventCount': eventCount,
    };
  }
}