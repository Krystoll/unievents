package com.unievents.repository;

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

    List<GameScore> findByUserAndGameTypeOrderByPlayedAtDesc(User user, GameType gameType);

    Optional<GameScore> findTopByUserAndGameTypeOrderByScoreDesc(User user, GameType gameType);

    @Query("""
            SELECT gs FROM GameScore gs
            JOIN FETCH gs.user u
            WHERE gs.gameType = :gameType
            ORDER BY gs.score DESC, gs.durationMs ASC, gs.playedAt ASC
            """)
    List<GameScore> findLeaderboard(@Param("gameType") GameType gameType);

    long countByUserAndGameType(User user, GameType gameType);

    @Query("SELECT COALESCE(AVG(gs.score), 0) FROM GameScore gs WHERE gs.user = :user AND gs.gameType = :gameType")
    double averageScoreByUserAndGameType(@Param("user") User user, @Param("gameType") GameType gameType);
}
