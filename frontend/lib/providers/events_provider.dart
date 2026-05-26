import 'package:flutter/foundation.dart';

import '../core/api/api_json.dart';
import '../core/api/events_service.dart';
import '../models/attendance.dart';
import '../models/event.dart';
import '../models/registration.dart';

class EventsProvider extends ChangeNotifier {
  final EventsService _service = EventsService();

  bool _isLoadingEvents = false;
  bool _isLoadingRegistrations = false;
  String? _error;
  List<Event> _events = [];
  List<Registration> _myRegistrations = [];
  EventParticipantsResponse? _participants;
  AttendanceStats? _attendance;
  ScanResponse? _scanResult;

  bool get isLoadingEvents => _isLoadingEvents;
  bool get isLoadingRegistrations => _isLoadingRegistrations;
  String? get error => _error;
  List<Event> get events => _events;
  List<Registration> get myRegistrations => _myRegistrations;
  EventParticipantsResponse? get participants => _participants;
  AttendanceStats? get attendance => _attendance;
  ScanResponse? get scanResult => _scanResult;

  Future<void> loadEvents() async {
    _isLoadingEvents = true;
    _error = null;
    notifyListeners();
    try {
      _events = await _service.getEvents();
    } catch (e) {
      _error = _extractErrorMessage(e);
    } finally {
      _isLoadingEvents = false;
      notifyListeners();
    }
  }

  Future<Event?> loadEventById(String id) async {
    try {
      return await _service.getEventById(id);
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<EventRegistrationResponse?> registerForEvent(
    String id, {
    List<Map<String, String>> answers = const [],
  }) async {
    try {
      final result = await _service.registerForEvent(id, answers: answers);
      await Future.wait([loadEvents(), loadMyRegistrations()]);
      return result;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<String?> cancelRegistration(String id) async {
    try {
      final message = await _service.cancelRegistration(id);
      await Future.wait([loadEvents(), loadMyRegistrations()]);
      return message;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMyRegistrations() async {
    _isLoadingRegistrations = true;
    _error = null;
    notifyListeners();
    try {
      _myRegistrations = await _service.getMyRegistrations();
    } catch (e) {
      _error = _extractErrorMessage(e);
    } finally {
      _isLoadingRegistrations = false;
      notifyListeners();
    }
  }

  Future<bool> createEvent({
    required String title,
    required String description,
    required DateTime eventDate,
    required String location,
    required int maxParticipants,
    required String type,
    required List<Map<String, dynamic>> fields,
  }) async {
    _error = null;
    notifyListeners();
    try {
      await _service.createEvent(
        title: title,
        description: description,
        eventDate: eventDate,
        location: location,
        maxParticipants: maxParticipants,
        type: type,
        fields: fields,
      );
      await loadEvents();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEvent({
    required String id,
    required String title,
    required String description,
    required DateTime eventDate,
    required String location,
    required int maxParticipants,
    required String type,
    required List<Map<String, dynamic>> fields,
  }) async {
    _error = null;
    notifyListeners();
    try {
      await _service.updateEvent(
        id: id,
        title: title,
        description: description,
        eventDate: eventDate,
        location: location,
        maxParticipants: maxParticipants,
        type: type,
        fields: fields,
      );
      await loadEvents();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(String id) async {
    _error = null;
    notifyListeners();
    try {
      await _service.deleteEvent(id);
      await loadEvents();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> loadParticipants(String eventId) async {
    _error = null;
    _participants = null;
    notifyListeners();
    try {
      _participants = await _service.getEventRegistrations(eventId);
    } catch (e) {
      _error = _extractErrorMessage(e);
    } finally {
      notifyListeners();
    }
  }

  Future<String?> approve(String eventId, String registrationId) async {
    try {
      final message = await _service.approveRegistration(eventId, registrationId);
      await loadParticipants(eventId);
      return message;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<String?> reject(String eventId, String registrationId) async {
    try {
      final message = await _service.rejectRegistration(eventId, registrationId);
      await loadParticipants(eventId);
      return message;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> loadAttendance(String eventId) async {
    _error = null;
    _attendance = null;
    notifyListeners();
    try {
      _attendance = await _service.getAttendance(eventId);
    } catch (e) {
      _error = _extractErrorMessage(e);
    } finally {
      notifyListeners();
    }
  }

  Future<String?> finalizeEvent(String eventId) async {
    try {
      final message = await _service.finalizeEvent(eventId);
      await loadAttendance(eventId);
      return message;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<ScanResponse?> scan({
    required String qrToken,
    required String eventId,
  }) async {
    try {
      _scanResult = await _service.scan(qrToken: qrToken, eventId: eventId);
      notifyListeners();
      return _scanResult;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Registration? registrationByEventId(String eventId) {
    for (final registration in _myRegistrations) {
      if (registration.event.id == eventId) {
        return registration;
      }
    }
    return null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) => extractApiErrorMessage(error);
}
