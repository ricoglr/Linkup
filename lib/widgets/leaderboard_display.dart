import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_stats_provider.dart';
import '../models/user_stats.dart';

class LeaderboardDisplay extends StatefulWidget {
  final int limit;

  const LeaderboardDisplay({
    Key? key,
    this.limit = 10,
  }) : super(key: key);

  @override
  State<LeaderboardDisplay> createState() => _LeaderboardDisplayState();
}

class _LeaderboardDisplayState extends State<LeaderboardDisplay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserStatsProvider>().loadLeaderboard(limit: widget.limit);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsProvider>(
      builder: (context, statsProvider, child) {
        if (statsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (statsProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Liderlik tablosu yüklenirken hata oluştu',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => statsProvider.loadLeaderboard(limit: widget.limit),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        final leaderboard = statsProvider.leaderboard;
        if (leaderboard.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Henüz liderlik tablosu verisi yok'),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.leaderboard, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Liderlik Tablosu',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => statsProvider.loadLeaderboard(limit: widget.limit),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),

            // Top 3 podium
            if (leaderboard.length >= 3) 
              _buildPodium(context, leaderboard.take(3).toList()),

            const SizedBox(height: 16),

            // Geri kalan liste
            Expanded(
              child: ListView.builder(
                itemCount: leaderboard.length,
                itemBuilder: (context, index) {
                  final user = leaderboard[index];
                  return _buildLeaderboardItem(context, user, index);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPodium(BuildContext context, List<Map<String, dynamic>> topThree) {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2. sıra
          if (topThree.length > 1)
            _buildPodiumPosition(context, topThree[1], 2, 120, Colors.grey),
          
          // 1. sıra
          _buildPodiumPosition(context, topThree[0], 1, 150, Colors.amber),
          
          // 3. sıra
          if (topThree.length > 2)
            _buildPodiumPosition(context, topThree[2], 3, 100, Colors.brown),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(
    BuildContext context,
    Map<String, dynamic> user,
    int position,
    double height,
    Color color,
  ) {
    final UserStats stats = user['stats'];
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Kullanıcı avatarı
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            image: user['photoURL'].isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(user['photoURL']),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: user['photoURL'].isEmpty
              ? Icon(Icons.person, size: 30, color: color)
              : null,
        ),
        
        const SizedBox(height: 8),
        
        // Kullanıcı adı
        SizedBox(
          width: 80,
          child: Text(
            user['username'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Puan
        Text(
          '${stats.totalEventsParticipated} etkinlik',
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Podium
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                position.toString(),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (position == 1) const Text('👑', style: TextStyle(fontSize: 24)),
              if (position == 2) const Text('🥈', style: TextStyle(fontSize: 20)),
              if (position == 3) const Text('🥉', style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(BuildContext context, Map<String, dynamic> user, int index) {
    final UserStats stats = user['stats'];
    final bool isTopThree = index < 3;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isTopThree ? 4 : 1,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: user['photoURL'].isNotEmpty
                  ? NetworkImage(user['photoURL'])
                  : null,
              child: user['photoURL'].isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getRankColor(index + 1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user['username'],
                style: TextStyle(
                  fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (stats.userLevel > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lv.${stats.userLevel}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${stats.totalEventsParticipated} etkinliğe katıldı'),
            if (stats.totalBadgesEarned > 0)
              Text(
                '🏆 ${stats.totalBadgesEarned} rozet kazandı',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${stats.activityScore}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getRankColor(index + 1),
              ),
            ),
            Text(
              'puan',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        onTap: () => _showUserStatsDialog(context, user),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  void _showUserStatsDialog(BuildContext context, Map<String, dynamic> user) {
    final UserStats stats = user['stats'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: user['photoURL'].isNotEmpty
                  ? NetworkImage(user['photoURL'])
                  : null,
              child: user['photoURL'].isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user['username'],
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Katıldığı Etkinlikler', '${stats.totalEventsParticipated}'),
            _buildStatRow('Organize Ettiği', '${stats.totalEventsOrganized}'),
            _buildStatRow('Rozet Sayısı', '${stats.totalBadgesEarned}'),
            _buildStatRow('Seviye', '${stats.userLevel}'),
            _buildStatRow('Aktivite Puanı', '${stats.activityScore}'),
            if (stats.currentStreak > 0)
              _buildStatRow('Aktif Streak', '${stats.currentStreak} hafta'),
            if (stats.favoriteCategory != 'Henüz yok')
              _buildStatRow('En Sevilen Kategori', stats.favoriteCategory),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}