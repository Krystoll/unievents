package com.unievents.service;

import com.unievents.dto.request.EventRequest;
import com.unievents.dto.response.EventResponse;
import com.unievents.exception.NotFoundException;
import com.unievents.model.*;
import com.unievents.model.enums.RegistrationStatus;
import com.unievents.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EventService {

    private final EventRepository eventRepository;
    private final EventFieldRepository fieldRepository;
    private final RegistrationRepository registrationRepository;

    public List<EventResponse> getAll() {
        return eventRepository.findAll().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public EventResponse getById(UUID id) {
        Event event = findById(id);
        return toResponseWithFields(event);
    }

    @Transactional
    public EventResponse create(EventRequest req, User admin) {
        Event event = Event.builder()
                .title(req.title())
                .description(req.description())
                .eventDate(req.eventDate())
                .location(req.location())
                .maxParticipants(req.maxParticipants())
                .type(req.type())
                .createdBy(admin)
                .build();
        eventRepository.save(event);

        if (req.fields() != null) {
            for (var f : req.fields()) {
                EventField field = EventField.builder()
                        .event(event)
                        .fieldName(f.fieldName())
                        .required(Boolean.TRUE.equals(f.required()))
                        .build();
                fieldRepository.save(field);
            }
        }
        return toResponseWithFields(eventRepository.findById(event.getId()).orElseThrow());
    }

    @Transactional
    public EventResponse update(UUID id, EventRequest req) {
        Event event = findById(id);
        event.setTitle(req.title());
        event.setDescription(req.description());
        event.setEventDate(req.eventDate());
        event.setLocation(req.location());
        event.setMaxParticipants(req.maxParticipants());
        event.setType(req.type());

        // Обновить поля: удалить старые, добавить новые
        fieldRepository.deleteAll(fieldRepository.findByEvent(event));
        if (req.fields() != null) {
            for (var f : req.fields()) {
                EventField field = EventField.builder()
                        .event(event)
                        .fieldName(f.fieldName())
                        .required(Boolean.TRUE.equals(f.required()))
                        .build();
                fieldRepository.save(field);
            }
        }
        return toResponseWithFields(eventRepository.save(event));
    }

    @Transactional
    public void delete(UUID id) {
        Event event = findById(id);
        eventRepository.delete(event);
    }

    // ── helpers ──────────────────────────────────────
    public Event findById(UUID id) {
        return eventRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Мероприятие не найдено"));
    }

    private EventResponse toResponse(Event e) {
        int current = (int) registrationRepository
                .countByEventAndStatus(e, RegistrationStatus.REGISTERED);
        int waitlist = (int) registrationRepository
                .countByEventAndStatus(e, RegistrationStatus.WAITLISTED);
        return new EventResponse(e.getId(), e.getTitle(), e.getDescription(),
                e.getEventDate(), e.getLocation(), e.getMaxParticipants(),
                current, waitlist, e.getType(), List.of());
    }

    private EventResponse toResponseWithFields(Event e) {
        int current = (int) registrationRepository
                .countByEventAndStatus(e, RegistrationStatus.REGISTERED);
        int waitlist = (int) registrationRepository
                .countByEventAndStatus(e, RegistrationStatus.WAITLISTED);
        List<EventResponse.FieldDto> fields = fieldRepository.findByEvent(e).stream()
                .map(f -> new EventResponse.FieldDto(f.getId(), f.getFieldName(), f.getRequired()))
                .collect(Collectors.toList());
        return new EventResponse(e.getId(), e.getTitle(), e.getDescription(),
                e.getEventDate(), e.getLocation(), e.getMaxParticipants(),
                current, waitlist, e.getType(), fields);
    }
}