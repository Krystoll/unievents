package com.unievents.util;

import com.unievents.exception.BadRequestException;
import com.unievents.model.Event;
import com.unievents.model.enums.EventPhase;

import java.time.LocalDateTime;

public final class EventTimeUtil {

    private EventTimeUtil() {}

    public static LocalDateTime endAt(Event event) {
        int minutes = event.getDurationMinutes() != null ? event.getDurationMinutes() : 60;
        return event.getEventDate().plusMinutes(minutes);
    }

    public static EventPhase phase(Event event, LocalDateTime now) {
        if (now.isBefore(event.getEventDate())) {
            return EventPhase.UPCOMING;
        }
        if (now.isAfter(endAt(event))) {
            return EventPhase.FINISHED;
        }
        return EventPhase.ONGOING;
    }

    public static boolean isFinished(Event event, LocalDateTime now) {
        return phase(event, now) == EventPhase.FINISHED;
    }

    public static boolean isOngoing(Event event, LocalDateTime now) {
        return phase(event, now) == EventPhase.ONGOING;
    }

    public static void ensureRegistrationOpen(Event event) {
        if (isFinished(event, LocalDateTime.now())) {
            throw new BadRequestException("Запись на прошедшее мероприятие недоступна");
        }
    }

    public static void ensureScanWindow(Event event) {
        LocalDateTime now = LocalDateTime.now();
        if (now.isBefore(event.getEventDate())) {
            throw new BadRequestException("Сканирование доступно только после начала мероприятия");
        }
        if (now.isAfter(endAt(event))) {
            throw new BadRequestException("Сканирование недоступно — мероприятие уже завершилось");
        }
    }

    public static void ensureGamesWindow(Event event) {
        if (!isOngoing(event, LocalDateTime.now())) {
            throw new BadRequestException("Играть можно только во время проведения мероприятия");
        }
    }
}
