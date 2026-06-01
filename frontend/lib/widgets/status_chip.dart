import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cfg.$2.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.$2.withValues(alpha: 0.5)),
      ),
      child: Text(
        cfg.$1,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cfg.$2,
              fontSize: 12,
            ),
      ),
    );
  }

  (String, Color) _config(String status, int? queuePosition) {
    switch (status) {
      case 'REGISTERED':
        return ('Записан', AppColors.success);
      case 'WAITLISTED':
        return ('В очереди #${queuePosition ?? '-'}', AppColors.warning);
      case 'PENDING':
        return ('На рассмотрении', AppColors.info);
      case 'REJECTED':
        return ('Отклонено', AppColors.error);
      case 'ATTENDED':
        return ('Посетил', AppColors.success);
      case 'NO_SHOW':
        return ('Не явился', AppColors.textSecondary);
      case 'CANCELLED':
        return ('Отменено', AppColors.textSecondary);
      default:
        return (status, AppColors.textSecondary);
    }
  }
}
