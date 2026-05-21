import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.queuePosition,
  });

  final String status;
  final int? queuePosition;

  @override
  Widget build(BuildContext context) {
    final cfg = _config(status, queuePosition);
    return Chip(
      label: Text(cfg.$1),
      backgroundColor: cfg.$2.withValues(alpha: 0.15),
      side: BorderSide(color: cfg.$2),
    );
  }

  (String, Color) _config(String status, int? queuePosition) {
    switch (status) {
      case 'REGISTERED':
        return ('Записан', Colors.green);
      case 'WAITLISTED':
        return ('В очереди #${queuePosition ?? '-'}', Colors.amber);
      case 'PENDING':
        return ('На рассмотрении', Colors.blue);
      case 'REJECTED':
        return ('Отклонено', Colors.red);
      case 'ATTENDED':
        return ('Посетил', Colors.green);
      case 'NO_SHOW':
        return ('Не явился', Colors.grey);
      default:
        return (status, Colors.grey);
    }
  }
}
