import '../models/event.dart';

enum EventPhase { upcoming, ongoing, finished }

extension EventTime on Event {
  DateTime get endDate =>
      eventEndDate ?? eventDate.add(Duration(minutes: durationMinutes));

  EventPhase get phase {
    if (this.phaseRaw != null) {
      return switch (this.phaseRaw!.toUpperCase()) {
        'ONGOING' => EventPhase.ongoing,
        'FINISHED' => EventPhase.finished,
        _ => EventPhase.upcoming,
      };
    }
    final now = DateTime.now();
    if (now.isBefore(eventDate)) return EventPhase.upcoming;
    if (now.isAfter(endDate)) return EventPhase.finished;
    return EventPhase.ongoing;
  }

  bool get isPast => phase == EventPhase.finished;
  bool get isOngoing => phase == EventPhase.ongoing;
  bool get isUpcoming => phase == EventPhase.upcoming;

  String get phaseLabel => switch (phase) {
        EventPhase.upcoming => 'Скоро',
        EventPhase.ongoing => 'Идёт сейчас',
        EventPhase.finished => 'Завершено',
      };
}

const activeRegistrationStatuses = {
  'PENDING',
  'REGISTERED',
  'WAITLISTED',
  'ATTENDED',
  'NO_SHOW',
};

bool isActiveRegistrationStatus(String status) =>
    activeRegistrationStatuses.contains(status);

bool canCancelRegistration(String status) =>
    status == 'REGISTERED' || status == 'WAITLISTED' || status == 'PENDING';

bool canRegisterForEvent(String? status) =>
    status == null || status == 'CANCELLED' || status == 'REJECTED';

bool canShowEventQr(String status, Event event) =>
    status == 'REGISTERED' && event.isOngoing;

bool canPlayEventGames(String status, Event event) =>
    status == 'ATTENDED' && event.isOngoing;

bool canViewEventLeaderboard(Event event) =>
    event.isOngoing || event.isPast;

String formatEventSchedule(DateTime start, DateTime end) {
  final startText = _dateFormat.format(start);
  final endText = _timeFormat.format(end);
  return '$startText — $endText';
}

String formatEventScheduleShort(DateTime start, DateTime end) => formatEventSchedule(start, end);

final _dateFormat = _EventDateFormat();
final _timeFormat = _EventTimeFormat();

class _EventDateFormat {
  String format(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}, '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _EventTimeFormat {
  String format(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
