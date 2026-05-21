package com.unievents.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;

@Entity
@Table(name = "application_answers")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ApplicationAnswer {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "registration_id", nullable = false)
    private Registration registration;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "field_id", nullable = false)
    private EventField field;

    @Column(columnDefinition = "TEXT")
    private String answer;
}