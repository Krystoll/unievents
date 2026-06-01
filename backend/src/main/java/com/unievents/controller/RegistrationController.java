package com.unievents.controller;

import com.unievents.dto.request.RegisterEventRequest;
import com.unievents.dto.response.RegistrationResponse;
import com.unievents.model.User;
import com.unievents.model.Event;
import com.unievents.repository.RegistrationRepository;
import com.unievents.service.*;
import com.unievents.util.EventTimeUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;
import java.time.LocalDateTime;

@RestController
@RequiredArgsConstructor
public class RegistrationController {

    private final RegistrationService registrationService;
    private final EventService eventService;
    private final RegistrationRepository registrationRepository;

    // ── Записаться / подать заявку ──────────────────
    @PostMapping("/api/events/{id}/register")
    @PreAuthorize("hasRole('STUDENT')")
    public RegistrationResponse register(
            @PathVariable UUID id,
            @RequestBody(required = false) RegisterEventRequest req,
            @AuthenticationPrincipal User user) {
        return registrationService.register(user, eventService.findById(id), req);
    }

    // ── Отменить участие ────────────────────────────
    @DeleteMapping("/api/events/{id}/register")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<?> cancel(
            @PathVariable UUID id,
            @AuthenticationPrincipal User user) {
        registrationService.cancel(user, eventService.findById(id));
        return ResponseEntity.ok(Map.of("message", "Участие отменено"));
    }

    // ── Мои регистрации ─────────────────────────────
    @GetMapping("/api/users/me/registrations")
    @PreAuthorize("hasRole('STUDENT')")
    public List<?> myRegistrations(@AuthenticationPrincipal User user) {
        return registrationRepository.findByUserOrderByRegisteredAtDesc(user)
                .stream()
                .map(r -> {
                    Event event = r.getEvent();
                    LocalDateTime end = EventTimeUtil.endAt(event);
                    return Map.of(
                            "registrationId", r.getId(),
                            "event", Map.of(
                                    "id", event.getId(),
                                    "title", event.getTitle(),
                                    "eventDate", event.getEventDate(),
                                    "durationMinutes", event.getDurationMinutes(),
                                    "eventEndDate", end,
                                    "phase", EventTimeUtil.phase(event, LocalDateTime.now()),
                                    "location", event.getLocation() != null ? event.getLocation() : "",
                                    "type", event.getType()
                            ),
                            "status", r.getStatus(),
                            "queuePosition", r.getQueuePosition() != null
                                    ? r.getQueuePosition() : "null"
                    );
                })
                .collect(Collectors.toList());
    }
}