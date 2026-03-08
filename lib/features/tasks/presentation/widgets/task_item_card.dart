import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/theme/app_motion.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/tasks/domain/entities/task_item.dart';
import 'package:flutter/material.dart';

class TaskItemCard extends StatelessWidget {
  const TaskItemCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskItem task;
  final Future<void> Function() onToggle;
  final bool busy;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final secondaryText = AppColors.textSecondaryFor(brightness);
    final localizations = MaterialLocalizations.of(context);
    final swipeDuration = AppMotion.swipe(context);
    final resizeDuration = AppMotion.resize(context);
    final priorityColor = _priorityColor(task.priority);
    final isOverdue = !task.completed &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now());
    final dueLabel = task.completed
        ? 'Completed'
        : task.dueDate == null
            ? 'Pending'
            : 'Due ${localizations.formatMediumDate(task.dueDate!)} '
                '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(task.dueDate!), alwaysUse24HourFormat: true)}';

    return Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: busy ? DismissDirection.none : DismissDirection.horizontal,
      movementDuration: swipeDuration,
      resizeDuration: resizeDuration,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.4,
        DismissDirection.endToStart: 0.4,
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await onToggle();
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          await onDelete();
          return false;
        }
        return false;
      },
      background: const _SwipeBackground(
        color: Color(0xFF1E5C2A),
        icon: Icons.check_circle_outline,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const _SwipeBackground(
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
              height: 76,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: busy
                  ? null
                  : () {
                      onToggle();
                    },
              icon: Icon(
                task.completed
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: task.completed ? AppColors.success : secondaryText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: textTheme.bodyLarge?.copyWith(
                      decoration:
                          task.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: secondaryText,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _PriorityBadge(priority: task.priority),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dueLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: task.completed
                                ? AppColors.success
                                : (isOverdue
                                    ? AppColors.danger
                                    : secondaryText),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: busy
                  ? null
                  : () {
                      onEdit();
                    },
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

Color _priorityColor(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.high => AppColors.danger,
    TaskPriority.medium => AppColors.warning,
    TaskPriority.low => AppColors.accent,
  };
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
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
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      TaskPriority.high => ('Urgent', AppColors.danger),
      TaskPriority.medium => ('Important', AppColors.warning),
      TaskPriority.low => ('Neutral', AppColors.accent),
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
