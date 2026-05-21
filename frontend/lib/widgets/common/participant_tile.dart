import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../reliability_badge.dart';

class ParticipantTile extends StatelessWidget {
  const ParticipantTile({
    super.key,
    required this.name,
    required this.email,
    this.subtitle,
    this.reliabilityScore,
    this.trailing,
    this.actions,
  });

  final String name;
  final String email;
  final String? subtitle;
  final double? reliabilityScore;
  final Widget? trailing;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(email, style: Theme.of(context).textTheme.bodyMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (reliabilityScore != null) ...[
              const SizedBox(height: AppSpacing.md),
              ReliabilityBadge(score: reliabilityScore!),
            ],
            if (actions != null) ...[
              const SizedBox(height: AppSpacing.md),
              actions!,
            ],
          ],
        ),
      ),
    );
  }
}
