import 'package:flutter/material.dart';

import '../../core/api/games_service.dart';
import '../../models/game_stats.dart';
import 'game_scoring.dart';

/// Отправка результата игровой сессии на сервер (один раз).
class GameSessionSubmitter {
  GameSessionSubmitter(this._service);

  final GamesService _service;
  bool submitted = false;

  Future<bool> submit(SubmitGameScorePayload payload) async {
    if (submitted) return true;
    try {
      await _service.submitScore(payload);
      submitted = true;
      return true;
    } catch (_) {
      return false;
    }
  }
}

Future<void> showScoreSavedSnackBar(BuildContext context, {required bool saved}) {
  return Future.microtask(() {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'Результат сохранён' : 'Не удалось сохранить результат'),
        duration: const Duration(seconds: 2),
      ),
    );
  });
}

String gameResultSubtitle({
  required int score,
  required int durationMs,
  required int progress,
  required bool completed,
}) {
  final time = GameScoring.formatDuration(durationMs);
  final status = completed ? 'завершено' : 'не завершено';
  return 'Очки: $score • Время: $time • Прогресс: $progress • $status';
}
