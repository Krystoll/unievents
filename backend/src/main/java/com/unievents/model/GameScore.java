package com.unievents.model;

import com.unievents.model.enums.GameType;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "game_scores")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GameScore {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private GameType gameType;

    @Column(nullable = false)
    private Integer score;

    @Column(nullable = false)
    private Long durationMs;

    /** Уровни / раунды / ходы — зависит от игры. */
    @Column(nullable = false)
    private Integer progress;

    @Column(nullable = false)
    private Boolean completed;

    private LocalDateTime playedAt;

    @PrePersist
    public void prePersist() {
        playedAt = LocalDateTime.now();
    }
}
