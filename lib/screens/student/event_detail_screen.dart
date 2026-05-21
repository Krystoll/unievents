import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../../widgets/status_chip.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? _event;
  bool _loading = true;
  final Map<String, TextEditingController> _answerControllers = {};

  @override
  void dispose() {
    for (final c in _answerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final event = await context.read<EventsProvider>().loadEventById(widget.eventId);
    if (!mounted) return;
    setState(() {
      _event = event;
      _loading = false;
    });
    if (event != null) {
      _answerControllers.clear();
      for (final field in event.fields) {
        _answerControllers[field.id] = TextEditingController();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    final registration = provider.registrationByEventId(widget.eventId);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Детали мероприятия')),
        body: Center(child: Text(provider.error ?? 'Не удалось загрузить мероприятие')),
      );
    }

    final dateText = DateFormat('dd.MM.yyyy HH:mm').format(_event!.eventDate);
    final freePlaces = _event!.maxParticipants - _event!.currentParticipants;
    final isApproval = _event!.type == 'APPROVAL';
    final hasPlaces = _event!.currentParticipants < _event!.maxParticipants;

    return Scaffold(
      appBar: AppBar(title: const Text('Детали мероприятия')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(_event!.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(_event!.description),
            const SizedBox(height: 12),
            Text('Дата: $dateText'),
            Text('Место: ${_event!.location}'),
            Text('Свободно мест: $freePlaces'),
            Text('В очереди: ${_event!.waitlistCount}'),
            Text('Тип: ${_event!.type}'),
            const SizedBox(height: 12),
            if (registration != null)
              StatusChip(
                status: registration.status,
                queuePosition: registration.queuePosition,
              )
            else
              const Text('Вы не записаны'),
            const SizedBox(height: 16),
            if (registration == null && isApproval) ...[
              Text('Форма заявки', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._event!.fields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _answerControllers[field.id],
                    decoration: InputDecoration(
                      labelText: field.fieldName + (field.required ? ' *' : ''),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
            if (registration == null)
              FilledButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final answers = <Map<String, String>>[];
                  if (isApproval) {
                    for (final field in _event!.fields) {
                      final answer = _answerControllers[field.id]?.text.trim() ?? '';
                      if (field.required && answer.isEmpty) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Заполните поле: ${field.fieldName}')),
                        );
                        return;
                      }
                      if (answer.isNotEmpty) {
                        answers.add({'fieldId': field.id, 'answer': answer});
                      }
                    }
                  }
                  final result = await context.read<EventsProvider>().registerForEvent(
                        widget.eventId,
                        answers: answers,
                      );
                  if (!context.mounted || result == null) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text(result.message)),
                  );
                  await _load();
                },
                child: Text(
                  isApproval
                      ? 'Подать заявку'
                      : hasPlaces
                          ? 'Записаться'
                          : 'Встать в очередь',
                ),
              )
            else
              OutlinedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final message =
                      await context.read<EventsProvider>().cancelRegistration(widget.eventId);
                  if (!context.mounted || message == null) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                  await _load();
                },
                child: const Text('Отменить участие'),
              ),
          ],
        ),
      ),
    );
  }
}
