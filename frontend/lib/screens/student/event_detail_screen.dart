import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/event_time.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/info_row.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/status_chip.dart';
import 'event_leaderboard_section.dart';

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
    final provider = context.read<EventsProvider>();
    await provider.loadMyRegistrations();
    final event = await provider.loadEventById(widget.eventId);
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
    final status = registration?.status;

    if (_loading) {
      return const Scaffold(body: LoadingView());
    }
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мероприятие')),
        body: Center(child: Text(provider.error ?? 'Не удалось загрузить мероприятие')),
      );
    }

    final event = _event!;
    final scheduleText = formatEventSchedule(event.eventDate, event.endDate);
    final freePlaces = event.maxParticipants - event.currentParticipants;
    final isApproval = event.type == 'APPROVAL';
    final hasPlaces = event.currentParticipants < event.maxParticipants;
    final typeLabel = isApproval ? 'По заявке' : 'Свободная запись';
    final canRegister = !event.isPast && canRegisterForEvent(status);
    final canCancel = registration != null && canCancelRegistration(registration.status);
    final showQr = registration != null && canShowEventQr(registration.status, event);
    final canPlay = registration != null && canPlayEventGames(registration.status, event);
    final showLeaderboard = canViewEventLeaderboard(event);

    return Scaffold(
      appBar: AppBar(title: const Text('Мероприятие')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: event.isPast
                    ? LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade500])
                    : AppColors.cardAccent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Badge(label: typeLabel),
                      _Badge(label: event.phaseLabel),
                      if (registration != null) _Badge(label: 'Вы участвуете'),
                    ],
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
                    Text(event.description, style: Theme.of(context).textTheme.bodyLarge),
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
                    InfoRow(icon: Icons.calendar_today_outlined, label: 'Расписание', value: scheduleText),
                    InfoRow(
                      icon: Icons.timer_outlined,
                      label: 'Длительность',
                      value: '${event.durationMinutes} мин',
                    ),
                    InfoRow(icon: Icons.place_outlined, label: 'Место', value: event.location),
                    InfoRow(
                      icon: Icons.people_outline,
                      label: 'Свободно мест',
                      value: '$freePlaces из ${event.maxParticipants}',
                    ),
                    InfoRow(icon: Icons.queue, label: 'В очереди', value: '${event.waitlistCount}'),
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
                      Text('Не записаны', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            if (event.isPast)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Card(
                  color: AppColors.textSecondary.withValues(alpha: 0.08),
                  child: const ListTile(
                    leading: Icon(Icons.event_busy_outlined),
                    title: Text('Мероприятие завершено'),
                    subtitle: Text('Запись и игры недоступны'),
                  ),
                ),
              ),
            if (showQr) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => context.push(
                  '/student/qr?eventId=${event.id}&title=${Uri.encodeComponent(event.title)}',
                ),
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('Показать QR-код для входа'),
              ),
            ],
            if (registration?.status == 'REGISTERED' && event.isUpcoming) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'QR-код для входа будет доступен после начала мероприятия',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (registration?.status == 'REGISTERED' && event.isOngoing) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Покажите QR-код на входе, чтобы получить доступ к играм',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning),
              ),
            ],
            if (canPlay) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => context.push('/student/events/${event.id}/games'),
                icon: const Icon(Icons.sports_esports_outlined),
                label: const Text('Играть в нейро-игры'),
              ),
            ],
            if (registration?.status == 'ATTENDED' && event.isUpcoming)
              const SizedBox.shrink(),
            if (showLeaderboard) ...[
              const SizedBox(height: AppSpacing.lg),
              EventLeaderboardSection(eventId: event.id),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (canRegister && isApproval) ...[
              Text('Форма заявки', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ...event.fields.map(
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
            if (canRegister)
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
              ),
            if (canCancel)
              OutlinedButton.icon(
                onPressed: () => _cancel(context),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Отменить участие'),
              ),
          ],
        ),
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
          messenger.showSnackBar(SnackBar(content: Text('Заполните поле: ${field.fieldName}')));
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отменить участие?'),
        content: const Text('Вы уверены, что хотите отменить запись на мероприятие?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Да')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final message = await context.read<EventsProvider>().cancelRegistration(widget.eventId);
    if (!context.mounted || message == null) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
    await _load();
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }
}
