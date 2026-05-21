import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../models/event.dart';
import 'admin_applications_screen.dart';
import 'admin_attendance_screen.dart';
import 'admin_create_event_screen.dart';
import 'admin_events_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  Event? _editingEvent;
  Event? _applicationsEvent;
  Event? _attendanceEvent;

  static const _titles = [
    'Все мероприятия',
    'Создать мероприятие',
    'Заявки',
    'Статистика',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pages = [
          AdminEventsScreen(
            onCreate: () {
              setState(() {
                _editingEvent = null;
                _selectedIndex = 1;
              });
            },
            onEdit: (event) {
              setState(() {
                _editingEvent = event;
                _selectedIndex = 1;
              });
            },
            onApplications: (event) {
              setState(() {
                _applicationsEvent = event;
                _selectedIndex = 2;
              });
            },
            onAttendance: (event) {
              setState(() {
                _attendanceEvent = event;
                _selectedIndex = 3;
              });
            },
          ),
          AdminCreateEventScreen(
            initialEvent: _editingEvent,
            onSaved: () {
              setState(() {
                _editingEvent = null;
                _selectedIndex = 0;
              });
            },
          ),
          _applicationsEvent == null
              ? const Center(child: Text('Выберите мероприятие на вкладке «События»'))
              : AdminApplicationsScreen(event: _applicationsEvent!),
          _attendanceEvent == null
              ? const Center(child: Text('Выберите мероприятие на вкладке «События»'))
              : AdminAttendanceScreen(event: _attendanceEvent!),
        ];

        final isExtended = constraints.maxWidth > 1100;

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: isExtended,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                labelType: isExtended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.event),
                    label: Text('События'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.add_box),
                    label: Text('Создать'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people),
                    label: Text('Заявки'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.bar_chart),
                    label: Text('Статистика'),
                  ),
                ],
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: IconButton(
                      tooltip: 'Выйти',
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        _titles[_selectedIndex],
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Expanded(child: pages[_selectedIndex]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
