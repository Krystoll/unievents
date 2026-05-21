package com.unievents.controller;

import com.unievents.exception.NotFoundException;
import com.unievents.model.*;
import com.unievents.model.enums.RegistrationStatus;
import com.unievents.repository.*;
import com.unievents.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final EventService eventService;
    private final RegistrationService registrationService;
    private final RegistrationRepository registrationRepository;
    private final ApplicationAnswerRepository answerRepository;

    // ── Список заявок на мероприятие ───────────────
    @GetMapping("/api/events/{id}/registrations")
    public ResponseEntity<?> getRegistrations(@PathVariable UUID id) {
        var event = eventService.findById(id);

        var registered = registrationRepository
                .findByEventAndStatus(event, RegistrationStatus.REGISTERED)
                .stream().map(r -> buildRegEntry(r, false, false)).collect(Collectors.toList());

        var waitlist = registrationRepository
                .findByEventAndStatusOrderByQueuePositionAsc(event, RegistrationStatus.WAITLISTED)
                .stream().map(r -> buildRegEntry(r, true, false)).collect(Collectors.toList());

        var pending = registrationRepository
                .findByEventAndStatus(event, RegistrationStatus.PENDING)
                .stream().map(r -> buildRegEntry(r, false, true)).collect(Collectors.toList());

        return ResponseEntity.ok(Map.of(
                "registered", registered,
                "waitlist", waitlist,
                "pending", pending));
    }

    // ── Одобрить заявку ────────────────────────────
    @PostMapping("/api/events/{eventId}/registrations/{regId}/approve")
    public ResponseEntity<?> approve(@PathVariable UUID eventId,
                                     @PathVariable UUID regId) {
        Registration reg = registrationRepository.findById(regId)
                .orElseThrow(() -> new NotFoundException("Регистрация не найдена"));
        registrationService.approve(reg);
        return ResponseEntity.ok(Map.of("message", "Заявка одобрена"));
    }

    // ── Отклонить заявку ───────────────────────────
    @PostMapping("/api/events/{eventId}/registrations/{regId}/reject")
    public ResponseEntity<?> reject(@PathVariable UUID eventId,
                                    @PathVariable UUID regId) {
        Registration reg = registrationRepository.findById(regId)
                .orElseThrow(() -> new NotFoundException("Регистрация не найдена"));
        registrationService.reject(reg);
        return ResponseEntity.ok(Map.of("message", "Заявка отклонена"));
    }

    // ── Статистика посещаемости ────────────────────
    @GetMapping("/api/events/{id}/attendance")
    public ResponseEntity<?> attendance(@PathVariable UUID id) {
        var event = eventService.findById(id);
        var attended = registrationRepository.findByEventAndStatus(event, RegistrationStatus.ATTENDED);
        var noShow   = registrationRepository.findByEventAndStatus(event, RegistrationStatus.NO_SHOW);
        var registered = registrationRepository.findByEventAndStatus(event, RegistrationStatus.REGISTERED);

        int total = attended.size() + noShow.size() + registered.size();
        double rate = total == 0 ? 0 : Math.round(attended.size() * 1000.0 / total) / 10.0;

        return ResponseEntity.ok(Map.of(
                "totalRegistered", total,
                "attended", attended.size(),
                "noShow", noShow.size(),
                "attendanceRate", rate,
                "attendees", attended.stream().map(r -> Map.of(
                        "userId", r.getUser().getId(),
                        "name", r.getUser().getName(),
                        "attendedAt", r.getAttendedAt()
                )).collect(Collectors.toList()),
                "noShowList", noShow.stream().map(r -> Map.of(
                        "userId", r.getUser().getId(),
                        "name", r.getUser().getName()
                )).collect(Collectors.toList())
        ));
    }

    // ── Финализировать мероприятие ─────────────────
    @PostMapping("/api/events/{id}/finalize")
    public ResponseEntity<?> finalize(@PathVariable UUID id) {
        var event = eventService.findById(id);
        List<Registration> stillRegistered =
                registrationRepository.findByEventAndStatus(event, RegistrationStatus.REGISTERED);

        for (Registration reg : stillRegistered) {
            reg.setStatus(RegistrationStatus.NO_SHOW);
            registrationRepository.save(reg);
            User u = reg.getUser();
            u.setNoShowCount(u.getNoShowCount() + 1);
            int total = u.getAttendedCount() + u.getNoShowCount();
            u.setReliabilityScore(total == 0 ? 100.0f :
                    (u.getAttendedCount() * 100.0f) / total);
        }

        return ResponseEntity.ok(Map.of(
                "message", "Мероприятие завершено. Обновлено записей: "
                        + stillRegistered.size()));
    }

    // ── helper ────────────────────────────────────
    private Map<String, Object> buildRegEntry(Registration r,
                                              boolean withQueue,
                                              boolean withAnswers) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("registrationId", r.getId());
        map.put("userId", r.getUser().getId());
        map.put("name", r.getUser().getName());
        map.put("email", r.getUser().getEmail());
        map.put("reliabilityScore", r.getUser().getReliabilityScore());
        map.put("registeredAt", r.getRegisteredAt());
        if (withQueue) map.put("queuePosition", r.getQueuePosition());
        if (withAnswers) {
            var answers = answerRepository.findByRegistration(r).stream()
                    .map(a -> Map.of("fieldName", a.getField().getFieldName(),
                            "answer", a.getAnswer()))
                    .collect(Collectors.toList());
            map.put("answers", answers);
        }
        return map;
    }
}