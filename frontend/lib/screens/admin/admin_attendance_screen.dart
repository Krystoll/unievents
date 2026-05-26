import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/event_context_banner.dart';
import '../../widgets/common/form_section.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/participant_tile.dart';
import '../../widgets/confirm_action.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key, required this.event});

  final Event event;

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().loadAttendance(widget.event.id);
    });
  }

  Future<void> _finalizeEvent() async {
    final confirmed = await confirmAction(
      context,
      title: 'Завершить мероприятие?',
      message:
          '«${widget.event.title}» будет закрыто. Рейтинги надёжности обновятся для неявившихся.',
      confirmLabel: 'Завершить',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final msg = await context.read<EventsProvider>().finalizeEvent(widget.event.id);
    if (!context.mounted || msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    await context.read<EventsProvider>().loadAttendance(widget.event.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    final data = provider.attendance;

    if (data == null) {
      if (provider.error != null) {
        return ErrorState(
          message: provider.error!,
          onRetry: () => provider.loadAttendance(widget.event.id),
        );
      }
      return const LoadingView(message: 'Загрузка статистики...');
    }

    final progress = data.totalRegistered == 0 ? 0.0 : data.attended / data.totalRegistered;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        EventContextBanner(event: widget.event),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(Icons.bar_chart_rounded, color: AppColors.secondary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Явка', style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            '${data.attended} из ${data.totalRegistered} '
                            '(${data.attendanceRate.toStringAsFixed(1)}%)',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: AppColors.outline,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _finalizeEvent,
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Завершить мероприятие'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FormSection(
          title: 'Пришедшие',
          subtitle: '${data.attendees.length} человек',
          icon: Icons.check_circle_outline_rounded,
          child: data.attendees.isEmpty
              ? Text('Пока никто не отмечен', style: Theme.of(context).textTheme.bodyMedium)
              : Column(
                  children: data.attendees.map((a) {
                    final time = DateFormat('dd.MM.yyyy, HH:mm').format(a.attendedAt);
                    return ParticipantTile(
                      name: a.name,
                      email: 'Отмечен: $time',
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        FormSection(
          title: 'Не явились',
          subtitle: '${data.noShowList.length} человек',
          icon: Icons.person_off_outlined,
          child: data.noShowList.isEmpty
              ? Text('Все записанные пришли', style: Theme.of(context).textTheme.bodyMedium)
              : Column(
                  children: data.noShowList
                      .map((n) => ParticipantTile(name: n.name, email: 'Не отмечен на входе'))
                      .toList(),
                ),
        ),
      ],
    );
  }
}
