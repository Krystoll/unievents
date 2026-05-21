import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/events_provider.dart';

class _FieldDraft {
  _FieldDraft({String name = '', this.required = true}) : controller = TextEditingController(text: name);
  final TextEditingController controller;
  bool required;
}

class AdminCreateEventScreen extends StatefulWidget {
  const AdminCreateEventScreen({super.key, this.initialEvent, this.onSaved});

  final Event? initialEvent;
  final VoidCallback? onSaved;

  @override
  State<AdminCreateEventScreen> createState() => _AdminCreateEventScreenState();
}

class _AdminCreateEventScreenState extends State<AdminCreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  DateTime? _eventDate;
  String _type = 'FREE';
  final List<_FieldDraft> _fields = [];
  bool _isSaving = false;

  bool get _isEdit => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    if (event != null) {
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _locationController.text = event.location;
      _maxParticipantsController.text = event.maxParticipants.toString();
      _eventDate = event.eventDate;
      _type = event.type;
      for (final field in event.fields) {
        _fields.add(_FieldDraft(name: field.fieldName, required: field.required));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    for (final field in _fields) {
      field.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventDate ?? now),
    );
    if (time == null) return;
    setState(() {
      _eventDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _eventDate == null) return;
    setState(() => _isSaving = true);
    final provider = context.read<EventsProvider>();
    final maxParticipants = int.parse(_maxParticipantsController.text.trim());
    final payloadFields = _type == 'APPROVAL'
        ? _fields
            .where((f) => f.controller.text.trim().isNotEmpty)
            .map((f) => {
                  'fieldName': f.controller.text.trim(),
                  'required': f.required,
                })
            .toList()
        : <Map<String, dynamic>>[];

    bool ok;
    if (_isEdit) {
      ok = await provider.updateEvent(
        id: widget.initialEvent!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: _eventDate!,
        location: _locationController.text.trim(),
        maxParticipants: maxParticipants,
        type: _type,
        fields: payloadFields,
      );
    } else {
      ok = await provider.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: _eventDate!,
        location: _locationController.text.trim(),
        maxParticipants: maxParticipants,
        type: _type,
        fields: payloadFields,
      );
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Мероприятие обновлено' : 'Мероприятие создано')),
      );
      widget.onSaved?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Ошибка сохранения')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _eventDate == null
        ? 'Дата не выбрана'
        : DateFormat('dd.MM.yyyy HH:mm').format(_eventDate!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Редактирование мероприятия' : 'Создание мероприятия',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Описание'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Введите описание' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Место'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Введите место' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Тип'),
                items: const [
                  DropdownMenuItem(value: 'FREE', child: Text('FREE')),
                  DropdownMenuItem(value: 'APPROVAL', child: Text('APPROVAL')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(labelText: 'Максимум участников'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final n = int.tryParse(value?.trim() ?? '');
                  if (n == null || n <= 0) return 'Введите положительное число';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Дата: $dateText')),
                  OutlinedButton(
                    onPressed: _pickDateTime,
                    child: const Text('Выбрать дату'),
                  ),
                ],
              ),
              if (_eventDate == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Выберите дату и время'),
                ),
              if (_type == 'APPROVAL') ...[
                const SizedBox(height: 16),
                Text('Кастомные поля', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._fields.asMap().entries.map((entry) {
                  final i = entry.key;
                  final field = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: field.controller,
                            decoration: const InputDecoration(
                              labelText: 'Название поля',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: field.required,
                          onChanged: (v) {
                            setState(() => field.required = v ?? false);
                          },
                        ),
                        const Text('Обязательное'),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fields.removeAt(i).controller.dispose();
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _fields.add(_FieldDraft())),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить поле'),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Сохранить изменения' : 'Создать'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
