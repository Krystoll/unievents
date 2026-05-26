enum GameType {
  memory,
  simon,
  tap,
  pattern;

  static GameType fromApi(String value) {
    return GameType.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => GameType.memory,
    );
  }
}

extension GameTypeApi on GameType {
  String get apiValue => name.toUpperCase();

  String get title => switch (this) {
        GameType.memory => 'Запоминание пар',
        GameType.simon => 'Запомни и повтори',
        GameType.tap => 'Tap-the-Target',
        GameType.pattern => 'Блочный пазл',
      };
}
class GameTypeStats {
  const GameTypeStats({
    required this.gameType,
    required this.gamesPlayed,
    required this.bestScore,
    required this.averageScore,
    required this.lastScore,
    this.lastDurationMs,
    this.lastProgress,
    this.lastCompleted,
  });

  final GameType gameType;
  final int gamesPlayed;
  final int bestScore;
  final double averageScore;
  final int lastScore;
  final int? lastDurationMs;
  final int? lastProgress;
  final bool? lastCompleted;

  factory GameTypeStats.fromJson(Map<String, dynamic> json) {
    return GameTypeStats(
      gameType: GameType.fromApi(json['gameType'] as String),
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
      lastScore: (json['lastScore'] as num?)?.toInt() ?? 0,
      lastDurationMs: (json['lastDurationMs'] as num?)?.toInt(),
      lastProgress: (json['lastProgress'] as num?)?.toInt(),
      lastCompleted: json['lastCompleted'] as bool?,
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    required this.gameType,
    required this.score,
    required this.durationMs,
    required this.progress,
    required this.completed,
    required this.playedAt,
  });

  final int rank;
  final String userId;
  final String userName;
  final GameType gameType;
  final int score;
  final int durationMs;
  final int progress;
  final bool completed;
  final String? playedAt;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['userId']?.toString() ?? '',
      userName: json['userName'] as String? ?? '—',
      gameType: GameType.fromApi(json['gameType'] as String),
      score: (json['score'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
      playedAt: json['playedAt']?.toString(),
    );
  }
}

class SubmitGameScorePayload {
  const SubmitGameScorePayload({
    required this.gameType,
    required this.score,
    required this.durationMs,
    required this.progress,
    required this.completed,
  });

  final GameType gameType;
  final int score;
  final int durationMs;
  final int progress;
  final bool completed;

  Map<String, dynamic> toJson() => {
        'gameType': gameType.apiValue,
        'score': score,
        'durationMs': durationMs,
        'progress': progress,
        'completed': completed,
      };
}
