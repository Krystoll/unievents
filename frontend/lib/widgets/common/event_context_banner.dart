import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event.dart';

/// Заголовок выбранного мероприятия в админ-вкладках.
class EventContextBanner extends StatelessWidget {
  const EventContextBanner({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd.MM.yyyy, HH:mm').format(event.eventDate);
    final typeLabel = event.type == 'APPROVAL' ? 'По заявке' : 'Свободная запись';

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.cardAccent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_rounded, color: Colors.white, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateText • $typeLabel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
