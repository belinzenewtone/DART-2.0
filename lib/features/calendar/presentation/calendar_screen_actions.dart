part of 'calendar_screen.dart';

Future<void> _handleSuperAddFromCalendarImpl(
  _CalendarScreenState state,
  BuildContext context,
  DateTime selectedDay,
) async {
  final input = await showSuperAddSheet(
    context,
    defaultKind: SuperEntryKind.event,
    contextDate: selectedDay,
  );
  if (input == null) {
    return;
  }

  if (input.kind == SuperEntryKind.task) {
    await state.ref
        .read(taskWriteControllerProvider.notifier)
        .addTask(
          title: input.title,
          description: input.description,
          dueDate: input.dueAt,
          priority: switch (input.priority) {
            SuperEntryPriority.high => TaskPriority.high,
            SuperEntryPriority.medium => TaskPriority.medium,
            SuperEntryPriority.low => TaskPriority.low,
          },
          reminderEnabled: input.reminderEnabled,
          reminderMinutesBefore: input.reminderMinutesBefore,
        );
    if (context.mounted &&
        !state.ref.read(taskWriteControllerProvider).hasError) {
      AppFeedback.success(context, 'Task added', ref: state.ref);
    }
    return;
  }

  final eventStart = input.startAt;
  if (eventStart == null) {
    return;
  }

  await state.ref
      .read(calendarWriteControllerProvider.notifier)
      .addEvent(
        title: input.title,
        startAt: eventStart,
        priority: switch (input.priority) {
          SuperEntryPriority.high => CalendarEventPriority.high,
          SuperEntryPriority.medium => CalendarEventPriority.medium,
          SuperEntryPriority.low => CalendarEventPriority.low,
        },
        type: switch (input.eventType ?? SuperEntryEventType.general) {
          SuperEntryEventType.work => CalendarEventType.work,
          SuperEntryEventType.personal => CalendarEventType.personal,
          SuperEntryEventType.finance => CalendarEventType.finance,
          SuperEntryEventType.health => CalendarEventType.health,
          SuperEntryEventType.general => CalendarEventType.general,
        },
        endAt: input.endAt,
        note: input.description,
        reminderEnabled: input.reminderEnabled,
        reminderMinutesBefore: input.reminderMinutesBefore,
      );
  if (context.mounted &&
      !state.ref.read(calendarWriteControllerProvider).hasError) {
    AppFeedback.success(context, 'Event added', ref: state.ref);
  }
}

Future<void> _editEventWithSuperSheetImpl(
  _CalendarScreenState state,
  BuildContext context,
  CalendarEvent event,
  DateTime selectedDay,
) async {
  final input = await showSuperAddSheet(
    context,
    defaultKind: SuperEntryKind.event,
    contextDate: selectedDay,
    initialInput: SuperEntryInput(
      kind: SuperEntryKind.event,
      title: event.title,
      description: event.note,
      priority: _superPriorityFromEvent(event.priority),
      startAt: event.startAt,
      endAt: event.endAt,
      eventType: _superTypeFromEvent(event.type),
      reminderEnabled: event.reminderEnabled,
      reminderMinutesBefore: event.reminderMinutesBefore,
    ),
    actionLabel: 'Save',
    lockKind: true,
  );
  if (input == null || input.kind != SuperEntryKind.event) {
    return;
  }
  final eventStart = input.startAt;
  if (eventStart == null) {
    return;
  }
  await state.ref
      .read(calendarWriteControllerProvider.notifier)
      .updateEvent(
        eventId: event.id,
        title: input.title,
        startAt: eventStart,
        priority: _eventPriorityFromSuper(input.priority),
        type: _eventTypeFromSuper(
          input.eventType ?? SuperEntryEventType.general,
        ),
        endAt: input.endAt,
        note: input.description,
        reminderEnabled: input.reminderEnabled,
        reminderMinutesBefore: input.reminderMinutesBefore,
      );
  if (context.mounted &&
      !state.ref.read(calendarWriteControllerProvider).hasError) {
    AppFeedback.success(context, 'Event updated', ref: state.ref);
  }
}

CalendarEventPriority _eventPriorityFromSuper(SuperEntryPriority priority) {
  return switch (priority) {
    SuperEntryPriority.high => CalendarEventPriority.high,
    SuperEntryPriority.medium => CalendarEventPriority.medium,
    SuperEntryPriority.low => CalendarEventPriority.low,
  };
}

SuperEntryPriority _superPriorityFromEvent(CalendarEventPriority priority) {
  return switch (priority) {
    CalendarEventPriority.high => SuperEntryPriority.high,
    CalendarEventPriority.medium => SuperEntryPriority.medium,
    CalendarEventPriority.low => SuperEntryPriority.low,
  };
}

CalendarEventType _eventTypeFromSuper(SuperEntryEventType type) {
  return switch (type) {
    SuperEntryEventType.work => CalendarEventType.work,
    SuperEntryEventType.personal => CalendarEventType.personal,
    SuperEntryEventType.finance => CalendarEventType.finance,
    SuperEntryEventType.health => CalendarEventType.health,
    SuperEntryEventType.general => CalendarEventType.general,
  };
}

SuperEntryEventType _superTypeFromEvent(CalendarEventType type) {
  return switch (type) {
    CalendarEventType.work => SuperEntryEventType.work,
    CalendarEventType.personal => SuperEntryEventType.personal,
    CalendarEventType.finance => SuperEntryEventType.finance,
    CalendarEventType.health => SuperEntryEventType.health,
    CalendarEventType.general => SuperEntryEventType.general,
  };
}
