import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/event.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onDetails,
  });

  final Event event;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd.MM.yyyy, HH:mm').format(event.eventDate);
    final fillRatio = event.maxParticipants > 0
        ? event.currentParticipants / event.maxParticipants
        : 0.0;
    final isFull = event.currentParticipants >= event.maxParticipants;
    final typeLabel = event.type == 'APPROVAL' ? 'По заявке' : 'Свободная запись';

    return Card(
      clipBehavior: Clip.antiAlias,
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
                      gradient: AppColors.cardAccent,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(Icons.event_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          typeLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _MetaLine(icon: Icons.calendar_today_outlined, text: dateText),
              const SizedBox(height: 6),
              _MetaLine(icon: Icons.place_outlined, text: event.location),
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
