package com.unievents.controller;

import com.unievents.dto.request.EventRequest;
import com.unievents.dto.response.EventResponse;
import com.unievents.model.User;
import com.unievents.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    @GetMapping
    public List<EventResponse> getAll() {
        return eventService.getAll();
    }

    @GetMapping("/{id}")
    public EventResponse getById(@PathVariable UUID id) {
        return eventService.getById(id);
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<EventResponse> create(
            @RequestBody EventRequest req,
            @AuthenticationPrincipal User admin) {
        return ResponseEntity.status(201).body(eventService.create(req, admin));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public EventResponse update(@PathVariable UUID id, @RequestBody EventRequest req) {
        return eventService.update(id, req);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        eventService.delete(id);
        return ResponseEntity.noContent().build();
    }
}