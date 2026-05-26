import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/confirm_action.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({
    super.key,
    required this.onCreate,
    required this.onEdit,
    required this.onApplications,
    required this.onAttendance,
  });

  final VoidCallback onCreate;
  final ValueChanged<Event> onEdit;
  final ValueChanged<Event> onApplications;
  final ValueChanged<Event> onAttendance;

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().loadEvents();
    });
  }

  Future<void> _deleteEvent(Event event) async {
    final confirmed = await confirmAction(
      context,
      title: 'Удалить мероприятие?',
      message: '«${event.title}» будет удалено без возможности восстановления.',
      confirmLabel: 'Удалить',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<EventsProvider>();
    final ok = await provider.deleteEvent(event.id);
    if (!context.mounted) return;
    final text = ok ? 'Мероприятие удалено' : (provider.error ?? 'Ошибка');
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    if (provider.isLoadingEvents) {
      return const LoadingView();
    }
    if (provider.error != null && provider.events.isEmpty) {
      return ErrorState(
        message: provider.error!,
        onRetry: () => context.read<EventsProvider>().loadEvents(),
      );
    }
    if (provider.events.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_outlined,
        message: 'Нет мероприятий',
        actionLabel: 'Создать',
        onAction: widget.onCreate,
      );
    }

    final headerStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: widget.onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Создать мероприятие'),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<EventsProvider>().loadEvents(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppColors.primary.withValues(alpha: 0.06),
                      ),
                      headingTextStyle: headerStyle,
                      dataTextStyle: Theme.of(context).textTheme.bodyLarge,
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('Название')),
                        DataColumn(label: Text('Дата')),
                        DataColumn(label: Text('Место')),
                        DataColumn(label: Text('Участники')),
                        DataColumn(label: Text('Тип')),
                        DataColumn(label: Text('Действия')),
                      ],
                      rows: provider.events.map((event) {
                        final dateText = DateFormat('dd.MM.yyyy, HH:mm').format(event.eventDate);
                        final isApproval = event.type == 'APPROVAL';
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  event.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ),
                            DataCell(Text(dateText)),
                            DataCell(Text(event.location)),
                            DataCell(
                              Text('${event.currentParticipants}/${event.maxParticipants}'),
                            ),
                            DataCell(_TypeBadge(approval: isApproval)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isApproval)
                                    _ActionIcon(
                                      icon: Icons.people_outline,
                                      tooltip: 'Заявки',
                                      onPressed: () => widget.onApplications(event),
                                    ),
                                  _ActionIcon(
                                    icon: Icons.bar_chart_outlined,
                                    tooltip: 'Статистика',
                                    onPressed: () => widget.onAttendance(event),
                                  ),
                                  _ActionIcon(
                                    icon: Icons.edit_outlined,
                                    tooltip: 'Редактировать',
                                    onPressed: () => widget.onEdit(event),
                                  ),
                                  _ActionIcon(
                                    icon: Icons.delete_outline,
                                    tooltip: 'Удалить',
                                    color: AppColors.error,
                                    onPressed: () => _deleteEvent(event),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.approval});

  final bool approval;

  @override
  Widget build(BuildContext context) {
    final color = approval ? AppColors.info : AppColors.secondary;
    final label = approval ? 'По заявке' : 'Свободная';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color ?? AppColors.primary),
      style: IconButton.styleFrom(
        backgroundColor: (color ?? AppColors.primary).withValues(alpha: 0.08),
      ),
    );
  }
}
