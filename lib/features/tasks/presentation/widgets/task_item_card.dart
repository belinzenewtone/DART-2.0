import 'package:dart_2_0/core/theme/app_colors.dart';
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
    final localizations = MaterialLocalizations.of(context);
    final dueLabel = task.completed
        ? 'Completed'
        : task.dueDate == null
            ? 'Pending'
            : 'Due ${localizations.formatMediumDate(task.dueDate!)} '
                '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(task.dueDate!), alwaysUse24HourFormat: true)}';

    return Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: busy ? DismissDirection.none : DismissDirection.horizontal,
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
          children: [
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
                color: task.completed ? AppColors.success : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dueLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: task.completed
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PriorityBadge(priority: task.priority),
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
      TaskPriority.high => ('High', AppColors.danger),
      TaskPriority.medium => ('Medium', AppColors.warning),
      TaskPriority.low => ('Low', AppColors.success),
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
