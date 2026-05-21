package com.unievents.service;

import com.unievents.dto.request.RegisterEventRequest;
import com.unievents.dto.response.RegistrationResponse;
import com.unievents.exception.*;
import com.unievents.model.*;
import com.unievents.model.enums.*;
import com.unievents.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RegistrationService {

    private final RegistrationRepository registrationRepository;
    private final ApplicationAnswerRepository answerRepository;
    private final EventFieldRepository fieldRepository;

    @Transactional
    public RegistrationResponse register(User user, Event event,
                                         RegisterEventRequest req) {
        // Проверка дублей
        registrationRepository.findByUserAndEvent(user, event).ifPresent(r -> {
            if (r.getStatus() != RegistrationStatus.CANCELLED &&
                    r.getStatus() != RegistrationStatus.REJECTED) {
                throw new BadRequestException("Вы уже подали заявку на это мероприятие");
            }
        });

        Registration reg = Registration.builder()
                .user(user)
                .event(event)
                .build();

        if (event.getType() == EventType.FREE) {
            long registered = registrationRepository
                    .countByEventAndStatus(event, RegistrationStatus.REGISTERED);

            if (registered < event.getMaxParticipants()) {
                reg.setStatus(RegistrationStatus.REGISTERED);
                registrationRepository.save(reg);
                return new RegistrationResponse(RegistrationStatus.REGISTERED, null,
                        "Вы успешно записаны");
            } else {
                int pos = registrationRepository.nextQueuePosition(event);
                reg.setStatus(RegistrationStatus.WAITLISTED);
                reg.setQueuePosition(pos);
                registrationRepository.save(reg);
                return new RegistrationResponse(RegistrationStatus.WAITLISTED, pos,
                        "Мест нет. Вы в очереди на позиции " + pos);
            }

        } else { // APPROVAL
            reg.setStatus(RegistrationStatus.PENDING);
            registrationRepository.save(reg);

            // Сохранить ответы на кастомные поля
            if (req != null && req.answers() != null) {
                for (var ans : req.answers()) {
                    EventField field = fieldRepository.findById(ans.fieldId())
                            .orElseThrow(() -> new NotFoundException("Поле не найдено"));
                    answerRepository.save(ApplicationAnswer.builder()
                            .registration(reg)
                            .field(field)
                            .answer(ans.answer())
                            .build());
                }
            }
            return new RegistrationResponse(RegistrationStatus.PENDING, null,
                    "Заявка отправлена. Ожидайте подтверждения");
        }
    }

    @Transactional
    public void cancel(User user, Event event) {
        Registration reg = registrationRepository.findByUserAndEvent(user, event)
                .orElseThrow(() -> new NotFoundException("Регистрация не найдена"));

        boolean wasRegistered = reg.getStatus() == RegistrationStatus.REGISTERED;
        reg.setStatus(RegistrationStatus.CANCELLED);
        registrationRepository.save(reg);

        // Передать место следующему из очереди
        if (wasRegistered) {
            promoteFromWaitlist(event);
        }
    }

    @Transactional
    public void approve(Registration reg) {
        long registered = registrationRepository
                .countByEventAndStatus(reg.getEvent(), RegistrationStatus.REGISTERED);

        if (registered < reg.getEvent().getMaxParticipants()) {
            reg.setStatus(RegistrationStatus.REGISTERED);
        } else {
            int pos = registrationRepository.nextQueuePosition(reg.getEvent());
            reg.setStatus(RegistrationStatus.WAITLISTED);
            reg.setQueuePosition(pos);
        }
        registrationRepository.save(reg);
    }

    @Transactional
    public void reject(Registration reg) {
        reg.setStatus(RegistrationStatus.REJECTED);
        registrationRepository.save(reg);
    }

    // ── Поднять первого из очереди ────────────────────
    private void promoteFromWaitlist(Event event) {
        registrationRepository
                .findFirstByEventAndStatusOrderByQueuePositionAsc(event, RegistrationStatus.WAITLISTED)
                .ifPresent(first -> {
                    first.setStatus(RegistrationStatus.REGISTERED);
                    first.setQueuePosition(null);
                    registrationRepository.save(first);
                    // Пересчитать позиции оставшихся
                    recalculateQueue(event);
                });
    }

    private void recalculateQueue(Event event) {
        List<Registration> queue = registrationRepository
                .findByEventAndStatusOrderByQueuePositionAsc(event, RegistrationStatus.WAITLISTED);
        for (int i = 0; i < queue.size(); i++) {
            queue.get(i).setQueuePosition(i + 1);
        }
        registrationRepository.saveAll(queue);
    }
}