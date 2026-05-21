package com.unievents.repository;

import com.unievents.model.Event;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDateTime;
import java.util.*;

public interface EventRepository extends JpaRepository<Event, UUID> {
    // Мероприятия, которые закончились, но ещё не финализированы
    List<Event> findByEventDateBefore(LocalDateTime dateTime);
}