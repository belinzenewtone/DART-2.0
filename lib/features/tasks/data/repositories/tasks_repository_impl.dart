import 'package:dart_2_0/data/local/drift/app_drift_store.dart';
import 'package:dart_2_0/data/local/drift/app_drift_store_mutations.dart';
import 'package:dart_2_0/features/tasks/domain/entities/task_item.dart';
import 'package:dart_2_0/features/tasks/domain/repositories/tasks_repository.dart';

class TasksRepositoryImpl implements TasksRepository {
  TasksRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<List<TaskItem>> watchTasks() {
    return _store.watchTasks().map(
          (rows) => rows
              .map(
                (row) => TaskItem(
                  id: row.id,
                  title: row.title,
                  completed: row.completed,
                  priority: _toPriority(row.priority),
                  dueDate: row.dueDate,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> addTask({
    required String title,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    await _store.addTask(
      title: title,
      dueDate: dueDate,
      priority: priority.name,
    );
  }

  @override
  Future<void> toggleCompleted({
    required int taskId,
    required bool completed,
  }) async {
    await _store.toggleTaskCompletion(
      taskId: taskId,
      completed: completed,
    );
  }

  @override
  Future<void> updateTask({
    required int taskId,
    required String title,
    required DateTime? dueDate,
    required TaskPriority priority,
  }) async {
    await _store.updateTask(
      id: taskId,
      title: title,
      dueDate: dueDate,
      priority: priority.name,
    );
  }

  @override
  Future<void> deleteTask(int taskId) {
    return _store.deleteTask(taskId);
  }

  TaskPriority _toPriority(String value) {
    return switch (value.toLowerCase()) {
      'high' => TaskPriority.high,
      'low' => TaskPriority.low,
      _ => TaskPriority.medium,
    };
  }
}
