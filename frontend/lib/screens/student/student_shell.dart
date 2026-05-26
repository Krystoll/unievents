import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

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
