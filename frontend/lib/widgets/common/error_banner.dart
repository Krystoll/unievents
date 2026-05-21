import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: errorColor, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: errorColor))),
        ],
      ),
    );
  }
}
