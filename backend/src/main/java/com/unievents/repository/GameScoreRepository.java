package com.unievents.repository;

import com.unievents.model.Event;
import com.unievents.model.GameScore;
import com.unievents.model.User;
import com.unievents.model.enums.GameType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface GameScoreRepository extends JpaRepository<GameScore, UUID> {

    List<GameScore> findByUserOrderByPlayedAtDesc(User user);

    @Query("""
            SELECT gs FROM GameScore gs
            WHERE gs.user = :user AND gs.gameType = :gameType AND gs.event IS NULL
            ORDER BY gs.playedAt DESC
            """)
    List<GameScore> findGlobalByUserAndGameTypeOrderByPlayedAtDesc(
            @Param("user") User user, @Param("gameType") GameType gameType);

    Optional<GameScore> findFirstByUserAndGameTypeAndEventIsNullOrderByScoreDescDurationMsAscPlayedAtAsc(
            User user, GameType gameType);

    @Query("""
            SELECT gs FROM GameScore gs
            JOIN FETCH gs.user u
            WHERE gs.gameType = :gameType AND gs.event IS NULL
            ORDER BY gs.score DESC, gs.durationMs ASC, gs.playedAt ASC
            """)
    List<GameScore> findGlobalLeaderboard(@Param("gameType") GameType gameType);

    @Query("""
            SELECT gs FROM GameScore gs
            JOIN FETCH gs.user u
            WHERE gs.gameType = :gameType AND gs.event = :event
            ORDER BY gs.score DESC, gs.durationMs ASC, gs.playedAt ASC
            """)
    List<GameScore> findEventLeaderboard(@Param("gameType") GameType gameType, @Param("event") Event event);

    @Query("""
            SELECT COUNT(gs) FROM GameScore gs
            WHERE gs.user = :user AND gs.gameType = :gameType AND gs.event IS NULL
            """)
    long countGlobalByUserAndGameType(@Param("user") User user, @Param("gameType") GameType gameType);

    @Query("""
            SELECT COALESCE(AVG(gs.score), 0) FROM GameScore gs
            WHERE gs.user = :user AND gs.gameType = :gameType AND gs.event IS NULL
            """)
    double averageGlobalScoreByUserAndGameType(@Param("user") User user, @Param("gameType") GameType gameType);
}
