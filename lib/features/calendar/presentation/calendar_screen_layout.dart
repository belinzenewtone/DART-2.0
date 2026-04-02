part of 'calendar_screen.dart';

class _CalendarLayout extends StatelessWidget {
  const _CalendarLayout({
    required this.state,
    required this.textTheme,
    required this.visibleMonth,
    required this.selectedDay,
    required this.eventsState,
    required this.tasksState,
    required this.monthEventTypesState,
    required this.writeState,
    required this.title,
  });

  final _CalendarScreenState state;
  final TextTheme textTheme;
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final AsyncValue<List<CalendarEvent>> eventsState;
  final AsyncValue<List<TaskItem>> tasksState;
  final AsyncValue<Map<int, CalendarEventType>> monthEventTypesState;
  final AsyncValue<void> writeState;
  final String title;

  @override
  Widget build(BuildContext context) {
    final monthTaskDays = (tasksState.valueOrNull ?? const <TaskItem>[])
        .where((task) {
          final dueDate = task.dueDate;
          return dueDate != null &&
              dueDate.year == visibleMonth.year &&
              dueDate.month == visibleMonth.month;
        })
        .map((task) => task.dueDate!.day)
        .toSet();

    final dayEvents = eventsState.valueOrNull ?? const <CalendarEvent>[];
    final completedEvents = dayEvents.where((event) => event.completed).length;
    final pendingEvents = dayEvents.length - completedEvents;

    final dayTasks = (tasksState.valueOrNull ?? const <TaskItem>[])
        .where(
          (task) =>
              task.dueDate != null && _isSameDate(task.dueDate!, selectedDay),
        )
        .toList(growable: false);
    final completedTasks = dayTasks.where((task) => task.completed).length;
    final pendingTasks = dayTasks.length - completedTasks;

    return Stack(
      children: [
        PageShell(
          scrollable: true,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Calendar',
                action: AppIconPillButton(
                  icon: Icons.today_rounded,
                  label: 'Today',
                  tone: AppIconPillTone.subtle,
                  onPressed: () {
                    final today = DateTime.now();
                    final todayNorm = DateTime(
                      today.year,
                      today.month,
                      today.day,
                    );
                    state.ref.read(selectedDayProvider.notifier).state =
                        todayNorm;
                    state.ref.read(visibleMonthProvider.notifier).state =
                        DateTime(today.year, today.month, 1);
                  },
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
                      value: _CalendarView.events,
                      icon: Icon(Icons.event_outlined, size: 18),
                      label: Text('Events'),
                    ),
                    ButtonSegment(
                      value: _CalendarView.tasks,
                      icon: Icon(Icons.task_alt_outlined, size: 18),
                      label: Text('Tasks'),
                    ),
                  ],
                  selected: {state._view},
                  onSelectionChanged: (v) => state._setView(v.first),
                ),
              ),
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
                            onPressed: () => state._changeMonth(state.ref, -1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
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
                            onPressed: () => state._changeMonth(state.ref, 1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth:
                                _CalendarScreenState._calendarContentMaxWidth,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        taskDays: monthTaskDays,
                        maxWidth: _CalendarScreenState._calendarContentMaxWidth,
                        onSelect: (day) {
                          state.ref.read(selectedDayProvider.notifier).state =
                              day;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (state._view == _CalendarView.events)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CalendarSectionHeader(
                        title: 'Events',
                        dateLabel:
                            '${_calendarWeekdayName(selectedDay.weekday)}, ${_CalendarScreenState._months[selectedDay.month - 1]} ${selectedDay.day.toString().padLeft(2, '0')}',
                        pendingCount: pendingEvents,
                        completedCount: completedEvents,
                        showCompleted: state._showCompletedEvents,
                        onToggleCompleted:
                            state._toggleCompletedEventsVisibility,
                      ),
                      const SizedBox(height: 8),
                      _CalendarEventsPane(
                        state: state,
                        eventsState: eventsState,
                        selectedDay: selectedDay,
                        writeState: writeState,
                      ),
                    ],
                  ),
                )
              else if (state._view == _CalendarView.tasks)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CalendarSectionHeader(
                        title: 'Tasks',
                        dateLabel:
                            '${_calendarWeekdayName(selectedDay.weekday)}, ${_CalendarScreenState._months[selectedDay.month - 1]} ${selectedDay.day.toString().padLeft(2, '0')}',
                        pendingCount: pendingTasks,
                        completedCount: completedTasks,
                        showCompleted: state._showCompletedTasks,
                        onToggleCompleted:
                            state._toggleCompletedTasksVisibility,
                      ),
                      const SizedBox(height: 8),
                      _CalendarTasksPane(
                        state: state,
                        selectedDay: selectedDay,
                        tasksState: tasksState,
                      ),
                    ],
                  ),
                )
              else
                const GlassCard(
                  child: AppEmptyState(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Choose Events or Tasks',
                    subtitle:
                        'Switch tabs above to view what is scheduled for the selected day.',
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: AppSpacing.fabBottom(context),
          child: AppFab(
            busy: writeState.isLoading,
            onPressed: () => _handleSuperAddFromCalendarImpl(
              state,
              context,
              selectedDay,
              defaultKind: state._view == _CalendarView.tasks
                  ? SuperEntryKind.task
                  : SuperEntryKind.event,
            ),
          ),
        ),
      ],
    );
  }
}
