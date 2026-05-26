package com.unievents.service;

import com.unievents.dto.AnswerRequest;
import com.unievents.dto.MessageResponse;
import com.unievents.dto.RegisterEventRequest;
import com.unievents.dto.RegistrationResponse;
import com.unievents.exception.BadRequestException;
import com.unievents.model.Event;
import com.unievents.model.EventField;
import com.unievents.model.Registration;
import com.unievents.model.User;
import com.unievents.model.enums.EventType;
import com.unievents.model.enums.Role;
import com.unievents.model.enums.RegistrationStatus;
import com.unievents.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RegistrationServiceTest {

    @Mock
    private EventRepository eventRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private RegistrationRepository registrationRepository;
    @Mock
    private EventFieldRepository eventFieldRepository;
    @Mock
    private ApplicationAnswerRepository applicationAnswerRepository;

    @InjectMocks
    private RegistrationService registrationService;

    private UUID userId;
    private UUID eventId;
    private User user;
    private Event freeEvent;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        eventId = UUID.randomUUID();
        user = User.builder()
                .id(userId)
                .email("student@uni.ru")
                .name("Student")
                .role(Role.STUDENT)
                .password("password")
                .build();
        freeEvent = Event.builder()
                .id(eventId)
                .title("Free Event")
                .eventDate(LocalDateTime.now().plusDays(1))
                .maxParticipants(2)
                .type(EventType.FREE)
                .build();
    }

    @Test
    void registerFree_whenSpotAvailable_shouldRegisterUser() {
        when(eventRepository.findById(eventId)).thenReturn(Optional.of(freeEvent));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(registrationRepository.existsActiveRegistration(userId, eventId)).thenReturn(false);
        when(registrationRepository.countByEventIdAndStatus(eventId, RegistrationStatus.REGISTERED)).thenReturn(1L);
        when(registrationRepository.save(any(Registration.class))).thenAnswer(invocation -> invocation.getArgument(0));

        RegistrationResponse response = registrationService.register(userId, eventId, new RegisterEventRequest(List.of()));

        assertEquals(RegistrationStatus.REGISTERED, response.status());
        assertNull(response.queuePosition());
        assertEquals("Вы успешно записаны", response.message());
    }

    @Test
    void registerFree_whenNoSpots_shouldPutUserOnWaitlist() {
        when(eventRepository.findById(eventId)).thenReturn(Optional.of(freeEvent));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(registrationRepository.existsActiveRegistration(userId, eventId)).thenReturn(false);
        when(registrationRepository.countByEventIdAndStatus(eventId, RegistrationStatus.REGISTERED)).thenReturn(2L);
        when(registrationRepository.findMaxQueuePosition(eventId)).thenReturn(3);
        when(registrationRepository.save(any(Registration.class))).thenAnswer(invocation -> invocation.getArgument(0));

        RegistrationResponse response = registrationService.register(userId, eventId, new RegisterEventRequest(List.of()));

        assertEquals(RegistrationStatus.WAITLISTED, response.status());
        assertEquals(4, response.queuePosition());
        assertTrue(response.message().contains("очереди"));
    }

    @Test
    void registerApproval_shouldCreatePendingRegistration() {
        Event approvalEvent = Event.builder()
                .id(eventId)
                .title("Approval Event")
                .eventDate(LocalDateTime.now().plusDays(1))
                .maxParticipants(10)
                .type(EventType.APPROVAL)
                .build();
        UUID fieldId = UUID.randomUUID();
        EventField field = EventField.builder().id(fieldId).event(approvalEvent).fieldName("Курс").required(true).build();
        RegisterEventRequest request = new RegisterEventRequest(
                List.of(new AnswerRequest(fieldId, "3"))
        );

        when(eventRepository.findById(eventId)).thenReturn(Optional.of(approvalEvent));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(registrationRepository.existsActiveRegistration(userId, eventId)).thenReturn(false);
        when(eventFieldRepository.findByEvent_Id(eventId)).thenReturn(List.of(field));
        when(eventFieldRepository.findByIdAndEvent_Id(fieldId, eventId)).thenReturn(Optional.of(field));
        when(registrationRepository.save(any(Registration.class))).thenAnswer(invocation -> invocation.getArgument(0));

        RegistrationResponse response = registrationService.register(userId, eventId, request);

        assertEquals(RegistrationStatus.PENDING, response.status());
        assertEquals("Заявка отправлена. Ожидайте подтверждения", response.message());
        verify(applicationAnswerRepository).save(any());
    }

    @Test
    void register_whenDuplicateApplication_shouldThrowBadRequest() {
        when(eventRepository.findById(eventId)).thenReturn(Optional.of(freeEvent));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(registrationRepository.existsActiveRegistration(userId, eventId)).thenReturn(true);

        BadRequestException exception = assertThrows(
                BadRequestException.class,
                () -> registrationService.register(userId, eventId, new RegisterEventRequest(List.of()))
        );

        assertEquals("Вы уже подали заявку на это мероприятие", exception.getMessage());
    }

    @Test
    void cancelRegistered_shouldPromoteFirstFromWaitlist() {
        Registration registered = Registration.builder()
                .user(user)
                .event(freeEvent)
                .status(RegistrationStatus.REGISTERED)
                .build();
        Registration waitlisted = Registration.builder()
                .user(User.builder().id(UUID.randomUUID()).build())
                .event(freeEvent)
                .status(RegistrationStatus.WAITLISTED)
                .queuePosition(1)
                .build();

        when(registrationRepository.findActiveByUserIdAndEventId(userId, eventId))
                .thenReturn(Optional.of(registered));
        when(registrationRepository.findFirstByEventIdAndStatusOrderByQueuePositionAsc(
                eventId, RegistrationStatus.WAITLISTED
        )).thenReturn(Optional.of(waitlisted));
        when(registrationRepository.findByEventIdAndStatusOrderByQueuePositionAsc(
                eventId, RegistrationStatus.WAITLISTED
        )).thenReturn(List.of());

        MessageResponse response = registrationService.cancel(userId, eventId);

        assertEquals("Участие отменено", response.message());
        assertEquals(RegistrationStatus.REGISTERED, waitlisted.getStatus());
        assertNull(waitlisted.getQueuePosition());

        ArgumentCaptor<Registration> captor = ArgumentCaptor.forClass(Registration.class);
        verify(registrationRepository, atLeastOnce()).save(captor.capture());
        assertTrue(captor.getAllValues().stream()
                .anyMatch(r -> r.getStatus() == RegistrationStatus.CANCELLED));
    }
}
