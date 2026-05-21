import 'event_field.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String location;
  final int maxParticipants;
  final int currentParticipants;
  final int waitlistCount;
  final String type;
  final List<EventField> fields;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.waitlistCount,
    required this.type,
    required this.fields,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      eventDate: DateTime.parse(json['eventDate'] as String),
      location: json['location'] as String,
      maxParticipants: (json['maxParticipants'] as int?) ?? 0,
      currentParticipants: (json['currentParticipants'] as int?) ?? 0,
      waitlistCount: (json['waitlistCount'] as int?) ?? 0,
      type: (json['type'] as String?) ?? 'FREE',
      fields: (json['fields'] as List<dynamic>? ?? [])
          .map((e) => EventField.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toCreateUpdateJson() {
    return {
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'location': location,
      'maxParticipants': maxParticipants,
      'type': type,
      'fields': fields.map((e) => e.toJson()).toList(),
    };
  }
}
