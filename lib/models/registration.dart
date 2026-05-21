import 'event.dart';

class Registration {
  final String registrationId;
  final Event event;
  final String status;
  final int? queuePosition;

  const Registration({
    required this.registrationId,
    required this.event,
    required this.status,
    required this.queuePosition,
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      registrationId: (json['registrationId'] as String?) ?? '',
      event: Event.fromJson(json['event'] as Map<String, dynamic>),
      status: json['status'] as String,
      queuePosition: json['queuePosition'] as int?,
    );
  }
}
