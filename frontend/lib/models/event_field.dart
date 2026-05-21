class EventField {
  final String id;
  final String fieldName;
  final bool required;

  const EventField({
    required this.id,
    required this.fieldName,
    required this.required,
  });

  factory EventField.fromJson(Map<String, dynamic> json) {
    return EventField(
      id: json['id']?.toString() ?? '',
      fieldName: json['fieldName'] as String,
      required: json['required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldName': fieldName,
      'required': required,
    };
  }
}
