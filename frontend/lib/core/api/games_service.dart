import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../../models/game_stats.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class GamesService {
  final Dio _dio = ApiClient.instance.dio;

  Future<void> submitScore(SubmitGameScorePayload payload) async {
    if (AppConfig.useMockData) return;
    await _dio.post(ApiEndpoints.submitGameScore, data: payload.toJson());
  }

  Future<List<GameTypeStats>> getMyStats() async {
    if (AppConfig.useMockData) {
      return GameType.values
          .map(
            (t) => GameTypeStats(
              gameType: t,
              gamesPlayed: 0,
              bestScore: 0,
              averageScore: 0,
              lastScore: 0,
            ),
          )
          .toList();
    }
    final response = await _dio.get(ApiEndpoints.myGameStats);
    final list = response.data as List<dynamic>;
    return list.map((e) => GameTypeStats.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LeaderboardEntry>> getLeaderboard(GameType gameType) async {
    if (AppConfig.useMockData) return [];
    final response = await _dio.get(ApiEndpoints.gameLeaderboard(gameType.apiValue));
    final list = response.data as List<dynamic>;
    return list.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LeaderboardEntry>> getEventLeaderboard({
    required String eventId,
    required GameType gameType,
  }) async {
    if (AppConfig.useMockData) return [];
    final response = await _dio.get(
      ApiEndpoints.eventGameLeaderboard(eventId, gameType.apiValue),
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
