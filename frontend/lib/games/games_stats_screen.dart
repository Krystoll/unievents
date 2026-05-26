import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/games_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/game_stats.dart';
import 'game_scoring.dart';

class GamesStatsScreen extends StatefulWidget {
  const GamesStatsScreen({super.key});

  @override
  State<GamesStatsScreen> createState() => _GamesStatsScreenState();
}

class _GamesStatsScreenState extends State<GamesStatsScreen> {
  final _service = GamesService();
  late Future<List<GameTypeStats>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _service.getMyStats();
  }

  Future<void> _reload() async {
    setState(() => _statsFuture = _service.getMyStats());
    await _statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Статистика игр'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<GameTypeStats>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Не удалось загрузить статистику'),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(onPressed: _reload, child: const Text('Повторить')),
                ],
              ),
            );
          }

          final stats = snapshot.data ?? [];
          final byType = {for (final s in stats) s.gameType: s};
          final totalGames = stats.fold<int>(0, (sum, s) => sum + s.gamesPlayed);
          final bestOverall = stats.fold<int>(0, (max, s) => s.bestScore > max ? s.bestScore : max);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _SummaryCard(totalGames: totalGames, bestOverall: bestOverall),
                const SizedBox(height: AppSpacing.lg),
                Text('По играм', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                ...GameType.values.map((type) {
                  final stat = byType[type] ??
                      GameTypeStats(
                        gameType: type,
                        gamesPlayed: 0,
                        bestScore: 0,
                        averageScore: 0,
                        lastScore: 0,
                      );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _GameStatsCard(
                      stats: stat,
                      onLeaderboard: () => context.push('/student/games/leaderboard/${type.name}'),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalGames, required this.bestOverall});

  final int totalGames;
  final int bestOverall;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(label: 'Всего игр', value: '$totalGames'),
            ),
            Expanded(
              child: _SummaryItem(label: 'Лучший счёт', value: '$bestOverall'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _GameStatsCard extends StatelessWidget {
  const _GameStatsCard({required this.stats, required this.onLeaderboard});

  final GameTypeStats stats;
  final VoidCallback onLeaderboard;

  String get _progressLabel {
    return switch (stats.gameType) {
      GameType.memory => '${stats.lastProgress ?? 0}/${GameScoring.memoryMaxLevels} ур.',
      GameType.simon => '${stats.lastProgress ?? 0}/${GameScoring.simonMaxRounds} раундов',
      GameType.tap => '${stats.lastProgress ?? 0} очков за минуту',
      GameType.pattern => '${stats.lastProgress ?? 0} размещений',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(stats.gameType.title, style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  onPressed: onLeaderboard,
                  icon: const Icon(Icons.leaderboard_outlined, size: 18),
                  label: const Text('Топ'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _StatChip(label: 'Игр', value: '${stats.gamesPlayed}'),
                _StatChip(label: 'Рекорд', value: '${stats.bestScore}'),
                _StatChip(label: 'Среднее', value: stats.averageScore.toStringAsFixed(0)),
                _StatChip(label: 'Последний', value: '${stats.lastScore}'),
              ],
            ),
            if (stats.gamesPlayed > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Последняя игра: $_progressLabel'
                '${stats.lastDurationMs != null ? ' • ${GameScoring.formatDuration(stats.lastDurationMs!)}' : ''}'
                '${stats.lastCompleted == true ? ' • завершено' : stats.lastCompleted == false ? ' • не завершено' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ] else
              Text(
                'Ещё не играли — попробуйте!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleSmall),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
