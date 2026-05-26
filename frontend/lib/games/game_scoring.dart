import 'dart:math';

/// Формулы итоговых очков для соревновательной таблицы.
abstract final class GameScoring {
  static const memoryMaxLevels = 11;
  static const simonMaxRounds = 10;
  static const patternStartingMoves = 20;
  static const patternMovesPerLine = 3;
  static const tapDurationSec = 60;

  /// Memory: уровни + пары + бонус за скорость при полном прохождении.
  static int memoryFinal({
    required int levelsCompleted,
    required int pairPoints,
    required int elapsedMs,
    required bool allLevelsCompleted,
  }) {
    var total = levelsCompleted * 400 + pairPoints;
    if (allLevelsCompleted) {
      total += max(0, (900000 - elapsedMs) ~/ 100);
    }
    return total;
  }

  /// Simon: раунды + очки за раунды + бонус за скорость при победе.
  static int simonFinal({
    required int roundsCompleted,
    required int roundPoints,
    required int elapsedMs,
    required bool allRoundsCompleted,
  }) {
    var total = roundsCompleted * 200 + roundPoints;
    if (allRoundsCompleted) {
      total += max(0, (600000 - elapsedMs) ~/ 100);
    }
    return total;
  }

  /// Tap: очки за скорость реакции (мс) с учётом комбо.
  static int tapPointsForReaction(int reactionMs, int combo) {
    final base = switch (reactionMs) {
      < 250 => 18,
      < 400 => 14,
      < 600 => 10,
      < 900 => 7,
      < 1200 => 4,
      _ => 2,
    };
    final multiplier = 1 + combo ~/ 5;
    return base * multiplier;
  }

  /// Pattern: очки за линии + бонус за каждое размещение.
  static int patternFinal({
    required int lineScore,
    required int placements,
  }) {
    return lineScore + placements * 10;
  }

  /// Бонус ходов за очищенные линии (1 линия = +3 хода).
  static int patternMovesForLines(int linesCleared) {
    return linesCleared * patternMovesPerLine;
  }

  static String formatDuration(int ms) {
    final sec = (ms / 1000).floor();
    final min = sec ~/ 60;
    final rem = sec % 60;
    if (min > 0) return '${min}м ${rem}с';
    return '${rem}с';
  }
}
