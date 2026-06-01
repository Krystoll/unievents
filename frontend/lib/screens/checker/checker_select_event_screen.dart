import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/event_time.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event.dart';
import '../../core/providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_view.dart';

class CheckerSelectEventScreen extends StatefulWidget {
  const CheckerSelectEventScreen({super.key});

  @override
  State<CheckerSelectEventScreen> createState() => _CheckerSelectEventScreenState();
}

class _CheckerSelectEventScreenState extends State<CheckerSelectEventScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().loadEvents();
    });
  }

  List<Event> _scannableEvents(List<Event> events) {
    return events.where((event) => event.isOngoing).toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    if (provider.isLoadingEvents) {
      return const Scaffold(body: LoadingView(message: 'Загрузка...'));
    }
    if (provider.error != null && provider.events.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сканирование')),
        body: ErrorState(
          message: provider.error!,
          onRetry: () => provider.loadEvents(),
        ),
      );
    }
    final events = _scannableEvents(provider.events);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор мероприятия'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => provider.loadEvents(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Выйти',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: events.isEmpty
          ? const EmptyState(
              icon: Icons.event_busy_outlined,
              message: 'Нет мероприятий, идущих прямо сейчас',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final event = events[index];
                final scheduleText = formatEventScheduleShort(event.eventDate, event.endDate);
                return Card(
                  child: InkWell(
                    onTap: () => context.go('/checker/scan/${event.id}', extra: event.title),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.secondary),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.title, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(scheduleText, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
