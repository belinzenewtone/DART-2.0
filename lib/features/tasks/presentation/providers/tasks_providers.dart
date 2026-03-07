import 'dart:async';

import 'package:dart_2_0/core/di/notification_providers.dart';
import 'package:dart_2_0/core/notifications/local_notification_service.dart';
import 'package:dart_2_0/core/di/repository_providers.dart';
import 'package:dart_2_0/features/tasks/domain/entities/task_item.dart';
import 'package:dart_2_0/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TaskFilter { all, pending, completed }

final taskFilterProvider = StateProvider<TaskFilter>((_) => TaskFilter.all);

final tasksProvider = StreamProvider<List<TaskItem>>(
  (ref) => ref.watch(tasksRepositoryProvider).watchTasks(),
);

final filteredTasksProvider = Provider<AsyncValue<List<TaskItem>>>((ref) {
  final tasksState = ref.watch(tasksProvider);
  final filter = ref.watch(taskFilterProvider);
  return tasksState.whenData((tasks) {
    return switch (filter) {
      TaskFilter.pending => tasks.where((task) => !task.completed).toList(),
      TaskFilter.completed => tasks.where((task) => task.completed).toList(),
      TaskFilter.all => tasks,
    };
  });
});

class TaskWriteController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addQuickTask() async {
    final now = DateTime.now();
    await addTask(
      title: 'New Task ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      dueDate: now.add(const Duration(days: 1)),
      priority: TaskPriority.medium,
    );
  }

  Future<void> addTask({
    required String title,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    final repository = ref.read(tasksRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.addTask(
        title: title,
        dueDate: dueDate,
        priority: priority,
      );
      if (dueDate != null) {
        await _scheduleCreatedTaskReminder(
          repository: repository,
          notifications: notifications,
          title: title,
          dueDate: dueDate,
          priority: priority,
        );
      }
    });
  }

  Future<void> toggleTask({
    required int taskId,
    required bool completed,
  }) async {
    final repository = ref.read(tasksRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    final tasks = await repository.watchTasks().first;
    final taskBeforeChange =
        tasks.where((item) => item.id == taskId).firstOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.toggleCompleted(
        taskId: taskId,
        completed: completed,
      );
      if (completed) {
        await notifications.cancelTaskReminder(taskId);
      } else if (taskBeforeChange?.dueDate != null) {
        await notifications.scheduleTaskReminder(
          taskId: taskId,
          title: taskBeforeChange!.title,
          dueDate: taskBeforeChange.dueDate!,
        );
      }
    });
  }

  Future<void> updateTask({
    required int taskId,
    required String title,
    required DateTime? dueDate,
    required TaskPriority priority,
  }) async {
    final repository = ref.read(tasksRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.updateTask(
        taskId: taskId,
        title: title,
        dueDate: dueDate,
        priority: priority,
      );
      if (dueDate == null) {
        await notifications.cancelTaskReminder(taskId);
      } else {
        await notifications.scheduleTaskReminder(
          taskId: taskId,
          title: title,
          dueDate: dueDate,
        );
      }
    });
  }

  Future<void> deleteTask(int taskId) async {
    final repository = ref.read(tasksRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await notifications.cancelTaskReminder(taskId);
      await repository.deleteTask(taskId);
    });
  }

  Future<void> _scheduleCreatedTaskReminder({
    required TasksRepository repository,
    required LocalNotificationService notifications,
    required String title,
    required DateTime dueDate,
    required TaskPriority priority,
  }) async {
    try {
      final tasks = await repository.watchTasks().first;
      final created = tasks.where((task) {
        if (task.title != title || task.priority != priority) {
          return false;
        }
        final due = task.dueDate;
        if (due == null) {
          return false;
        }
        return due.year == dueDate.year &&
            due.month == dueDate.month &&
            due.day == dueDate.day;
      }).firstOrNull;
      if (created == null || created.dueDate == null) {
        return;
      }
      await notifications.scheduleTaskReminder(
        taskId: created.id,
        title: created.title,
        dueDate: created.dueDate!,
      );
    } catch (_) {
      return;
    }
  }
}

final taskWriteControllerProvider =
    AutoDisposeAsyncNotifierProvider<TaskWriteController, void>(
  TaskWriteController.new,
);
