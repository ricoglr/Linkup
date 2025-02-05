import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getUserData(userId: widget.userId);
    setState(() => _userData = userData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_userData?['username'] ?? 'Kullanıcı Profili')),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_userData!['username']),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(
                      _userData!['about'] ?? 'Henüz bir açıklama eklenmemiş'),
                ),
              ],
            ),
    );
  }
}
