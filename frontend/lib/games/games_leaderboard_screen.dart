import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/games_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/game_stats.dart';
import 'game_scoring.dart';

class GamesLeaderboardScreen extends StatefulWidget {
  const GamesLeaderboardScreen({super.key, required this.gameType});

  final GameType gameType;

  @override
  State<GamesLeaderboardScreen> createState() => _GamesLeaderboardScreenState();
}

class _GamesLeaderboardScreenState extends State<GamesLeaderboardScreen> {
  final _service = GamesService();
  late Future<List<LeaderboardEntry>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _service.getLeaderboard(widget.gameType);
  }

  Future<void> _reload() async {
    setState(() => _leaderboardFuture = _service.getLeaderboard(widget.gameType));
    await _leaderboardFuture;
  }

  String _progressLabel(LeaderboardEntry entry) {
    return switch (widget.gameType) {
      GameType.memory => '${entry.progress}/${GameScoring.memoryMaxLevels} ур.',
      GameType.simon => '${entry.progress}/${GameScoring.simonMaxRounds} раундов',
      GameType.tap => '${entry.progress} очков',
      GameType.pattern => '${entry.progress} размещений',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Топ — ${widget.gameType.title}'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Не удалось загрузить таблицу лидеров'),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(onPressed: _reload, child: const Text('Повторить')),
                ],
              ),
            );
          }

          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Пока нет результатов — сыграйте первым!')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _LeaderboardTile(
                  entry: entry,
                  progressLabel: _progressLabel(entry),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry, required this.progressLabel});

  final LeaderboardEntry entry;
  final String progressLabel;

  Color _rankColor(int rank) {
    return switch (rank) {
      1 => const Color(0xFFFFD54F),
      2 => const Color(0xFFB0BEC5),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColor(entry.rank);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rankColor.withValues(alpha: 0.2),
          child: Text(
            '${entry.rank}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: entry.rank <= 3 ? rankColor : null,
            ),
          ),
        ),
        title: Text(entry.userName),
        subtitle: Text(
          '$progressLabel • ${GameScoring.formatDuration(entry.durationMs)}'
          '${entry.completed ? ' • завершено' : ''}',
        ),
        trailing: Text(
          '${entry.score}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
