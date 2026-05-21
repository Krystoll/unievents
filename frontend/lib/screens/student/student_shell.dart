import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../providers/events_provider.dart';
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
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'События'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Мои записи'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Имя: ${user?.name ?? '-'}'),
          const SizedBox(height: 8),
          Text('Email: ${user?.email ?? '-'}'),
          const SizedBox(height: 8),
          Text('Роль: ${user?.role ?? '-'}'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/student/qr'),
            icon: const Icon(Icons.qr_code),
            label: const Text('Показать QR-код'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
