part of 'tasks_screen.dart';

Future<void> _completeSelectedImpl(
  _TasksScreenState state,
  BuildContext context,
) async {
  final ids = state._selectedTaskIds.toList(growable: false);
  if (ids.isEmpty) {
    return;
  }
  final count = await state.ref
      .read(taskWriteControllerProvider.notifier)
      .completeTasks(ids);
  if (!context.mounted) {
    return;
  }
  if (!state.ref.read(taskWriteControllerProvider).hasError) {
    AppFeedback.success(
      context,
      count == 1 ? '1 task completed' : '$count tasks completed',
      ref: state.ref,
    );
    state._clearSelectionState();
  }
}

Future<void> _archiveSelectedImpl(
  _TasksScreenState state,
  BuildContext context,
) async {
  final ids = state._selectedTaskIds.toList(growable: false);
  if (ids.isEmpty) {
    return;
  }
  final count = await state.ref
      .read(taskWriteControllerProvider.notifier)
      .archiveTasks(ids);
  if (!context.mounted) {
    return;
  }
  if (!state.ref.read(taskWriteControllerProvider).hasError) {
    AppFeedback.success(
      context,
      count == 1
          ? '1 task archived to completed'
          : '$count tasks archived to completed',
      ref: state.ref,
    );
    state._clearSelectionState();
  }
}

Future<void> _deleteSelectedImpl(
  _TasksScreenState state,
  BuildContext context,
) async {
  final ids = state._selectedTaskIds.toList(growable: false);
  if (ids.isEmpty) {
    return;
  }
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete selected tasks?'),
          content: Text(
            ids.length == 1
                ? 'This action cannot be undone.'
                : 'This will permanently delete ${ids.length} tasks.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed) {
    return;
  }
  final count = await state.ref
      .read(taskWriteControllerProvider.notifier)
      .deleteTasks(ids);
  if (!context.mounted) {
    return;
  }
  if (!state.ref.read(taskWriteControllerProvider).hasError) {
    AppFeedback.success(
      context,
      count == 1 ? '1 task deleted' : '$count tasks deleted',
      ref: state.ref,
    );
    state._clearSelectionState();
  }
}
