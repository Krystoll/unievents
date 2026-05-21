import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/event_card.dart';

class EventsListScreen extends StatelessWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    if (provider.isLoadingEvents) {
      return const LoadingView(message: 'Загрузка мероприятий...');
    }
    if (provider.error != null && provider.events.isEmpty) {
      return ErrorState(
        message: provider.error!,
        onRetry: () => context.read<EventsProvider>().loadEvents(),
      );
    }
    if (provider.events.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy_outlined,
        message: 'Пока нет доступных мероприятий',
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<EventsProvider>().loadEvents(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: provider.events.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final event = provider.events[index];
          return EventCard(
            event: event,
            onDetails: () => context.push('/student/events/${event.id}'),
          );
        },
      ),
    );
  }
}
