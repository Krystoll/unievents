import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onDetails,
  });

  final Event event;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd.MM.yyyy HH:mm').format(event.eventDate);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('$dateText • ${event.location}'),
            const SizedBox(height: 4),
            Text('${event.currentParticipants} / ${event.maxParticipants} мест'),
            const SizedBox(height: 4),
            Text('Тип: ${event.type}'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onDetails,
              child: const Text('Подробнее'),
            ),
          ],
        ),
      ),
    );
  }
}
