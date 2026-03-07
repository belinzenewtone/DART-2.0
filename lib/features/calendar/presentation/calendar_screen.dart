import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/widgets/action_button.dart';
import 'package:dart_2_0/core/widgets/error_message.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/core/widgets/loading_indicator.dart';
import 'package:dart_2_0/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:dart_2_0/features/calendar/presentation/widgets/calendar_events_card.dart';
import 'package:dart_2_0/features/calendar/presentation/widgets/event_dialogs.dart';
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
    final writeState = ref.watch(calendarWriteControllerProvider);

    ref.listen<AsyncValue<void>>(calendarWriteControllerProvider,
        (previous, next) {
      if (previous is AsyncLoading && next is AsyncData<void>) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event added')),
        );
      } else if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add event')),
        );
      }
    });

    final title = '${_months[visibleMonth.month - 1]} ${visibleMonth.year}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calendar', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            GlassCard(
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
                                child: Text(day,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CalendarGrid(
                    visibleMonth: visibleMonth,
                    selectedDay: selectedDay,
                    maxWidth: _calendarContentMaxWidth,
                    onSelect: (day) {
                      ref.read(selectedDayProvider.notifier).state = day;
                    },
                  ),
                ],
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
                error: (_, __) =>
                    const ErrorMessage(label: 'Unable to load events'),
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
      'Sunday'
    ];
    return weekdays[weekday - 1];
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.visibleMonth,
    required this.selectedDay,
    required this.maxWidth,
    required this.onSelect,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final double maxWidth;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final totalDays =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final leadingBlanks =
        DateTime(visibleMonth.year, visibleMonth.month, 1).weekday - 1;
    final totalItems = ((leadingBlanks + totalDays + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GridView.builder(
          itemCount: totalItems,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 42,
          ),
          itemBuilder: (context, index) {
            final day = index - leadingBlanks + 1;
            if (day < 1 || day > totalDays) {
              return const SizedBox.shrink();
            }

            final current = DateTime(visibleMonth.year, visibleMonth.month, day);
            final isSelected = selectedDay.year == current.year &&
                selectedDay.month == current.month &&
                selectedDay.day == current.day;
            final isToday = today.year == current.year &&
                today.month == current.month &&
                today.day == current.day;
            final dotColor = isSelected ? AppColors.textPrimary : AppColors.accent;

            return Center(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onSelect(current),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accent : Colors.transparent,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: textTheme.bodyLarge?.copyWith(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isToday)
                        Positioned(
                          bottom: 6,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
