import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/games_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/game_stats.dart';

class EventLeaderboardSection extends StatefulWidget {
  const EventLeaderboardSection({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventLeaderboardSection> createState() => _EventLeaderboardSectionState();
}

class _EventLeaderboardSectionState extends State<EventLeaderboardSection> {
  final _service = GamesService();
  GameType? _loadingType;
  final Map<GameType, List<LeaderboardEntry>> _cache = {};

  Future<void> _load(GameType type) async {
    if (_cache.containsKey(type)) return;
    setState(() => _loadingType = type);
    try {
      final entries = await _service.getEventLeaderboard(eventId: widget.eventId, gameType: type);
      if (mounted) setState(() => _cache[type] = entries);
    } finally {
      if (mounted) setState(() => _loadingType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Топ игроков мероприятия', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Рейтинг по каждой игре среди участников',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            ...GameType.values.map((type) {
              final entries = _cache[type];
              final loading = _loadingType == type;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(type.title, style: Theme.of(context).textTheme.titleSmall),
                  subtitle: entries == null && !loading
                      ? const Text('Нажмите, чтобы загрузить')
                      : Text('${entries?.length ?? 0} игроков'),
                  onExpansionChanged: (open) {
                    if (open) _load(type);
                  },
                  children: [
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (entries == null || entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Text('Пока нет результатов'),
                      )
                    else ...[
                      ...entries.take(5).map(
                            (e) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                child: Text('${e.rank}', style: const TextStyle(fontSize: 12)),
                              ),
                              title: Text(e.userName),
                              trailing: Text('${e.score}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push(
                            '/student/events/${widget.eventId}/leaderboard/${type.name}',
                          ),
                          child: const Text('Весь топ'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class EventLeaderboardScreen extends StatefulWidget {
  const EventLeaderboardScreen({
    super.key,
    required this.eventId,
    required this.gameType,
  });

  final String eventId;
  final GameType gameType;

  @override
  State<EventLeaderboardScreen> createState() => _EventLeaderboardScreenState();
}

class _EventLeaderboardScreenState extends State<EventLeaderboardScreen> {
  final _service = GamesService();
  late Future<List<LeaderboardEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getEventLeaderboard(eventId: widget.eventId, gameType: widget.gameType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Топ — ${widget.gameType.title}')),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(child: Text('Пока нет результатов'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final e = entries[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${e.rank}')),
                title: Text(e.userName),
                subtitle: Text('Прогресс: ${e.progress}'),
                trailing: Text('${e.score}', style: Theme.of(context).textTheme.titleMedium),
              );
            },
          );
        },
      ),
    );
  }
}
