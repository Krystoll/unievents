import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/games_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/game_stats.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/profile_card.dart';
import 'events_list_screen.dart';
import 'my_registrations_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<EventsProvider>();
      await provider.loadEvents();
      await provider.loadMyRegistrations();
    });
  }

  @override
  Widget build(BuildContext context) {
    const pages = [
      EventsListScreen(),
      MyRegistrationsScreen(),
      _ProfileScreen(),
    ];
    const titles = ['Мероприятия', 'Мои записи', 'Профиль'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              tooltip: 'Обновить',
              onPressed: () => context.read<EventsProvider>().loadEvents(),
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event_rounded),
            label: 'События',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Записи',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

class _ProfileScreen extends StatefulWidget {
  const _ProfileScreen();

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  final _gamesService = GamesService();
  late Future<List<GameTypeStats>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _gamesService.getMyStats();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ProfileCard(
          name: user?.name ?? '—',
          email: user?.email ?? '—',
          role: user?.role ?? '—',
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Нейро-игры', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        FutureBuilder<List<GameTypeStats>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final stats = snapshot.data ?? [];
            final totalGames = stats.fold<int>(0, (sum, s) => sum + s.gamesPlayed);
            final bestScore = stats.fold<int>(0, (max, s) => s.bestScore > max ? s.bestScore : max);

            return Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Всего игр: $totalGames', style: Theme.of(context).textTheme.titleSmall),
                                  Text('Лучший счёт: $bestScore', style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/student/games/stats'),
                              child: const Text('Подробнее'),
                            ),
                          ],
                        ),
                        if (stats.any((s) => s.gamesPlayed > 0)) ...[
                          const Divider(height: AppSpacing.lg),
                          ...stats.where((s) => s.gamesPlayed > 0).map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(s.gameType.title, style: Theme.of(context).textTheme.bodyMedium),
                                      ),
                                      Text('${s.bestScore}', style: Theme.of(context).textTheme.titleSmall),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        '(${s.gamesPlayed})',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ] else
                          Text(
                            'Сыграйте в нейро-игры, чтобы увидеть статистику',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _ActionTile(
                  icon: Icons.sports_esports_outlined,
                  title: 'Нейро-игры',
                  subtitle: 'Тренировка памяти и внимания',
                  color: AppColors.primary,
                  onTap: () => context.push('/student/games'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ActionTile(
                  icon: Icons.bar_chart_rounded,
                  title: 'Статистика и рейтинг',
                  subtitle: 'Ваши результаты и топ игроков',
                  color: const Color(0xFF7E57C2),
                  onTap: () => context.push('/student/games/stats'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        _ActionTile(
          icon: Icons.qr_code_2_rounded,
          title: 'QR-код для входа',
          subtitle: 'Покажите на мероприятии',
          color: AppColors.primary,
          onTap: () => context.push('/student/qr'),
        ),
        const SizedBox(height: AppSpacing.md),
        _ActionTile(
          icon: Icons.logout_rounded,
          title: 'Выйти из аккаунта',
          subtitle: 'Завершить сессию',
          color: AppColors.error,
          onTap: () async {
            await context.read<AuthProvider>().logout();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
