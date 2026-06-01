import 'package:flutter/material.dart';

import '../core/event_time.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/event.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onDetails,
    this.isParticipating = false,
  });

  final Event event;
  final VoidCallback onDetails;
  final bool isParticipating;

  @override
  Widget build(BuildContext context) {
    final scheduleText = formatEventScheduleShort(event.eventDate, event.endDate);
    final fillRatio = event.maxParticipants > 0
        ? event.currentParticipants / event.maxParticipants
        : 0.0;
    final isFull = event.currentParticipants >= event.maxParticipants;
    final typeLabel = event.type == 'APPROVAL' ? 'По заявке' : 'Свободная запись';
    final isPast = event.isPast;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isPast ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
      child: InkWell(
        onTap: onDetails,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: isPast
                          ? LinearGradient(colors: [Colors.grey.shade500, Colors.grey.shade400])
                          : AppColors.cardAccent,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      isPast ? Icons.event_busy_outlined : Icons.event_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isPast ? AppColors.textSecondary : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              typeLabel,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            _Chip(label: event.phaseLabel, muted: isPast),
                            if (isParticipating) const _Chip(label: 'Участвую', highlight: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _MetaLine(icon: Icons.calendar_today_outlined, text: scheduleText),
              const SizedBox(height: 6),
              _MetaLine(icon: Icons.place_outlined, text: event.location),
              if (!isPast) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fillRatio.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.outline,
                          color: isFull ? AppColors.warning : AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${event.currentParticipants}/${event.maxParticipants}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isFull ? AppColors.warning : AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Подробнее'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.muted = false, this.highlight = false});

  final String label;
  final bool muted;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.outline.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: muted
                  ? AppColors.textSecondary
                  : highlight
                      ? AppColors.success
                      : AppColors.textSecondary,
            ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
