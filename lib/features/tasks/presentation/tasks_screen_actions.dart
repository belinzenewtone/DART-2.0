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
  final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => AppFormSheet(
          title: ids.length == 1 ? 'Delete Task?' : 'Delete ${ids.length} Tasks?',
          subtitle: ids.length == 1
              ? 'This action cannot be undone.'
              : 'This will permanently delete ${ids.length} tasks. This cannot be undone.',
          onClose: () => Navigator.of(sheetCtx).pop(false),
          footer: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(sheetCtx).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Delete',
                  variant: AppButtonVariant.danger,
                  icon: Icons.delete_outline_rounded,
                  onPressed: () => Navigator.of(sheetCtx).pop(true),
                ),
              ),
            ],
          ),
          child: const SizedBox.shrink(),
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
