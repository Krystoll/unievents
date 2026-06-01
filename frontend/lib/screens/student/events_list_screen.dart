import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/event_time.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/event_card.dart';

class EventsListScreen extends StatelessWidget {
  const EventsListScreen({super.key});

  List<Event> _sortedEvents(List<Event> events) {
    final copy = List<Event>.from(events);
    copy.sort((a, b) {
      if (a.isPast != b.isPast) return a.isPast ? 1 : -1;
      return a.eventDate.compareTo(b.eventDate);
    });
    return copy;
  }

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

    final events = _sortedEvents(provider.events);
    if (events.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          EmptyState(
            icon: Icons.event_busy_outlined,
            message: 'Пока нет доступных мероприятий',
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<EventsProvider>().loadEvents();
        await context.read<EventsProvider>().loadMyRegistrations();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final event = events[index];
          return EventCard(
            event: event,
            isParticipating: provider.isParticipatingIn(event.id),
            onDetails: () => context.push('/student/events/${event.id}'),
          );
        },
      ),
    );
  }
}
