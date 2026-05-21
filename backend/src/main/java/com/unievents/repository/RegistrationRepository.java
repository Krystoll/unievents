package com.unievents.repository;

import com.unievents.model.*;
import com.unievents.model.enums.RegistrationStatus;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;

public interface RegistrationRepository extends JpaRepository<Registration, UUID> {

    Optional<Registration> findByUserAndEvent(User user, Event event);

    List<Registration> findByEventAndStatus(Event event, RegistrationStatus status);

    List<Registration> findByUserOrderByRegisteredAtDesc(User user);

    // Количество зарегистрированных (не считая очередь)
    long countByEventAndStatus(Event event, RegistrationStatus status);

    // Первый в очереди
    Optional<Registration> findFirstByEventAndStatusOrderByQueuePositionAsc(
            Event event, RegistrationStatus status);

    // Все в очереди упорядоченно
    List<Registration> findByEventAndStatusOrderByQueuePositionAsc(
            Event event, RegistrationStatus status);

    // Следующая позиция в очереди
    @Query("SELECT COALESCE(MAX(r.queuePosition), 0) + 1 FROM Registration r " +
            "WHERE r.event = :event AND r.status = 'WAITLISTED'")
    int nextQueuePosition(@Param("event") Event event);
}