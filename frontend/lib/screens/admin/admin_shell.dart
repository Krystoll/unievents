import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/empty_state.dart';
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
              ? const EmptyState(
                  icon: Icons.people_outline,
                  message: 'Выберите мероприятие на вкладке «События»',
                )
              : AdminApplicationsScreen(event: _applicationsEvent!),
          _attendanceEvent == null
              ? const EmptyState(
                  icon: Icons.bar_chart_outlined,
                  message: 'Выберите мероприятие на вкладке «События»',
                )
              : AdminAttendanceScreen(event: _attendanceEvent!),
        ];

        final isExtended = constraints.maxWidth > 1100;

        return Scaffold(
          body: Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  border: Border(right: BorderSide(color: AppColors.outline)),
                ),
                child: NavigationRail(
                  extended: isExtended,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  labelType: isExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: isExtended
                        ? const AppLogo(showTitle: true, size: 40)
                        : const AppLogo(showTitle: false, size: 36),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.event_outlined),
                      selectedIcon: Icon(Icons.event_rounded),
                      label: Text('События'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.add_box_outlined),
                      selectedIcon: Icon(Icons.add_box_rounded),
                      label: Text('Создать'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people_rounded),
                      label: Text('Заявки'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart_rounded),
                      label: Text('Статистика'),
                    ),
                  ],
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: IconButton.filledTonal(
                          tooltip: 'Выйти',
                          onPressed: () async {
                            await context.read<AuthProvider>().logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                          icon: const Icon(Icons.logout_rounded),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainer,
                        border: Border(bottom: BorderSide(color: AppColors.outline)),
                      ),
                      child: Text(
                        _titles[_selectedIndex],
                        style: Theme.of(context).textTheme.headlineMedium,
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
