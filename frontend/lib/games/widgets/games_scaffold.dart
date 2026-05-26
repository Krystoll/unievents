import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import 'game_exit_guard.dart';
import 'games_layout.dart';

class GamesScaffold extends StatelessWidget {
  const GamesScaffold({
    super.key,
    required this.title,
    required this.child,
    this.gameInProgress = false,
    this.scoreSubmitted = false,
  });

  final String title;
  final Widget child;
  final bool gameInProgress;
  final bool scoreSubmitted;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactGameScreen(context);
    return GameExitGuard(
      gameInProgress: gameInProgress,
      scoreSubmitted: scoreSubmitted,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              if (gameInProgress && !scoreSubmitted) {
                if (!await confirmGameExit(context) || !context.mounted) return;
              }
              if (context.mounted) context.pop();
            },
          ),
          title: Text(title),
          centerTitle: compact,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.sm : AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
