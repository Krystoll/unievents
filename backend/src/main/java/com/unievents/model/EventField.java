package com.unievents.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;

@Entity
@Table(name = "event_fields")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EventField {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    @Column(nullable = false)
    private String fieldName;

    @Column(nullable = false)
    private Boolean required = false;
}