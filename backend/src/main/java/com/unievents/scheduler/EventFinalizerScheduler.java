package com.unievents.scheduler;

import com.unievents.model.*;
import com.unievents.model.enums.RegistrationStatus;
import com.unievents.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class EventFinalizerScheduler {

    private final EventRepository eventRepository;
    private final RegistrationRepository registrationRepository;
    private final UserRepository userRepository;

    // Запускается каждые 15 минут
    @Scheduled(cron = "0 */15 * * * *")
    @Transactional
    public void finalizeExpiredEvents() {
        List<Event> expiredEvents = eventRepository
                .findByEventDateBefore(LocalDateTime.now().minusHours(1));

        for (Event event : expiredEvents) {
            List<Registration> stillRegistered = registrationRepository
                    .findByEventAndStatus(event, RegistrationStatus.REGISTERED);

            if (!stillRegistered.isEmpty()) {
                log.info("Финализация события '{}': {} NO_SHOW",
                        event.getTitle(), stillRegistered.size());

                for (Registration reg : stillRegistered) {
                    reg.setStatus(RegistrationStatus.NO_SHOW);
                    registrationRepository.save(reg);

                    User u = reg.getUser();
                    u.setNoShowCount(u.getNoShowCount() + 1);
                    int total = u.getAttendedCount() + u.getNoShowCount();
                    u.setReliabilityScore(total == 0 ? 100.0f
                            : (u.getAttendedCount() * 100.0f) / total);
                    userRepository.save(u);
                }
            }
        }
    }
}