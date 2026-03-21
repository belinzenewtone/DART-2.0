part of 'tasks_screen.dart';

class _TasksLayout extends StatelessWidget {
  const _TasksLayout({
    required this.state,
    required this.tasksState,
    required this.allTasks,
    required this.selectedFilter,
    required this.writeState,
    required this.countSubtitle,
  });

  final _TasksScreenState state;
  final AsyncValue<List<TaskItem>> tasksState;
  final List<TaskItem> allTasks;
  final TaskFilter selectedFilter;
  final AsyncValue<void> writeState;
  final String countSubtitle;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      scrollable: false,
      glowColor: AppColors.glowViolet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            eyebrow: 'FOCUS',
            title: 'Tasks',
            subtitle: countSubtitle,
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!state._selectionMode)
                  IconButton(
                    tooltip: 'Search',
                    onPressed: state._toggleSearch,
                    icon: const Icon(Icons.search_rounded),
                  ),
                if (state._selectionMode)
                  IconButton(
                    tooltip: allTasks.isEmpty
                        ? 'Select all'
                        : state._selectedTaskIds.length == allTasks.length
                            ? 'Clear selection'
                            : 'Select all',
                    onPressed: writeState.isLoading || allTasks.isEmpty
                        ? null
                        : () => state._toggleSelectAll(allTasks),
                    icon: Icon(
                      state._selectedTaskIds.length == allTasks.length
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                    ),
                  ),
                IconButton(
                  tooltip: state._selectionMode
                      ? 'Exit multi-select'
                      : 'Select multiple tasks',
                  onPressed: writeState.isLoading
                      ? null
                      : state._toggleSelectionMode,
                  icon: Icon(
                    state._selectionMode
                        ? Icons.close_rounded
                        : Icons.checklist_rtl_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Add task',
                  onPressed: writeState.isLoading || state._selectionMode
                      ? null
                      : () async {
                          final input = await showAddTaskDialog(context);
                          if (input == null) {
                            return;
                          }
                          await state.ref
                              .read(taskWriteControllerProvider.notifier)
                              .addTask(
                                title: input.title,
                                description: input.description,
                                dueDate: input.dueDate,
                                priority: input.priority,
                              );
                          if (context.mounted &&
                              !state
                                  .ref
                                  .read(taskWriteControllerProvider)
                                  .hasError) {
                            AppFeedback.success(context, 'Task added', ref: state.ref);
                          }
                        },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
          if (state._showSearch) ...[
            AppSearchBar(
              controller: state._searchController,
              hint: 'Search tasks...',
              onChanged: (_) => state._refreshSearchResults(),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
          if (state._selectionMode) ...[
            TaskSelectionBar(
              selectedCount: state._selectedTaskIds.length,
              isLoading: writeState.isLoading,
              onComplete: () => state._completeSelected(context),
              onArchive: () => state._archiveSelected(context),
              onDelete: () => state._deleteSelected(context),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: TaskFilter.values.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    label: state._filterLabel(filter),
                    selected: selectedFilter == filter,
                    onTap: () {
                      state.ref.read(taskFilterProvider.notifier).state =
                          filter;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          if (allTasks.isNotEmpty)
            _TaskPulseBar(tasks: allTasks),
          if (allTasks.isNotEmpty)
            const SizedBox(height: AppSpacing.sectionGap),
          Expanded(
            child: tasksState.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.task_alt_rounded,
                    title: 'No tasks here',
                    subtitle: 'Tap + to add your first task',
                  );
                }
                return ListView.separated(
                  itemBuilder: (_, index) => TaskItemCard(
                    task: tasks[index],
                    selectionMode: state._selectionMode,
                    selected: state._selectedTaskIds.contains(tasks[index].id),
                    onSelectToggle: () =>
                        state._toggleTaskSelection(tasks[index].id),
                    busy: writeState.isLoading,
                    onToggle: () async {
                      if (state._selectionMode) {
                        state._toggleTaskSelection(tasks[index].id);
                        return;
                      }
                      final isCompleting = !tasks[index].completed;
                      await state.ref
                          .read(taskWriteControllerProvider.notifier)
                          .toggleTask(
                            taskId: tasks[index].id,
                            completed: isCompleting,
                          );
                      if (context.mounted &&
                          !state.ref.read(taskWriteControllerProvider).hasError) {
                        AppFeedback.success(
                          context,
                          isCompleting
                              ? 'Task completed ✓'
                              : 'Task marked as pending',
                          ref: state.ref,
                        );
                      }
                    },
                    onEdit: () async {
                      await state._editTask(context, tasks[index]);
                    },
                    onDelete: () async {
                      if (state._selectionMode) {
                        state._toggleTaskSelection(tasks[index].id);
                        return;
                      }
                      final deletedTask = tasks[index];
                      AppHaptics.mediumImpact();
                      await state.ref
                          .read(taskWriteControllerProvider.notifier)
                          .deleteTask(deletedTask.id);
                      if (!context.mounted) return;
                      if (state.ref.read(taskWriteControllerProvider).hasError) return;
                      // Show undo snackbar
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      if (messenger == null) return;
                      messenger.hideCurrentSnackBar();
                      final keyboardInset =
                          MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0;
                      final snackResult = await messenger.showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Task deleted',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {},
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.fromLTRB(
                              16, 0, 16, 88 + keyboardInset),
                          duration: const Duration(seconds: 4),
                        ),
                      ).closed;
                      if (snackResult == SnackBarClosedReason.action &&
                          context.mounted) {
                        await state.ref
                            .read(taskWriteControllerProvider.notifier)
                            .addTask(
                              title: deletedTask.title,
                              description: deletedTask.description,
                              dueDate: deletedTask.dueDate,
                              priority: deletedTask.priority,
                            );
                      }
                    },
                  ),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.listGap),
                  itemCount: tasks.length,
                );
              },
              loading: () => Column(
                children: List.generate(5, (_) => const TaskCardSkeleton())
                    .expand((element) => [
                          element,
                          const SizedBox(height: AppSpacing.listGap),
                        ])
                    .toList(),
              ),
              error: (_, __) => ErrorMessage(
                label: 'Unable to load tasks',
                onRetry: () => state.ref.invalidate(filteredTasksProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task Pulse bar ────────────────────────────────────────────────────────────

class _TaskPulseBar extends StatelessWidget {
  const _TaskPulseBar({required this.tasks});
  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    if (total == 0) return const SizedBox.shrink();

    final done = tasks.where((t) => t.completed).length;
    final open = total - done;
    final doneRatio = done / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _PulseCount(value: open, label: 'Open', color: AppColors.accent),
            const Spacer(),
            _PulseCount(
              value: done,
              label: 'Done',
              color: AppColors.success,
              alignRight: true,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: SizedBox(
            height: 5,
            child: LinearProgressIndicator(
              value: doneRatio,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
        ),
      ],
    );
  }
}

class _PulseCount extends StatelessWidget {
  const _PulseCount({
    required this.value,
    required this.label,
    required this.color,
    this.alignRight = false,
  });

  final int value;
  final String label;
  final Color color;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final children = [
      Text(
        '$value',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: AppTypography.metaText(context),
      ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: alignRight ? children.reversed.toList() : children,
    );
  }
}
