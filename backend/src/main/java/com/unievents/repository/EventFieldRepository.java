package com.unievents.repository;

import com.unievents.model.*;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;

public interface EventFieldRepository extends JpaRepository<EventField, UUID> {
    List<EventField> findByEvent(Event event);
}