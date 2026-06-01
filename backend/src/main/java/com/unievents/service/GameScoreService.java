package com.unievents.service;

import com.unievents.dto.request.SubmitGameScoreRequest;
import com.unievents.dto.response.GameScoreResponse;
import com.unievents.dto.response.GameTypeStatsResponse;
import com.unievents.dto.response.LeaderboardEntryResponse;
import com.unievents.exception.BadRequestException;
import com.unievents.exception.NotFoundException;
import com.unievents.model.Event;
import com.unievents.model.GameScore;
import com.unievents.model.Registration;
import com.unievents.model.User;
import com.unievents.model.enums.GameType;
import com.unievents.model.enums.RegistrationStatus;
import com.unievents.repository.EventRepository;
import com.unievents.repository.GameScoreRepository;
import com.unievents.repository.RegistrationRepository;
import com.unievents.util.EventTimeUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GameScoreService {

    private static final int LEADERBOARD_LIMIT = 20;

    private final GameScoreRepository gameScoreRepository;
    private final EventRepository eventRepository;
    private final RegistrationRepository registrationRepository;

    @Transactional
    public GameScoreResponse submitScore(User user, SubmitGameScoreRequest req) {
        validate(req);

        Event event = null;
        if (req.eventId() != null) {
            event = eventRepository.findById(req.eventId())
                    .orElseThrow(() -> new NotFoundException("Мероприятие не найдено"));
            EventTimeUtil.ensureGamesWindow(event);

            Registration reg = registrationRepository.findByUserAndEvent(user, event)
                    .orElseThrow(() -> new BadRequestException("Вы не записаны на это мероприятие"));
            if (reg.getStatus() != RegistrationStatus.ATTENDED) {
                throw new BadRequestException("Сначала пройдите регистрацию на входе (QR-код)");
            }
        }

        GameScore saved = gameScoreRepository.save(GameScore.builder()
                .user(user)
                .event(event)
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
            stats.add(buildGlobalStats(user, type));
        }
        return stats;
    }

    @Transactional(readOnly = true)
    public List<LeaderboardEntryResponse> getLeaderboard(GameType gameType) {
        return buildLeaderboard(gameScoreRepository.findGlobalLeaderboard(gameType));
    }

    @Transactional(readOnly = true)
    public List<LeaderboardEntryResponse> getEventLeaderboard(UUID eventId, GameType gameType) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new NotFoundException("Мероприятие не найдено"));
        return buildLeaderboard(gameScoreRepository.findEventLeaderboard(gameType, event));
    }

    private List<LeaderboardEntryResponse> buildLeaderboard(List<GameScore> scores) {
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

    private GameTypeStatsResponse buildGlobalStats(User user, GameType type) {
        long played = gameScoreRepository.countGlobalByUserAndGameType(user, type);
        var best = gameScoreRepository
                .findFirstByUserAndGameTypeAndEventIsNullOrderByScoreDescDurationMsAscPlayedAtAsc(user, type);
        double avg = gameScoreRepository.averageGlobalScoreByUserAndGameType(user, type);
        var recent = gameScoreRepository.findGlobalByUserAndGameTypeOrderByPlayedAtDesc(user, type);

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
