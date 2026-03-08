import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/theme/app_spacing.dart';
import 'package:dart_2_0/core/widgets/action_button.dart';
import 'package:dart_2_0/core/widgets/app_feedback.dart';
import 'package:dart_2_0/core/widgets/category_chip.dart';
import 'package:dart_2_0/core/widgets/error_message.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/core/widgets/loading_indicator.dart';
import 'package:dart_2_0/features/tasks/domain/entities/task_item.dart';
import 'package:dart_2_0/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:dart_2_0/features/tasks/presentation/widgets/task_item_card.dart';
import 'package:dart_2_0/features/tasks/presentation/widgets/task_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final tasksState = ref.watch(filteredTasksProvider);
    final allTasksState = ref.watch(tasksProvider);
    final selectedFilter = ref.watch(taskFilterProvider);
    final writeState = ref.watch(taskWriteControllerProvider);

    ref.listen<AsyncValue<void>>(taskWriteControllerProvider, (previous, next) {
      if (previous is AsyncLoading && next is AsyncData<void>) {
        AppFeedback.success(context, 'Task changes saved successfully.');
      } else if (next.hasError) {
        AppFeedback.error(context, 'Task action failed. Please try again.');
      }
    });

    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tasks', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _buildCountSubtitle(allTasksState),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskFilter.values
                  .map(
                    (filter) => CategoryChip(
                      label: _filterLabel(filter),
                      selected: selectedFilter == filter,
                      onTap: () {
                        ref.read(taskFilterProvider.notifier).state = filter;
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: tasksState.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const GlassCard(
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('No tasks in this filter'),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemBuilder: (_, index) => TaskItemCard(
                      task: tasks[index],
                      busy: writeState.isLoading,
                      onToggle: () async {
                        await ref
                            .read(taskWriteControllerProvider.notifier)
                            .toggleTask(
                              taskId: tasks[index].id,
                              completed: !tasks[index].completed,
                            );
                      },
                      onEdit: () async {
                        final input = await showEditTaskDialog(context,
                            task: tasks[index]);
                        if (input == null) {
                          return;
                        }
                        await ref
                            .read(taskWriteControllerProvider.notifier)
                            .updateTask(
                              taskId: tasks[index].id,
                              title: input.title,
                              description: input.description,
                              dueDate: input.dueDate,
                              priority: input.priority,
                            );
                      },
                      onDelete: () async {
                        await ref
                            .read(taskWriteControllerProvider.notifier)
                            .deleteTask(
                              tasks[index].id,
                            );
                      },
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: tasks.length,
                  );
                },
                loading: () => const Center(child: LoadingIndicator()),
                error: (_, __) => ErrorMessage(
                  label: 'Unable to load tasks',
                  onRetry: () => ref.invalidate(filteredTasksProvider),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ActionButton(
                icon: Icons.add_task,
                isLoading: writeState.isLoading,
                onPressed: writeState.isLoading
                    ? null
                    : () async {
                        final input = await showAddTaskDialog(context);
                        if (input == null) {
                          return;
                        }
                        await ref
                            .read(taskWriteControllerProvider.notifier)
                            .addTask(
                              title: input.title,
                              description: input.description,
                              dueDate: input.dueDate,
                              priority: input.priority,
                            );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(TaskFilter filter) {
    return switch (filter) {
      TaskFilter.all => 'All',
      TaskFilter.pending => 'Pending',
      TaskFilter.completed => 'Completed',
    };
  }

  String _buildCountSubtitle(AsyncValue<List<TaskItem>> tasksState) {
    final tasks = tasksState.valueOrNull;
    if (tasks == null) {
      return 'Loading tasks...';
    }
    final pending = tasks.where((task) => !task.completed).length;
    final completed = tasks.where((task) => task.completed).length;
    return '$pending pending · $completed completed';
  }
}
