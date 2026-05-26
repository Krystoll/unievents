package com.unievents.service;

import com.unievents.dto.request.SubmitGameScoreRequest;
import com.unievents.dto.response.GameScoreResponse;
import com.unievents.dto.response.GameTypeStatsResponse;
import com.unievents.dto.response.LeaderboardEntryResponse;
import com.unievents.exception.BadRequestException;
import com.unievents.model.GameScore;
import com.unievents.model.User;
import com.unievents.model.enums.GameType;
import com.unievents.repository.GameScoreRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class GameScoreService {

    private static final int LEADERBOARD_LIMIT = 20;

    private final GameScoreRepository gameScoreRepository;

    @Transactional
    public GameScoreResponse submitScore(User user, SubmitGameScoreRequest req) {
        validate(req);

        GameScore saved = gameScoreRepository.save(GameScore.builder()
                .user(user)
                .gameType(req.gameType())
                .score(req.score())
                .durationMs(req.durationMs())
                .progress(req.progress())
                .completed(req.completed())
                .build());

        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<GameTypeStatsResponse> getMyStats(User user) {
        List<GameTypeStatsResponse> stats = new ArrayList<>();
        for (GameType type : GameType.values()) {
            stats.add(buildStats(user, type));
        }
        return stats;
    }

    @Transactional(readOnly = true)
    public List<LeaderboardEntryResponse> getLeaderboard(GameType gameType) {
        List<GameScore> scores = gameScoreRepository.findLeaderboard(gameType);

        // Лучший результат каждого пользователя
        var bestByUser = new java.util.LinkedHashMap<java.util.UUID, GameScore>();
        for (GameScore score : scores) {
            var userId = score.getUser().getId();
            if (!bestByUser.containsKey(userId)) {
                bestByUser.put(userId, score);
            }
        }

        List<GameScore> ranked = bestByUser.values().stream()
                .sorted(Comparator
                        .comparingInt(GameScore::getScore).reversed()
                        .thenComparingLong(GameScore::getDurationMs)
                        .thenComparing(GameScore::getPlayedAt))
                .limit(LEADERBOARD_LIMIT)
                .toList();

        List<LeaderboardEntryResponse> result = new ArrayList<>();
        for (int i = 0; i < ranked.size(); i++) {
            GameScore gs = ranked.get(i);
            result.add(new LeaderboardEntryResponse(
                    i + 1,
                    gs.getUser().getId(),
                    gs.getUser().getName(),
                    gs.getGameType(),
                    gs.getScore(),
                    gs.getDurationMs(),
                    gs.getProgress(),
                    Boolean.TRUE.equals(gs.getCompleted()),
                    gs.getPlayedAt()
            ));
        }
        return result;
    }

    private GameTypeStatsResponse buildStats(User user, GameType type) {
        long played = gameScoreRepository.countByUserAndGameType(user, type);
        var best = gameScoreRepository.findTopByUserAndGameTypeOrderByScoreDesc(user, type);
        double avg = gameScoreRepository.averageScoreByUserAndGameType(user, type);
        var recent = gameScoreRepository.findByUserAndGameTypeOrderByPlayedAtDesc(user, type);

        int bestScore = best.map(GameScore::getScore).orElse(0);
        int lastScore = recent.isEmpty() ? 0 : recent.get(0).getScore();
        Long lastDuration = recent.isEmpty() ? null : recent.get(0).getDurationMs();
        Integer lastProgress = recent.isEmpty() ? null : recent.get(0).getProgress();
        Boolean lastCompleted = recent.isEmpty() ? null : recent.get(0).getCompleted();

        return new GameTypeStatsResponse(
                type, played, bestScore, avg, lastScore, lastDuration, lastProgress, lastCompleted
        );
    }

    private void validate(SubmitGameScoreRequest req) {
        if (req.gameType() == null) {
            throw new BadRequestException("Тип игры обязателен");
        }
        if (req.score() == null || req.score() < 0) {
            throw new BadRequestException("Некорректный счёт");
        }
        if (req.durationMs() == null || req.durationMs() < 0) {
            throw new BadRequestException("Некорректная длительность");
        }
        if (req.progress() == null || req.progress() < 0) {
            throw new BadRequestException("Некорректный прогресс");
        }
        if (req.completed() == null) {
            throw new BadRequestException("Флаг завершения обязателен");
        }
        if (req.score() > 1_000_000) {
            throw new BadRequestException("Слишком большой счёт");
        }
    }

    private GameScoreResponse toResponse(GameScore gs) {
        return new GameScoreResponse(
                gs.getId(),
                gs.getGameType(),
                gs.getScore(),
                gs.getDurationMs(),
                gs.getProgress(),
                gs.getCompleted(),
                gs.getPlayedAt()
        );
    }
}
