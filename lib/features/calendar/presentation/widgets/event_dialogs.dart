import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class NewEventInput {
  const NewEventInput({
    required this.title,
    required this.startAt,
    this.endAt,
    this.note,
  });

  final String title;
  final DateTime startAt;
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
  TimeOfDay startTime = initialEvent == null
      ? const TimeOfDay(hour: 14, minute: 0)
      : TimeOfDay.fromDateTime(initialEvent.startAt);
  TimeOfDay endTime = initialEvent?.endAt == null
      ? const TimeOfDay(hour: 15, minute: 0)
      : TimeOfDay.fromDateTime(initialEvent!.endAt!);

  return showDialog<NewEventInput>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(initialEvent == null ? 'Add Event' : 'Edit Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Team check-in',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (picked != null) {
                          setState(() => startTime = picked);
                        }
                      },
                      icon: const Icon(Icons.schedule),
                      label: Text('Start ${_timeLabel(startTime)}'),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (picked != null) {
                          setState(() => endTime = picked);
                        }
                      },
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text('End ${_timeLabel(endTime)}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                return;
              }
              final startAt = DateTime(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
                startTime.hour,
                startTime.minute,
              );
              final endAt = DateTime(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
                endTime.hour,
                endTime.minute,
              );
              Navigator.of(context).pop(
                NewEventInput(
                  title: title,
                  startAt: startAt,
                  endAt: endAt.isAfter(startAt)
                      ? endAt
                      : startAt.add(const Duration(hours: 1)),
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                ),
              );
            },
            child: Text(initialEvent == null ? 'Save' : 'Update'),
          ),
        ],
      ),
    ),
  );
}

String _timeLabel(TimeOfDay value) {
  final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $suffix';
}
