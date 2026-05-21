import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/events_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/event_context_banner.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/participant_tile.dart';
import '../../widgets/common/styled_tabs.dart';
import '../../widgets/confirm_action.dart';

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
      if (provider.error != null) {
        return ErrorState(
          message: provider.error!,
          onRetry: () => provider.loadParticipants(widget.event.id),
        );
      }
      return const LoadingView(message: 'Загрузка участников...');
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EventContextBanner(event: widget.event),
          const SizedBox(height: AppSpacing.md),
          const StyledTabBar(
            tabs: [
              Tab(text: 'Записаны'),
              Tab(text: 'Очередь'),
              Tab(text: 'Заявки'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
    if (items.isEmpty) {
      return EmptyState(
        icon: showQueue ? Icons.queue_outlined : Icons.people_outline,
        message: showQueue ? 'Очередь пуста' : 'Пока никто не записан',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final p = items[index];
        final dateText = DateFormat('dd.MM.yyyy, HH:mm').format(p.registeredAt);
        final subtitle = showQueue
            ? 'Очередь #${p.queuePosition ?? '-'} • $dateText'
            : 'Записан: $dateText';

        return ParticipantTile(
          name: p.name,
          email: p.email,
          subtitle: subtitle,
          reliabilityScore: p.reliabilityScore,
        );
      },
    );
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList({required this.eventId, required this.items});

  final String eventId;
  final List<ParticipantInfo> items;

  Future<void> _approve(BuildContext context, String eventId, ParticipantInfo p) async {
    final confirmed = await confirmAction(
      context,
      title: 'Одобрить заявку?',
      message: 'Студент ${p.name} будет записан на мероприятие.',
      confirmLabel: 'Одобрить',
    );
    if (!confirmed || !context.mounted) return;

    final msg = await context.read<EventsProvider>().approve(eventId, p.registrationId);
    if (!context.mounted || msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    await context.read<EventsProvider>().loadParticipants(eventId);
  }

  Future<void> _reject(BuildContext context, String eventId, ParticipantInfo p) async {
    final confirmed = await confirmAction(
      context,
      title: 'Отклонить заявку?',
      message: 'Заявка студента ${p.name} будет отклонена.',
      confirmLabel: 'Отклонить',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final msg = await context.read<EventsProvider>().reject(eventId, p.registrationId);
    if (!context.mounted || msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    await context.read<EventsProvider>().loadParticipants(eventId);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.pending_actions_outlined,
        message: 'Нет заявок на рассмотрении',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final p = items[index];
        return ParticipantTile(
          name: p.name,
          email: p.email,
          reliabilityScore: p.reliabilityScore,
          actions: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.answers.isNotEmpty) ...[
                Text('Ответы', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                ...p.answers.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${a.fieldName}: ${a.answer}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _approve(context, eventId, p),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Одобрить'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _reject(context, eventId, p),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Отклонить'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
