enum TaskPriority { high, medium, low }

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.completed,
    required this.priority,
    this.dueDate,
  });

  final int id;
  final String title;
  final bool completed;
  final TaskPriority priority;
  final DateTime? dueDate;
}
