import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/status_chip.dart';

class MyRegistrationsScreen extends StatelessWidget {
  const MyRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    if (provider.isLoadingRegistrations) {
      return const LoadingView();
    }

    if (provider.error != null && provider.myRegistrations.isEmpty) {
      return ErrorState(
        message: provider.error!,
        onRetry: () => context.read<EventsProvider>().loadMyRegistrations(),
      );
    }

    if (provider.myRegistrations.isEmpty) {
      return const EmptyState(
        icon: Icons.bookmark_border_rounded,
        message: 'У вас пока нет записей на мероприятия',
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<EventsProvider>().loadMyRegistrations(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: provider.myRegistrations.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final registration = provider.myRegistrations[index];
          final event = registration.event;
          final dateText = DateFormat('dd.MM.yyyy, HH:mm').format(event.eventDate);
          final canCancel =
              registration.status == 'REGISTERED' || registration.status == 'WAITLISTED';

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(child: Text(dateText, style: Theme.of(context).textTheme.bodyMedium)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(event.location, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StatusChip(
                    status: registration.status,
                    queuePosition: registration.queuePosition,
                  ),
                  if (canCancel) ...[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final msg = await context
                              .read<EventsProvider>()
                              .cancelRegistration(event.id);
                          if (context.mounted && msg != null) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(msg)));
                          }
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Отменить'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
