part of 'calendar_screen.dart';

class _CalendarEventsPane extends StatelessWidget {
  const _CalendarEventsPane({
    required this.state,
    required this.eventsState,
    required this.selectedDay,
    required this.writeState,
  });

  final _CalendarScreenState state;
  final AsyncValue<List<CalendarEvent>> eventsState;
  final DateTime selectedDay;
  final AsyncValue<void> writeState;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
        absorbing: state._swiping,
        child: eventsState.when(
          skipLoadingOnReload: true,
          data: (events) {
            state._consumeSearchTarget(context, state.ref, selectedDay, events);
            if (events.isEmpty) {
              return const AppEmptyState(
                icon: Icons.event_outlined,
                title: 'No events',
                subtitle: 'Add an event to get started',
              );
            }
            return CalendarEventsCard(
              events: events,
              busy: writeState.isLoading,
              onComplete: (event) async {
                if (event.completed) {
                  return;
                }
                await state.ref
                    .read(calendarWriteControllerProvider.notifier)
                    .setEventCompleted(eventId: event.id, completed: true);
                if (context.mounted &&
                    !state.ref.read(calendarWriteControllerProvider).hasError) {
                  AppFeedback.success(
                    context,
                    'Event completed ✓',
                    ref: state.ref,
                  );
                }
              },
              onEdit: (event) async {
                await _editEventWithSuperSheetImpl(
                  state,
                  context,
                  event,
                  selectedDay,
                );
              },
              onDelete: (event) async {
                await state.ref
                    .read(calendarWriteControllerProvider.notifier)
                    .deleteEvent(event.id);
                if (context.mounted &&
                    !state.ref.read(calendarWriteControllerProvider).hasError) {
                  AppFeedback.success(context, 'Event deleted', ref: state.ref);
                }
              },
            );
          },
          loading: () => Column(
            children: List.generate(3, (_) => AppSkeleton.card(context))
                .expand(
                  (element) => [
                    element,
                    const SizedBox(height: AppSpacing.listGap),
                  ],
                )
                .toList(),
          ),
          error: (_, __) => ErrorMessage(
            label: 'Unable to load events',
            onRetry: () => state.ref.invalidate(dayEventsProvider),
          ),
        ),
      );
  }
}
