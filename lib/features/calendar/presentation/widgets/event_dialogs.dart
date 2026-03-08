import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/theme/app_motion.dart';
import 'package:dart_2_0/core/widgets/app_dialog.dart';
import 'package:dart_2_0/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class NewEventInput {
  const NewEventInput({
    required this.title,
    required this.startAt,
    required this.priority,
    required this.type,
    this.endAt,
    this.note,
  });

  final String title;
  final DateTime startAt;
  final CalendarEventPriority priority;
  final CalendarEventType type;
  final DateTime? endAt;
  final String? note;
}

Future<NewEventInput?> showAddEventDialog(
  BuildContext context, {
  required DateTime selectedDay,
}) async {
  return _showEventDialog(context, selectedDay: selectedDay);
}

Future<NewEventInput?> showEditEventDialog(
  BuildContext context, {
  required DateTime selectedDay,
  required CalendarEvent event,
}) {
  return _showEventDialog(
    context,
    selectedDay: selectedDay,
    initialEvent: event,
  );
}

Future<NewEventInput?> _showEventDialog(
  BuildContext context, {
  required DateTime selectedDay,
  CalendarEvent? initialEvent,
}) async {
  final titleController =
      TextEditingController(text: initialEvent?.title ?? '');
  final noteController = TextEditingController(text: initialEvent?.note ?? '');
  final defaultStart =
      DateTime(selectedDay.year, selectedDay.month, selectedDay.day, 14, 0);
  var selectedStart = initialEvent?.startAt ?? defaultStart;
  var selectedPriority = initialEvent?.priority ?? CalendarEventPriority.medium;
  var selectedType = initialEvent?.type ?? CalendarEventType.general;
  final eventDuration = initialEvent?.endAt == null
      ? const Duration(hours: 1)
      : initialEvent!.endAt!.difference(initialEvent.startAt).inMinutes <= 0
          ? const Duration(hours: 1)
          : initialEvent.endAt!.difference(initialEvent.startAt);

  return showAppDialog<NewEventInput>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final brightness = Theme.of(context).brightness;
        final textPrimary = AppColors.textPrimaryFor(brightness);
        final choiceDuration = AppMotion.content(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(brightness).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.borderFor(brightness).withValues(alpha: 0.7),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  initialEvent == null ? 'New Event' : 'Edit Event',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: 'Title'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  minLines: 2,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(hintText: 'Note (optional)'),
                ),
                const SizedBox(height: 14),
                Text(
                  'Priority',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    CalendarEventPriority.low,
                    CalendarEventPriority.medium,
                    CalendarEventPriority.high,
                  ].map((priority) {
                    final option = _priorityOption(priority);
                    final selected = selectedPriority == priority;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: priority == CalendarEventPriority.low ? 8 : 0,
                          left: priority == CalendarEventPriority.high ? 8 : 0,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () =>
                              setState(() => selectedPriority = priority),
                          child: AnimatedContainer(
                            duration: choiceDuration,
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? option.color.withValues(alpha: 0.9)
                                  : option.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? option.color.withValues(alpha: 0.95)
                                    : option.color.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              option.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected
                                    ? textPrimary
                                    : option.color.withValues(alpha: 0.95),
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text(
                  'Event Type',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CalendarEventType.values.map((type) {
                    final option = _eventTypeOption(type);
                    final selected = selectedType == type;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => selectedType = type),
                      child: AnimatedContainer(
                        duration: choiceDuration,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? option.color.withValues(alpha: 0.88)
                              : option.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: option.color.withValues(
                              alpha: selected ? 0.95 : 0.35,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              option.icon,
                              size: 16,
                              color: selected
                                  ? textPrimary
                                  : option.color.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              option.label,
                              style: TextStyle(
                                color: selected
                                    ? textPrimary
                                    : option.color.withValues(alpha: 0.95),
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final picked = await _pickDateTime(context, selectedStart);
                    if (picked != null) {
                      setState(() => selectedStart = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMutedFor(brightness)
                          .withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.borderFor(brightness)
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: AppColors.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _formatDateTimeLabel(context, selectedStart),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          return;
                        }
                        final note = noteController.text.trim();
                        Navigator.of(context).pop(
                          NewEventInput(
                            title: title,
                            startAt: selectedStart,
                            endAt: selectedStart.add(eventDuration),
                            priority: selectedPriority,
                            type: selectedType,
                            note: note.isEmpty ? null : note,
                          ),
                        );
                      },
                      child: Text(initialEvent == null ? 'Create' : 'Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<DateTime?> _pickDateTime(BuildContext context, DateTime initial) async {
  final now = DateTime.now();
  final pickedDate = await showDatePicker(
    context: context,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 5),
    initialDate: initial,
  );
  if (pickedDate == null) {
    return null;
  }
  if (!context.mounted) {
    return null;
  }
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (pickedTime == null) {
    return null;
  }
  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}

String _formatDateTimeLabel(BuildContext context, DateTime value) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatMediumDate(value);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(value),
    alwaysUse24HourFormat: true,
  );
  return '$date at $time';
}

({String label, Color color}) _priorityOption(CalendarEventPriority priority) {
  return switch (priority) {
    CalendarEventPriority.high => (label: 'Urgent', color: AppColors.danger),
    CalendarEventPriority.medium => (
        label: 'Important',
        color: AppColors.warning
      ),
    CalendarEventPriority.low => (label: 'Neutral', color: AppColors.accent),
  };
}

({String label, Color color, IconData icon}) _eventTypeOption(
    CalendarEventType type) {
  return switch (type) {
    CalendarEventType.work => (
        label: 'Work',
        color: const Color(0xFF2F82FF),
        icon: Icons.work_outline
      ),
    CalendarEventType.personal => (
        label: 'Personal',
        color: const Color(0xFF6D77E8),
        icon: Icons.person_outline
      ),
    CalendarEventType.finance => (
        label: 'Finance',
        color: const Color(0xFF2AAE9D),
        icon: Icons.account_balance_wallet_outlined
      ),
    CalendarEventType.health => (
        label: 'Health',
        color: const Color(0xFFE4895E),
        icon: Icons.favorite_outline
      ),
    CalendarEventType.general => (
        label: 'General',
        color: const Color(0xFF5F7395),
        icon: Icons.event_note_outlined
      ),
  };
}
