part of 'calendar_screen.dart';

class _CalendarWeekStrip extends StatelessWidget {
  const _CalendarWeekStrip({
    required this.weekDays,
    required this.selectedDay,
    required this.textTheme,
    required this.onSelect,
  });

  final List<DateTime> weekDays;
  final DateTime selectedDay;
  final TextTheme textTheme;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
            final isToday =
                day.year == now.year &&
                day.month == now.month &&
                day.day == now.day;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(day),
                child: Column(
                  children: [
                    Text(
                      _CalendarScreenState._weekDays[day.weekday - 1],
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
                              ? Theme.of(context).colorScheme.primary
                              : isToday
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.22)
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
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
