package com.unievents.controller;

import com.unievents.dto.request.EventRequest;
import com.unievents.dto.response.EventResponse;
import com.unievents.model.User;
import com.unievents.service.EventService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

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
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasRole('ADMIN')")
    public EventResponse create(
            @Valid @RequestBody EventRequest request,
            @AuthenticationPrincipal User admin
    ) {
        return eventService.create(request, admin);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public EventResponse update(
            @PathVariable UUID id,
            @Valid @RequestBody EventRequest request
    ) {
        return eventService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasRole('ADMIN')")
    public void delete(@PathVariable UUID id) {
        eventService.delete(id);
    }
}
