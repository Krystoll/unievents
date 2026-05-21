import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/events_provider.dart';
import '../../widgets/status_chip.dart';

class MyRegistrationsScreen extends StatelessWidget {
  const MyRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    if (provider.isLoadingRegistrations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.myRegistrations.isEmpty) {
      return Center(child: Text(provider.error!));
    }

    if (provider.myRegistrations.isEmpty) {
      return const Center(child: Text('У вас пока нет записей'));
    }

    return RefreshIndicator(
      onRefresh: () => context.read<EventsProvider>().loadMyRegistrations(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.myRegistrations.length,
        itemBuilder: (context, index) {
          final registration = provider.myRegistrations[index];
          final event = registration.event;
          final dateText = DateFormat('dd.MM.yyyy HH:mm').format(event.eventDate);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('$dateText\n${event.location}'),
                  const SizedBox(height: 8),
                  StatusChip(
                    status: registration.status,
                    queuePosition: registration.queuePosition,
                  ),
                  if (registration.status == 'REGISTERED' || registration.status == 'WAITLISTED')
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () async {
                          final msg = await context
                              .read<EventsProvider>()
                              .cancelRegistration(event.id);
                          if (context.mounted && msg != null) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(msg)));
                          }
                        },
                        child: const Text('Отменить'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
