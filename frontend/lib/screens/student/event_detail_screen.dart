import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/info_row.dart';
import '../../widgets/common/loading_view.dart';
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
      return const Scaffold(body: LoadingView());
    }
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мероприятие')),
        body: Center(child: Text(provider.error ?? 'Не удалось загрузить мероприятие')),
      );
    }

    final dateText = DateFormat('dd.MM.yyyy, HH:mm').format(_event!.eventDate);
    final freePlaces = _event!.maxParticipants - _event!.currentParticipants;
    final isApproval = _event!.type == 'APPROVAL';
    final hasPlaces = _event!.currentParticipants < _event!.maxParticipants;
    final typeLabel = isApproval ? 'По заявке' : 'Свободная запись';

    return Scaffold(
      appBar: AppBar(title: const Text('Мероприятие')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.cardAccent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _event!.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    typeLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Описание', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_event!.description, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  InfoRow(icon: Icons.calendar_today_outlined, label: 'Дата', value: dateText),
                  InfoRow(icon: Icons.place_outlined, label: 'Место', value: _event!.location),
                  InfoRow(
                    icon: Icons.people_outline,
                    label: 'Свободно мест',
                    value: '$freePlaces из ${_event!.maxParticipants}',
                  ),
                  InfoRow(
                    icon: Icons.queue,
                    label: 'В очереди',
                    value: '${_event!.waitlistCount}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Text('Ваш статус', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (registration != null)
                    StatusChip(
                      status: registration.status,
                      queuePosition: registration.queuePosition,
                    )
                  else
                    Text(
                      'Не записаны',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (registration == null && isApproval) ...[
            Text('Форма заявки', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ..._event!.fields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: TextField(
                  controller: _answerControllers[field.id],
                  decoration: InputDecoration(
                    labelText: field.fieldName + (field.required ? ' *' : ''),
                  ),
                ),
              ),
            ),
          ],
          if (registration == null)
            FilledButton.icon(
              onPressed: () => _register(context, isApproval, hasPlaces),
              icon: const Icon(Icons.how_to_reg_rounded),
              label: Text(
                isApproval
                    ? 'Подать заявку'
                    : hasPlaces
                        ? 'Записаться'
                        : 'Встать в очередь',
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _cancel(context),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Отменить участие'),
            ),
        ],
      ),
    );
  }

  Future<void> _register(BuildContext context, bool isApproval, bool hasPlaces) async {
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
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
    await _load();
  }

  Future<void> _cancel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await context.read<EventsProvider>().cancelRegistration(widget.eventId);
    if (!context.mounted || message == null) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
    await _load();
  }
}
