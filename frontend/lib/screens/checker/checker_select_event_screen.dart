import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/events_provider.dart';

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

  List<Event> _todayAndUpcoming(List<Event> events) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return events
        .where((event) => !event.eventDate.isBefore(startOfToday))
        .toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    if (provider.isLoadingEvents) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final events = _todayAndUpcoming(provider.events);
    return Scaffold(
      appBar: AppBar(title: const Text('Выбор мероприятия')),
      body: events.isEmpty
          ? const Center(child: Text('Нет мероприятий на сегодня и ближайшие дни'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  child: ListTile(
                    title: Text(event.title),
                    subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(event.eventDate)),
                    onTap: () => context.go('/checker/scan/${event.id}', extra: event.title),
                  ),
                );
              },
            ),
    );
  }
}
