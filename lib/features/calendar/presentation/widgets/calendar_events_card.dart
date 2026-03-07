import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class CalendarEventsCard extends StatelessWidget {
  const CalendarEventsCard({
    super.key,
    required this.events,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CalendarEvent> events;
  final bool busy;
  final Future<void> Function(CalendarEvent event) onEdit;
  final Future<void> Function(CalendarEvent event) onDelete;

  @override
  Widget build(BuildContext context) {
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

    return GlassCard(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final event = events[index];
          final start =
              '${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')}';
          final end = event.endAt == null
              ? null
              : '${event.endAt!.hour.toString().padLeft(2, '0')}:${event.endAt!.minute.toString().padLeft(2, '0')}';
          return Dismissible(
            key: ValueKey('event-${event.id}'),
            direction:
                busy ? DismissDirection.none : DismissDirection.horizontal,
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                await onEdit(event);
                return false;
              }
              if (direction == DismissDirection.endToStart) {
                await onDelete(event);
                return false;
              }
              return false;
            },
            background: const _EventSwipeBackground(
              color: Color(0xFF57411D),
              icon: Icons.edit_outlined,
              alignment: Alignment.centerLeft,
            ),
            secondaryBackground: const _EventSwipeBackground(
              color: Color(0xFF612226),
              icon: Icons.delete_outline,
              alignment: Alignment.centerRight,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.event_note_outlined, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title,
                          style: Theme.of(context).textTheme.bodyLarge),
                      Text(end == null ? start : '$start - $end',
                          style: Theme.of(context).textTheme.bodyMedium),
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
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: events.length,
      ),
    );
  }
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
