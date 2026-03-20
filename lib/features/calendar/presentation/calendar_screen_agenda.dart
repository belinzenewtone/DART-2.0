part of 'calendar_screen.dart';

class _CalendarAgendaPane extends StatelessWidget {
  const _CalendarAgendaPane({
    required this.state,
    required this.selectedDay,
    required this.agendaState,
    required this.writeState,
  });

  final _CalendarScreenState state;
  final DateTime selectedDay;
  final AsyncValue<List<CalendarEvent>> agendaState;
  final AsyncValue<void> writeState;

  @override
  Widget build(BuildContext context) {
    return agendaState.when(
      data: (events) {
        if (events.isEmpty) {
          return const AppEmptyState(
            icon: Icons.upcoming_outlined,
            title: 'No upcoming events',
            subtitle: 'Your next two weeks are clear.',
          );
        }

        DateTime? currentDay;
        return Column(
          children: events.expand((event) {
            final eventDay = DateTime(
              event.startAt.year,
              event.startAt.month,
              event.startAt.day,
            );
            final widgets = <Widget>[];
            if (currentDay == null ||
                !state._isSameDate(currentDay!, eventDay)) {
              currentDay = eventDay;
              widgets.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${state._weekdayName(eventDay.weekday)}, ${_CalendarScreenState._months[eventDay.month - 1]} ${eventDay.day}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              );
            }
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _agendaTypeColor(event.type)
                            .withValues(alpha: 0.18),
                        child: Icon(
                          _agendaTypeIcon(event.type),
                          color: _agendaTypeColor(event.type),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _agendaTimeLabel(event),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (event.note != null && event.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  event.note!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: event.completed,
                        onChanged: writeState.isLoading
                            ? null
                            : (_) async {
                                await state.ref
                                    .read(
                                      calendarWriteControllerProvider.notifier,
                                    )
                                    .setEventCompleted(
                                      eventId: event.id,
                                      completed: !event.completed,
                                    );
                              },
                      ),
                    ],
                  ),
                ),
              ),
            );
            return widgets;
          }).toList(),
        );
      },
      loading: () => Column(
        children: List.generate(3, (_) => AppSkeleton.card(context))
            .expand((element) => [element, const SizedBox(height: 10)])
            .toList(),
      ),
      error: (_, __) => ErrorMessage(
        label: 'Unable to load agenda',
        onRetry: () => state.ref.invalidate(agendaEventsProvider),
      ),
    );
  }
}

Color _agendaTypeColor(CalendarEventType type) {
  return switch (type) {
    CalendarEventType.work => AppColors.accent,
    CalendarEventType.personal => AppColors.violet,
    CalendarEventType.finance => AppColors.teal,
    CalendarEventType.health => AppColors.warning,
    CalendarEventType.general => AppColors.slate,
  };
}

IconData _agendaTypeIcon(CalendarEventType type) {
  return switch (type) {
    CalendarEventType.work => Icons.work_outline,
    CalendarEventType.personal => Icons.person_outline,
    CalendarEventType.finance => Icons.account_balance_wallet_outlined,
    CalendarEventType.health => Icons.favorite_outline,
    CalendarEventType.general => Icons.event_note_outlined,
  };
}

String _agendaTimeLabel(CalendarEvent event) {
  final startHour = event.startAt.hour.toString().padLeft(2, '0');
  final startMinute = event.startAt.minute.toString().padLeft(2, '0');
  if (event.endAt == null) {
    return '$startHour:$startMinute';
  }

  final endHour = event.endAt!.hour.toString().padLeft(2, '0');
  final endMinute = event.endAt!.minute.toString().padLeft(2, '0');
  return '$startHour:$startMinute - $endHour:$endMinute';
}
