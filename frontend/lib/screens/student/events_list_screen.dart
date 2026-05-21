import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/events_provider.dart';
import '../../widgets/event_card.dart';

class EventsListScreen extends StatelessWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    if (provider.isLoadingEvents) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.events.isEmpty) {
      return _ErrorState(
        message: provider.error!,
        onRetry: () => context.read<EventsProvider>().loadEvents(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<EventsProvider>().loadEvents(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.events.length,
        itemBuilder: (context, index) {
          final event = provider.events[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EventCard(
              event: event,
              onDetails: () => context.push('/student/events/${event.id}'),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
