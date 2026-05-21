import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/form_section.dart';

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
    if (!_formKey.currentState!.validate() || _eventDate == null) {
      if (_eventDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите дату и время мероприятия')),
        );
      }
      return;
    }
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
        ? 'Не выбрано'
        : DateFormat('dd.MM.yyyy, HH:mm').format(_eventDate!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEdit ? 'Редактирование' : 'Новое мероприятие',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                FormSection(
                  title: 'Основная информация',
                  subtitle: 'Название, описание и место проведения',
                  icon: Icons.info_outline_rounded,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Название',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Введите название' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          prefixIcon: Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Введите описание' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Место',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Введите место' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FormSection(
                  title: 'Параметры',
                  subtitle: 'Тип записи, лимит и дата',
                  icon: Icons.tune_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Тип записи', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'FREE',
                            label: Text('Свободная'),
                            icon: Icon(Icons.how_to_reg_outlined, size: 18),
                          ),
                          ButtonSegment(
                            value: 'APPROVAL',
                            label: Text('По заявке'),
                            icon: Icon(Icons.fact_check_outlined, size: 18),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (set) {
                          setState(() => _type = set.first);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _maxParticipantsController,
                        decoration: const InputDecoration(
                          labelText: 'Максимум участников',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final n = int.tryParse(value?.trim() ?? '');
                          if (n == null || n <= 0) return 'Введите положительное число';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InkWell(
                        onTap: _pickDateTime,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _eventDate == null
                                  ? AppColors.warning.withValues(alpha: 0.6)
                                  : AppColors.outline,
                            ),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            color: AppColors.surfaceContainer,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: _eventDate == null ? AppColors.warning : AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Дата и время',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      dateText,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_type == 'APPROVAL') ...[
                  const SizedBox(height: AppSpacing.md),
                  FormSection(
                    title: 'Поля заявки',
                    subtitle: 'Дополнительные вопросы для студентов',
                    icon: Icons.list_alt_rounded,
                    trailing: IconButton.filledTonal(
                      onPressed: () => setState(() => _fields.add(_FieldDraft())),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Добавить поле',
                    ),
                    child: Column(
                      children: [
                        if (_fields.isEmpty)
                          Text(
                            'Нет полей — нажмите + чтобы добавить',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ..._fields.asMap().entries.map((entry) {
                          final i = entry.key;
                          final field = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: field.controller,
                                    decoration: const InputDecoration(
                                      labelText: 'Название поля',
                                      isDense: true,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: field.required,
                                        onChanged: (v) {
                                          setState(() => field.required = v ?? false);
                                        },
                                      ),
                                      const Text('Обязательное'),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _fields.removeAt(i).controller.dispose();
                                          });
                                        },
                                        icon: const Icon(Icons.delete_outline_rounded),
                                        color: AppColors.error,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded),
                            const SizedBox(width: 8),
                            Text(_isEdit ? 'Сохранить изменения' : 'Создать мероприятие'),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
