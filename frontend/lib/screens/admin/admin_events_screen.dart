import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/events_provider.dart';
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
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.events.isEmpty) {
      return Center(child: Text(provider.error!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: FilledButton.icon(
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Создать мероприятие'),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<EventsProvider>().loadEvents(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Название')),
                        DataColumn(label: Text('Дата')),
                        DataColumn(label: Text('Место')),
                        DataColumn(label: Text('Участники')),
                        DataColumn(label: Text('Тип')),
                        DataColumn(label: Text('Действия')),
                      ],
                      rows: provider.events.map((event) {
                        final dateText =
                            DateFormat('dd.MM.yyyy HH:mm').format(event.eventDate);
                        return DataRow(
                          cells: [
                            DataCell(Text(event.title)),
                            DataCell(Text(dateText)),
                            DataCell(Text(event.location)),
                            DataCell(
                              Text('${event.currentParticipants}/${event.maxParticipants}'),
                            ),
                            DataCell(Text(event.type)),
                            DataCell(
                              Wrap(
                                spacing: 4,
                                children: [
                                  if (event.type == 'APPROVAL')
                                    TextButton(
                                      onPressed: () => widget.onApplications(event),
                                      child: const Text('Заявки'),
                                    ),
                                  TextButton(
                                    onPressed: () => widget.onAttendance(event),
                                    child: const Text('Статистика'),
                                  ),
                                  TextButton(
                                    onPressed: () => widget.onEdit(event),
                                    child: const Text('Редактировать'),
                                  ),
                                  TextButton(
                                    onPressed: () => _deleteEvent(event),
                                    child: const Text('Удалить'),
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
