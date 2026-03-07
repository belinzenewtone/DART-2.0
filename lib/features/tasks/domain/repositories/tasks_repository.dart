import 'package:dart_2_0/features/tasks/domain/entities/task_item.dart';

abstract class TasksRepository {
  Stream<List<TaskItem>> watchTasks();

  Future<void> addTask({
    required String title,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
  });

  Future<void> toggleCompleted({
    required int taskId,
    required bool completed,
  });

  Future<void> updateTask({
    required int taskId,
    required String title,
    required DateTime? dueDate,
    required TaskPriority priority,
  });

  Future<void> deleteTask(int taskId);
}
