import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_stats_provider.dart';
import '../models/user_stats.dart';

class UserStatsDisplay extends StatefulWidget {
  final String userId;
  final bool showDetailed;

  const UserStatsDisplay({
    Key? key,
    required this.userId,
    this.showDetailed = false,
  }) : super(key: key);

  @override
  State<UserStatsDisplay> createState() => _UserStatsDisplayState();
}

class _UserStatsDisplayState extends State<UserStatsDisplay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserStatsProvider>().loadUserStats(widget.userId);
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
                  'İstatistikler yüklenirken hata oluştu',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => statsProvider.loadUserStats(widget.userId),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        final userStats = statsProvider.userStats;
        if (userStats == null) {
          return const Center(child: Text('İstatistik bulunamadı'));
        }

        if (widget.showDetailed) {
          return _buildDetailedStats(context, userStats, statsProvider);
        } else {
          return _buildSummaryStats(context, userStats, statsProvider);
        }
      },
    );
  }

  Widget _buildSummaryStats(BuildContext context, UserStats userStats, UserStatsProvider provider) {
    final summaryCards = provider.getStatsSummaryCards();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // İstatistik kartları
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: summaryCards.length,
          itemBuilder: (context, index) {
            final card = summaryCards[index];
            return _buildStatCard(
              context,
              title: card['title'],
              value: card['value'],
              subtitle: card['subtitle'],
              icon: card['icon'],
              color: card['color'],
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        // Hızlı bilgiler
        _buildQuickInfo(context, userStats, provider),
      ],
    );
  }

  Widget _buildDetailedStats(BuildContext context, UserStats userStats, UserStatsProvider provider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet kartlar
          _buildSummaryStats(context, userStats, provider),
          
          const SizedBox(height: 24),
          
          // Seviye ve ilerleme
          _buildLevelProgress(context, userStats),
          
          const SizedBox(height: 24),
          
          // Kategori istatistikleri
          _buildCategoryStats(context, userStats),
          
          const SizedBox(height: 24),
          
          // Aylık trend
          _buildMonthlyTrend(context, userStats),
          
          const SizedBox(height: 24),
          
          // Achievements ve streak
          _buildAchievements(context, userStats),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required String icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const Spacer(),
                Icon(Icons.trending_up, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo(BuildContext context, UserStats userStats, UserStatsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hızlı Bilgiler',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.star, provider.getProgressText()),
            _buildInfoRow(Icons.category, provider.getBestCategoryText()),
            _buildInfoRow(Icons.local_fire_department, provider.getStreakText()),
            _buildInfoRow(Icons.leaderboard, provider.getRankingText()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(BuildContext context, UserStats userStats) {
    final progress = (userStats.activityScore % 100) / 100;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seviye İlerlemesi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Seviye ${userStats.userLevel}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${userStats.pointsToNextLevel} puan kaldı',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toplam Aktivite Puanı: ${userStats.activityScore}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStats(BuildContext context, UserStats userStats) {
    if (userStats.categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori İstatistikleri',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...userStats.categoryStats.entries.map((entry) {
              final maxValue = userStats.categoryStats.values.reduce((a, b) => a > b ? a : b);
              final progress = entry.value / maxValue;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text('${entry.value} etkinlik'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrend(BuildContext context, UserStats userStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu Ay',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMonthCard(
                    context,
                    'Bu Ay',
                    userStats.thisMonthEvents.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMonthCard(
                    context,
                    'Geçen Ay',
                    userStats.lastMonthEvents.toString(),
                    Colors.grey,
                  ),
                ),
              ],
            ),
            if (userStats.lastMonthEvents > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: userStats.monthlyGrowthRate >= 0 ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      userStats.monthlyGrowthRate >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: userStats.monthlyGrowthRate >= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${userStats.monthlyGrowthRate >= 0 ? '+' : ''}${userStats.monthlyGrowthRate.round()}% değişim',
                      style: TextStyle(
                        color: userStats.monthlyGrowthRate >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(BuildContext context, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(BuildContext context, UserStats userStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Başarılar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAchievementCard(
                    context,
                    '🔥',
                    'Aktif Streak',
                    '${userStats.currentStreak} hafta',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAchievementCard(
                    context,
                    '🏆',
                    'En Uzun Streak',
                    '${userStats.longestStreak} hafta',
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    String emoji,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}