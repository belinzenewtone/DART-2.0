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

enum _CalendarView { month, week }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  _CalendarView _view = _CalendarView.month;
  bool _swiping = false; // blocks events list during a calendar swipe
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
  Widget build(BuildContext context) {
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

    final title = _view == _CalendarView.month
        ? '${_months[visibleMonth.month - 1]} ${visibleMonth.year}'
        : _weekRangeLabel(selectedDay);

    // Week strip: 7 days starting from Monday of selected week
    final weekStart =
        selectedDay.subtract(Duration(days: selectedDay.weekday - 1));
    final weekDays = List.generate(
      7,
      (i) => weekStart.add(Duration(days: i)),
    );

    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calendar', style: textTheme.titleLarge),
                SegmentedButton<_CalendarView>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: _CalendarView.month,
                      icon: Icon(Icons.calendar_month_outlined, size: 18),
                      label: Text('Month'),
                    ),
                    ButtonSegment(
                      value: _CalendarView.week,
                      icon: Icon(Icons.view_week_outlined, size: 18),
                      label: Text('Week'),
                    ),
                  ],
                  selected: {_view},
                  onSelectionChanged: (v) => setState(() => _view = v.first),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => setState(() => _swiping = true),
              onHorizontalDragEnd: (details) {
                setState(() => _swiping = false);
                final velocity = details.primaryVelocity ?? 0;
                if (_view == _CalendarView.month) {
                  if (velocity < -120) _changeMonth(ref, 1);
                  if (velocity > 120) _changeMonth(ref, -1);
                } else {
                  if (velocity < -120) _changeWeek(ref, 1);
                  if (velocity > 120) _changeWeek(ref, -1);
                }
              },
              onHorizontalDragCancel: () => setState(() => _swiping = false),
              child: GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _view == _CalendarView.month
                              ? _changeMonth(ref, -1)
                              : _changeWeek(ref, -1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(title, style: textTheme.titleMedium),
                        IconButton(
                          onPressed: () => _view == _CalendarView.month
                              ? _changeMonth(ref, 1)
                              : _changeWeek(ref, 1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_view == _CalendarView.month) ...[
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
                        eventTypes:
                            monthEventTypesState.valueOrNull ?? const {},
                        maxWidth: _calendarContentMaxWidth,
                        onSelect: (day) {
                          ref.read(selectedDayProvider.notifier).state = day;
                        },
                      ),
                    ] else ...[
                      // Week view: 7 day cells in a row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: weekDays.map((day) {
                          final isSelected = day.year == selectedDay.year &&
                              day.month == selectedDay.month &&
                              day.day == selectedDay.day;
                          final isToday = day.year == DateTime.now().year &&
                              day.month == DateTime.now().month &&
                              day.day == DateTime.now().day;
                          return GestureDetector(
                            onTap: () {
                              ref.read(selectedDayProvider.notifier).state =
                                  day;
                            },
                            child: Column(
                              children: [
                                Text(
                                  _weekDays[day.weekday - 1],
                                  style: textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : isToday
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.22)
                                            : Colors.transparent,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: isSelected || isToday
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: isSelected ? Colors.white : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
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
              child: AbsorbPointer(
                absorbing: _swiping,
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
                          .setEventCompleted(
                              eventId: event.id, completed: true);
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

  void _changeWeek(WidgetRef ref, int offset) {
    final selected = ref.read(selectedDayProvider);
    final next = selected.add(Duration(days: 7 * offset));
    ref.read(selectedDayProvider.notifier).state = next;
    // Keep visible month in sync
    if (next.year != ref.read(visibleMonthProvider).year ||
        next.month != ref.read(visibleMonthProvider).month) {
      ref.read(visibleMonthProvider.notifier).state =
          DateTime(next.year, next.month, 1);
    }
  }

  String _weekRangeLabel(DateTime day) {
    final start = day.subtract(Duration(days: day.weekday - 1));
    final end = start.add(const Duration(days: 6));
    final startStr = '${_months[start.month - 1].substring(0, 3)} ${start.day}';
    final endStr = start.month == end.month
        ? '${end.day}'
        : '${_months[end.month - 1].substring(0, 3)} ${end.day}';
    return '$startStr – $endStr, ${end.year}';
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
