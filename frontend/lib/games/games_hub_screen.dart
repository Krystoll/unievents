import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  static const _categories = [
    _GameCategory(
      title: 'Запоминание',
      subtitle: 'Мини-memory',
      color: Color(0xFFFFC074),
      icon: Icons.psychology_outlined,
      route: '/student/games/memory',
    ),
    _GameCategory(
      title: 'Логика',
      subtitle: 'Запомни и повтори',
      color: Color(0xFFB18CFF),
      icon: Icons.lightbulb_outline_rounded,
      route: '/student/games/simon',
    ),
    _GameCategory(
      title: 'Внимание',
      subtitle: 'Tap-the-Target',
      color: Color(0xFF44C6D1),
      icon: Icons.track_changes_rounded,
      route: '/student/games/tap',
    ),
    _GameCategory(
      title: 'Мышление',
      subtitle: 'Блочный пазл',
      color: Color(0xFF82B4FF),
      icon: Icons.extension_outlined,
      route: '/student/games/pattern',
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
        title: const Text('Нейро-игры'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: AppColors.cardAccent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'UniEvents Games',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Тренируйте память, логику, внимание и мышление',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Выберите игру',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ..._categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _GameCategoryCard(
                category: category,
                onTap: () => context.push(category.route),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCategory {
  const _GameCategory({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final String route;
}

class _GameCategoryCard extends StatelessWidget {
  const _GameCategoryCard({
    required this.category,
    required this.onTap,
  });

  final _GameCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(category.icon, color: category.color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.title, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      category.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
