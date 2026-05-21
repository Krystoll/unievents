import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/events_service.dart';
import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../../widgets/reliability_badge.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key, required this.event});

  final Event event;

  @override
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().loadParticipants(widget.event.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    final participants = provider.participants;
    if (participants == null) {
      return Center(
        child: provider.error == null ? const CircularProgressIndicator() : Text(provider.error!),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Записаны'),
              Tab(text: 'Очередь'),
              Tab(text: 'Заявки'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SimpleParticipantsList(items: participants.registered, showQueue: false),
                _SimpleParticipantsList(items: participants.waitlist, showQueue: true),
                _PendingList(eventId: widget.event.id, items: participants.pending),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleParticipantsList extends StatelessWidget {
  const _SimpleParticipantsList({required this.items, required this.showQueue});

  final List<ParticipantInfo> items;
  final bool showQueue;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Список пуст'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final p = items[index];
        final dateText = DateFormat('dd.MM.yyyy HH:mm').format(p.registeredAt);
        return Card(
          child: ListTile(
            title: Text('${p.name} (${p.email})'),
            subtitle: Text('${showQueue ? 'Очередь #${p.queuePosition ?? '-'} • ' : ''}$dateText'),
            trailing: ReliabilityBadge(score: p.reliabilityScore),
          ),
        );
      },
    );
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList({required this.eventId, required this.items});

  final String eventId;
  final List<ParticipantInfo> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Заявок нет'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final p = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.name} (${p.email})'),
                const SizedBox(height: 8),
                ReliabilityBadge(score: p.reliabilityScore),
                const SizedBox(height: 8),
                ...p.answers.map((a) => Text('${a.fieldName}: ${a.answer}')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () async {
                        final msg = await context.read<EventsProvider>().approve(eventId, p.registrationId);
                        if (context.mounted && msg != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                        }
                      },
                      child: const Text('Одобрить'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final msg = await context.read<EventsProvider>().reject(eventId, p.registrationId);
                        if (context.mounted && msg != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                        }
                      },
                      child: const Text('Отклонить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
