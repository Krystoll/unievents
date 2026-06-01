package com.unievents.model;

import org.hibernate.annotations.ColumnDefault;

import com.unievents.model.enums.EventType;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.*;

@Entity
@Table(name = "events")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private LocalDateTime eventDate;

    /** Длительность мероприятия в минутах (в БД nullable для совместимости со старыми записями). */
    @Builder.Default
    @ColumnDefault("60")
    @Column(columnDefinition = "integer default 60")
    private Integer durationMinutes = 60;

    private String location;

    @Column(nullable = false)
    private Integer maxParticipants;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EventType type;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    private User createdBy;

    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "event", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<EventField> fields = new ArrayList<>();

    @PrePersist
    public void prePersist() {
        createdAt = LocalDateTime.now();
        if (durationMinutes == null) {
            durationMinutes = 60;
        }
    }

    @PreUpdate
    public void preUpdate() {
        if (durationMinutes == null) {
            durationMinutes = 60;
        }
    }
}