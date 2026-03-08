import 'package:beltech/core/widgets/action_button.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:beltech/features/calendar/presentation/widgets/calendar_events_card.dart';
import 'package:beltech/features/calendar/presentation/widgets/calendar_month_grid.dart';
import 'package:beltech/features/calendar/presentation/widgets/event_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});
  static const double _calendarContentMaxWidth = 360;

  static const List<String> _weekDays = [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su'
  ];
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final visibleMonth = ref.watch(visibleMonthProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final eventsState = ref.watch(dayEventsProvider);
    final monthEventTypesState = ref.watch(monthEventTypesProvider);
    final writeState = ref.watch(calendarWriteControllerProvider);

    ref.listen<AsyncValue<void>>(calendarWriteControllerProvider,
        (previous, next) {
      if (previous is AsyncLoading && next is AsyncData<void>) {
        AppFeedback.success(context, 'Calendar event saved successfully.');
      } else if (next.hasError) {
        AppFeedback.error(context, 'Unable to save calendar event.');
      }
    });

    final title = '${_months[visibleMonth.month - 1]} ${visibleMonth.year}';

    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calendar', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -120) {
                  _changeMonth(ref, 1);
                } else if (velocity > 120) {
                  _changeMonth(ref, -1);
                }
              },
              child: GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(ref, -1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(title, style: textTheme.titleMedium),
                        IconButton(
                          onPressed: () => _changeMonth(ref, 1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _calendarContentMaxWidth,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _weekDays
                              .map(
                                (day) => SizedBox(
                                  width: 30,
                                  child: Text(
                                    day,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CalendarMonthGrid(
                      visibleMonth: visibleMonth,
                      selectedDay: selectedDay,
                      eventTypes: monthEventTypesState.valueOrNull ?? const {},
                      maxWidth: _calendarContentMaxWidth,
                      onSelect: (day) {
                        ref.read(selectedDayProvider.notifier).state = day;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_weekdayName(selectedDay.weekday)}, ${_months[selectedDay.month - 1]} ${selectedDay.day.toString().padLeft(2, '0')}',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: eventsState.when(
                data: (events) => CalendarEventsCard(
                  events: events,
                  busy: writeState.isLoading,
                  onComplete: (event) async {
                    if (event.completed) {
                      return;
                    }
                    await ref
                        .read(calendarWriteControllerProvider.notifier)
                        .setEventCompleted(eventId: event.id, completed: true);
                  },
                  onEdit: (event) async {
                    final input = await showEditEventDialog(
                      context,
                      selectedDay: selectedDay,
                      event: event,
                    );
                    if (input == null) {
                      return;
                    }
                    await ref
                        .read(calendarWriteControllerProvider.notifier)
                        .updateEvent(
                          eventId: event.id,
                          title: input.title,
                          startAt: input.startAt,
                          priority: input.priority,
                          type: input.type,
                          endAt: input.endAt,
                          note: input.note,
                        );
                  },
                  onDelete: (event) async {
                    await ref
                        .read(calendarWriteControllerProvider.notifier)
                        .deleteEvent(event.id);
                  },
                ),
                loading: () => const Center(child: LoadingIndicator()),
                error: (_, __) => ErrorMessage(
                  label: 'Unable to load events',
                  onRetry: () => ref.invalidate(dayEventsProvider),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: ActionButton(
                icon: Icons.add,
                isLoading: writeState.isLoading,
                onPressed: writeState.isLoading
                    ? null
                    : () async {
                        final input = await showAddEventDialog(
                          context,
                          selectedDay: selectedDay,
                        );
                        if (input == null) {
                          return;
                        }
                        await ref
                            .read(calendarWriteControllerProvider.notifier)
                            .addEvent(
                              title: input.title,
                              startAt: input.startAt,
                              priority: input.priority,
                              type: input.type,
                              endAt: input.endAt,
                              note: input.note,
                            );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeMonth(WidgetRef ref, int offset) {
    final visible = ref.read(visibleMonthProvider);
    final next = DateTime(visible.year, visible.month + offset, 1);
    ref.read(visibleMonthProvider.notifier).state = next;
    final selected = ref.read(selectedDayProvider);
    if (selected.year != next.year || selected.month != next.month) {
      ref.read(selectedDayProvider.notifier).state =
          DateTime(next.year, next.month, 1);
    }
  }

  String _weekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }
}
