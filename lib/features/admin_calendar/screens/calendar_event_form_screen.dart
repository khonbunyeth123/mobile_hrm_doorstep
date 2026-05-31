import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_ui.dart';
import '../models/calendar_event.dart';
import '../models/calendar_target.dart';

class CalendarEventFormScreen extends StatefulWidget {
  final CalendarEvent? initialEvent;

  const CalendarEventFormScreen({
    super.key,
    this.initialEvent,
  });

  @override
  State<CalendarEventFormScreen> createState() => _CalendarEventFormScreenState();
}

class _CalendarEventFormScreenState extends State<CalendarEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _recurrenceController;
  late final TextEditingController _eventTypeController;
  late final TextEditingController _targetLabelController;
  late final TextEditingController _targetIdController;

  DateTime _startAt = DateTime.now();
  DateTime _endAt = DateTime.now().add(const Duration(hours: 1));
  bool _allDay = false;
  String _status = 'published';
  bool _companyWide = true;
  CalendarTargetType _targetType = CalendarTargetType.department;
  final List<CalendarTarget> _targets = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    _recurrenceController = TextEditingController(text: event?.recurrence ?? '');
    final initialEventType =
        event != null && event.eventType.isNotEmpty ? event.eventType : 'meeting';
    _eventTypeController = TextEditingController(text: initialEventType);
    _targetLabelController = TextEditingController();
    _targetIdController = TextEditingController();

    if (event != null) {
      _startAt = event.startAt;
      _endAt = event.endAt;
      _allDay = event.allDay;
      _status = event.status.isNotEmpty ? event.status : 'published';
      if (event.targets.isEmpty || event.targets.any((target) => target.type == CalendarTargetType.company)) {
        _companyWide = true;
      } else {
        _companyWide = false;
        _targets.addAll(event.targets);
      }
    } else {
      _companyWide = true;
      _targets.add(
        const CalendarTarget(
          type: CalendarTargetType.company,
          label: 'Company-wide',
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _recurrenceController.dispose();
    _eventTypeController.dispose();
    _targetLabelController.dispose();
    _targetIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startAt : _endAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;

    setState(() {
      final current = isStart ? _startAt : _endAt;
      final combined = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );
      if (isStart) {
        _startAt = combined;
        if (_endAt.isBefore(_startAt)) {
          _endAt = _startAt.add(const Duration(hours: 1));
        }
      } else {
        _endAt = combined;
        if (_endAt.isBefore(_startAt)) {
          _startAt = _endAt.subtract(const Duration(hours: 1));
        }
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = TimeOfDay.fromDateTime(isStart ? _startAt : _endAt);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    setState(() {
      final base = isStart ? _startAt : _endAt;
      final updated = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );
      if (isStart) {
        _startAt = updated;
        if (_endAt.isBefore(_startAt)) {
          _endAt = _startAt.add(const Duration(hours: 1));
        }
      } else {
        _endAt = updated;
        if (_endAt.isBefore(_startAt)) {
          _startAt = _endAt.subtract(const Duration(hours: 1));
        }
      }
    });
  }

  void _addTarget() {
    if (_companyWide) return;

    final label = _targetLabelController.text.trim();
    if (label.isEmpty) return;

    setState(() {
      _targets.add(
        CalendarTarget(
          type: _targetType,
          id: _targetIdController.text.trim().isEmpty ? null : _targetIdController.text.trim(),
          label: label,
        ),
      );
      _targetLabelController.clear();
      _targetIdController.clear();
    });
  }

  void _removeTarget(CalendarTarget target) {
    setState(() {
      _targets.remove(target);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_companyWide && _targets.isEmpty) {
      setState(() => _error = 'Add at least one target or switch to company-wide.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final normalizedStart = _allDay
        ? DateTime(_startAt.year, _startAt.month, _startAt.day)
        : _startAt;
    final normalizedEnd = _allDay
        ? DateTime(_endAt.year, _endAt.month, _endAt.day, 23, 59)
        : _endAt;

    final targets = _companyWide
        ? [
            const CalendarTarget(
              type: CalendarTargetType.company,
              label: 'Company-wide',
            ),
          ]
        : List<CalendarTarget>.from(_targets);

    final event = CalendarEvent(
      uuid: widget.initialEvent?.uuid ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      eventType: _eventTypeController.text.trim(),
      status: _status.trim(),
      startAt: normalizedStart,
      endAt: normalizedEnd,
      allDay: _allDay,
      recurrence: _recurrenceController.text.trim().isEmpty ? null : _recurrenceController.text.trim(),
      targets: targets,
      isLeave: false,
      leaveUuid: widget.initialEvent?.leaveUuid,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      color: widget.initialEvent?.color,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, event);
  }

  String _dateLabel(DateTime date) => DateFormat('EEE, MMM d, yyyy').format(date);

  String _timeLabel(DateTime date) => DateFormat('h:mm a').format(date);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialEvent == null ? 'Create event' : 'Edit event'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Event basics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Quarterly all-hands',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _eventTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Event type',
                          hintText: 'meeting, holiday, reminder, shift',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Event type is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'draft', child: Text('Draft')),
                          DropdownMenuItem(value: 'published', child: Text('Published')),
                          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppSurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _allDay,
                        title: const Text('All day'),
                        onChanged: (value) => setState(() => _allDay = value),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickDate(isStart: true),
                              child: Text('Start: ${_dateLabel(_startAt)}'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickDate(isStart: false),
                              child: Text('End: ${_dateLabel(_endAt)}'),
                            ),
                          ),
                        ],
                      ),
                      if (!_allDay) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _pickTime(isStart: true),
                                child: Text('Start time: ${_timeLabel(_startAt)}'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _pickTime(isStart: false),
                                child: Text('End time: ${_timeLabel(_endAt)}'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'HQ conference room',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Add notes or event details',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _recurrenceController,
                        decoration: const InputDecoration(
                          labelText: 'Recurrence rule',
                          hintText: 'RRULE:FREQ=WEEKLY;BYDAY=MO',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppSurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Targets',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Company-wide'),
                        value: _companyWide,
                        onChanged: (value) {
                          setState(() {
                            _companyWide = value;
                            if (_companyWide) {
                              _targets.clear();
                            }
                          });
                        },
                      ),
                        if (!_companyWide) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<CalendarTargetType>(
                          initialValue: _targetType,
                          decoration: const InputDecoration(labelText: 'Target type'),
                          items: CalendarTargetType.values
                              .where((type) => type != CalendarTargetType.company)
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _targetType = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _targetLabelController,
                          decoration: const InputDecoration(
                            labelText: 'Target label',
                            hintText: 'Finance team, HQ branch, employee name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _targetIdController,
                          decoration: const InputDecoration(
                            labelText: 'Target ID',
                            hintText: 'Optional backend identifier',
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _addTarget,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add target'),
                        ),
                        const SizedBox(height: 12),
                        if (_targets.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _targets
                                .map(
                                  (target) => InputChip(
                                    label: Text(target.displayLabel),
                                    onDeleted: () => _removeTarget(target),
                                  ),
                                )
                                .toList(),
                          ),
                      ] else
                        const AppStatusPill(
                          label: 'Applies to all employees',
                          color: AppTheme.brand,
                          backgroundColor: AppTheme.brandSoft,
                          icon: Icons.groups_rounded,
                        ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Validation failed',
                    message: _error!,
                  ),
                ],
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: widget.initialEvent == null ? 'Create event' : 'Save changes',
                  onPressed: _saving ? null : _submit,
                  loading: _saving,
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
