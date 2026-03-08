import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/theme/app_motion.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class CalendarEventsCard extends StatelessWidget {
  const CalendarEventsCard({
    super.key,
    required this.events,
    required this.busy,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CalendarEvent> events;
  final bool busy;
  final Future<void> Function(CalendarEvent event) onComplete;
  final Future<void> Function(CalendarEvent event) onEdit;
  final Future<void> Function(CalendarEvent event) onDelete;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final secondaryText = AppColors.textSecondaryFor(brightness);
    final swipeDuration = AppMotion.swipe(context);
    final resizeDuration = AppMotion.resize(context);
    if (events.isEmpty) {
      return const GlassCard(
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textSecondary),
            SizedBox(width: 10),
            Text('No events on this day'),
          ],
        ),
      );
    }

    return ListView.separated(
      itemBuilder: (context, index) {
        final event = events[index];
        final start =
            '${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')}';
        final end = event.endAt == null
            ? null
            : '${event.endAt!.hour.toString().padLeft(2, '0')}:${event.endAt!.minute.toString().padLeft(2, '0')}';
        final priorityColor = _priorityColor(event.priority);
        final statusLabel = event.completed ? 'Completed' : 'Scheduled';
        return Dismissible(
          key: ValueKey('event-${event.id}'),
          direction: busy ? DismissDirection.none : DismissDirection.horizontal,
          movementDuration: swipeDuration,
          resizeDuration: resizeDuration,
          dismissThresholds: const {
            DismissDirection.startToEnd: 0.4,
            DismissDirection.endToStart: 0.4,
          },
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await onComplete(event);
              return false;
            }
            if (direction == DismissDirection.endToStart) {
              await onDelete(event);
              return false;
            }
            return false;
          },
          background: const _EventSwipeBackground(
            color: Color(0xFF1E5C2A),
            icon: Icons.check_circle_outline,
            alignment: Alignment.centerLeft,
          ),
          secondaryBackground: const _EventSwipeBackground(
            color: Color(0xFF612226),
            icon: Icons.delete_outline,
            alignment: Alignment.centerRight,
          ),
          child: GlassCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 68,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  event.completed
                      ? Icons.check_circle
                      : Icons.event_note_outlined,
                  color: event.completed ? AppColors.success : AppColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              decoration: event.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                      Text(end == null ? start : '$start - $end',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _EventPriorityBadge(priority: event.priority),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: event.completed
                                        ? AppColors.success
                                        : secondaryText,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (event.note != null && event.note!.isNotEmpty)
                        Text(event.note!,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: busy
                      ? null
                      : () {
                          onEdit(event);
                        },
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: events.length,
    );
  }
}

Color _priorityColor(CalendarEventPriority priority) {
  return switch (priority) {
    CalendarEventPriority.high => AppColors.danger,
    CalendarEventPriority.medium => AppColors.warning,
    CalendarEventPriority.low => AppColors.accent,
  };
}

class _EventSwipeBackground extends StatelessWidget {
  const _EventSwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: alignment,
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

class _EventPriorityBadge extends StatelessWidget {
  const _EventPriorityBadge({required this.priority});

  final CalendarEventPriority priority;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      CalendarEventPriority.high => ('Urgent', AppColors.danger),
      CalendarEventPriority.medium => ('Important', AppColors.warning),
      CalendarEventPriority.low => ('Neutral', AppColors.accent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
