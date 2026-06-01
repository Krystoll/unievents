import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class EventGamesHubScreen extends StatelessWidget {
  const EventGamesHubScreen({super.key, required this.eventId});

  final String eventId;

  static const _categories = [
    _GameRoute(
      title: 'Запоминание пар',
      subtitle: 'Мини-memory',
      color: Color(0xFFFFC074),
      icon: Icons.psychology_outlined,
      path: 'memory',
    ),
    _GameRoute(
      title: 'Запомни и повтори',
      subtitle: 'Последовательности',
      color: Color(0xFFB18CFF),
      icon: Icons.lightbulb_outline_rounded,
      path: 'simon',
    ),
    _GameRoute(
      title: 'Tap-the-Target',
      subtitle: 'Внимание и реакция',
      color: Color(0xFF44C6D1),
      icon: Icons.track_changes_rounded,
      path: 'tap',
    ),
    _GameRoute(
      title: 'Блочный пазл',
      subtitle: 'Логика и стратегия',
      color: Color(0xFF82B4FF),
      icon: Icons.extension_outlined,
      path: 'pattern',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Игры мероприятия'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Результаты сохраняются в рейтинг этого мероприятия',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Card(
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: c.color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(c.icon, color: c.color),
                  ),
                  title: Text(c.title),
                  subtitle: Text(c.subtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/student/events/$eventId/games/${c.path}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameRoute {
  const _GameRoute({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.path,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final String path;
}
