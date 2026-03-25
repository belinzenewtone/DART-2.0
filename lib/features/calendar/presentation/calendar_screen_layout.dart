part of 'calendar_screen.dart';

class _CalendarLayout extends StatelessWidget {
  const _CalendarLayout({
    required this.state,
    required this.textTheme,
    required this.visibleMonth,
    required this.selectedDay,
    required this.eventsState,
    required this.agendaState,
    required this.monthEventTypesState,
    required this.writeState,
    required this.eventsPaneHeight,
    required this.title,
    required this.weekDays,
  });

  final _CalendarScreenState state;
  final TextTheme textTheme;
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final AsyncValue<List<CalendarEvent>> eventsState;
  final AsyncValue<List<CalendarEvent>> agendaState;
  final AsyncValue<Map<int, CalendarEventType>> monthEventTypesState;
  final AsyncValue<void> writeState;
  final double eventsPaneHeight;
  final String title;
  final List<DateTime> weekDays;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageShell(
          scrollable: true,
          glowColor: AppColors.glowBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Calendar',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIconPillButton(
                      icon: Icons.today_rounded,
                      label: 'Today',
                      tone: AppIconPillTone.subtle,
                      onPressed: () {
                        final today = DateTime.now();
                        final todayNorm =
                            DateTime(today.year, today.month, today.day);
                        state.ref.read(selectedDayProvider.notifier).state =
                            todayNorm;
                        state.ref.read(visibleMonthProvider.notifier).state =
                            DateTime(today.year, today.month, 1);
                      },
                    ),
                    const SizedBox(width: 8),
                    AppIconPillButton(
                      icon: state._showAllEvents
                          ? Icons.view_module_rounded
                          : Icons.view_agenda_rounded,
                      label: state._showAllEvents ? 'Calendar' : 'All',
                      tone: state._showAllEvents
                          ? AppIconPillTone.accent
                          : AppIconPillTone.subtle,
                      onPressed: state._toggleAllEvents,
                    ),
                  ],
                ),
              ),
              Center(
                child: SegmentedButton<_CalendarView>(
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
                    ButtonSegment(
                      value: _CalendarView.agenda,
                      icon: Icon(Icons.view_agenda_outlined, size: 18),
                      label: Text('Agenda'),
                    ),
                  ],
                  selected: {state._view},
                  onSelectionChanged: (v) => state._setView(v.first),
                ),
              ),
              if (!state._showAllEvents) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) => state._beginSwipe(),
                  onHorizontalDragEnd: state._handleSwipeEnd,
                  onHorizontalDragCancel: state._cancelSwipe,
                  child: GlassCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  state._view == _CalendarView.month
                                      ? state._changeMonth(state.ref, -1)
                                      : state._changeWeek(state.ref, -1),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: textTheme.titleMedium,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  state._view == _CalendarView.month
                                      ? state._changeMonth(state.ref, 1)
                                      : state._changeWeek(state.ref, 1),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (state._view == _CalendarView.month) ...[
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: _CalendarScreenState
                                    ._calendarContentMaxWidth,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: _CalendarScreenState._weekDays
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
                            maxWidth:
                                _CalendarScreenState._calendarContentMaxWidth,
                            onSelect: (day) {
                              state.ref
                                  .read(selectedDayProvider.notifier)
                                  .state = day;
                            },
                          ),
                        ] else if (state._view == _CalendarView.week) ...[
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final daySize = ((constraints.maxWidth / 7) - 10)
                                  .clamp(24.0, 34.0)
                                  .toDouble();
                              return Row(
                                children: weekDays.map((day) {
                                  final isSelected =
                                      day.year == selectedDay.year &&
                                          day.month == selectedDay.month &&
                                          day.day == selectedDay.day;
                                  final now = DateTime.now();
                                  final isToday = day.year == now.year &&
                                      day.month == now.month &&
                                      day.day == now.day;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        state.ref
                                            .read(selectedDayProvider.notifier)
                                            .state = day;
                                      },
                                      child: Column(
                                        children: [
                                          Text(
                                            _CalendarScreenState
                                                ._weekDays[day.weekday - 1],
                                            style: textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Center(
                                            child: Container(
                                              width: daySize,
                                              height: daySize,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                    : isToday
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                                alpha: 0.22)
                                                        : Colors.transparent,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${day.day}',
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                    fontWeight:
                                                        isSelected || isToday
                                                            ? FontWeight.w700
                                                            : FontWeight.w400,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ] else ...[
                          Row(
                            children: [
                              Icon(
                                Icons.upcoming_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Upcoming 14-day agenda from ${_CalendarScreenState._months[selectedDay.month - 1]} ${selectedDay.day}',
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 12),
              if (state._showAllEvents || state._view == _CalendarView.agenda)
                _CalendarAgendaPane(
                  state: state,
                  selectedDay: selectedDay,
                  agendaState: agendaState,
                  writeState: writeState,
                )
              else ...[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Selected day',
                              style: textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${state._weekdayName(selectedDay.weekday)}, ${_CalendarScreenState._months[selectedDay.month - 1]} ${selectedDay.day.toString().padLeft(2, '0')}',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _CalendarEventsPane(
                        state: state,
                        eventsState: eventsState,
                        selectedDay: selectedDay,
                        writeState: writeState,
                        eventsPaneHeight: eventsPaneHeight,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: AppSpacing.fabBottom(context),
          child: AppFab(
            busy: writeState.isLoading,
            onPressed: () async {
              final input = await showAddEventDialog(
                context,
                selectedDay: selectedDay,
              );
              if (input == null) return;
              await state.ref
                  .read(calendarWriteControllerProvider.notifier)
                  .addEvent(
                    title: input.title,
                    startAt: input.startAt,
                    priority: input.priority,
                    type: input.type,
                    endAt: input.endAt,
                    note: input.note,
                  );
              if (context.mounted &&
                  !state.ref.read(calendarWriteControllerProvider).hasError) {
                AppFeedback.success(context, 'Event added', ref: state.ref);
              }
            },
          ),
        ),
      ],
    );
  }
}
