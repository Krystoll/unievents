import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/events_provider.dart';
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
      return Center(
        child: provider.error == null ? const CircularProgressIndicator() : Text(provider.error!),
      );
    }
    final progress = data.totalRegistered == 0 ? 0.0 : data.attended / data.totalRegistered;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Явка: ${data.attended}/${data.totalRegistered} (${data.attendanceRate.toStringAsFixed(1)}%)'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _finalizeEvent,
          child: const Text('Завершить мероприятие'),
        ),
        const SizedBox(height: 16),
        Text('Пришедшие', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...data.attendees.map(
          (a) => ListTile(
            dense: true,
            title: Text(a.name),
            subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(a.attendedAt)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Не явились', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...data.noShowList.map((n) => ListTile(dense: true, title: Text(n.name))),
      ],
    );
  }
}
