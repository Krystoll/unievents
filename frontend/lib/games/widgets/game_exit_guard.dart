import 'package:flutter/material.dart';
/// Диалог при выходе из незавершённой игровой сессии.
Future<bool> confirmGameExit(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Выйти из игры?'),
      content: const Text(
        'Сессия ещё не завершена. Если выйти сейчас, прогресс и очки не будут сохранены.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Остаться')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти')),
      ],
    ),
  );
  return result ?? false;
}

/// Обёртка для системной кнопки «назад» и жеста pop.
class GameExitGuard extends StatelessWidget {
  const GameExitGuard({
    super.key,
    required this.gameInProgress,
    required this.scoreSubmitted,
    required this.child,
  });

  final bool gameInProgress;
  final bool scoreSubmitted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !gameInProgress || scoreSubmitted,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await confirmGameExit(context) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
