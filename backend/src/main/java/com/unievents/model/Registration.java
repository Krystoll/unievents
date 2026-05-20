package com.unievents.model;

import com.unievents.model.enums.RegistrationStatus;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "registrations")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Registration {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RegistrationStatus status;

    private Integer queuePosition;       // только для WAITLISTED

    private LocalDateTime registeredAt;
    private LocalDateTime attendedAt;    // заполняется при сканировании QR

    @PrePersist
    public void prePersist() {
        registeredAt = LocalDateTime.now();
    }
}