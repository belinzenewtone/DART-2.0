import 'package:dart_2_0/data/local/drift/app_drift_store.dart';

extension AppDriftStoreMutations on AppDriftStore {
  Future<void> updateTransaction({
    required int id,
    required String title,
    required String category,
    required double amountKes,
    required DateTime occurredAt,
  }) async {
    await ensureInitialized();
    await executor.runUpdate(
      'UPDATE transactions SET title = ?, category = ?, amount = ?, occurred_at = ?, source = ?, source_hash = NULL WHERE id = ?',
      [
        title,
        category,
        amountKes,
        occurredAt.millisecondsSinceEpoch,
        'manual',
        id
      ],
    );
    emitChange();
  }

  Future<void> deleteTransaction(int id) async {
    await ensureInitialized();
    await executor.runDelete('DELETE FROM transactions WHERE id = ?', [id]);
    emitChange();
  }

  Future<void> updateTask({
    required int id,
    required String title,
    required DateTime? dueDate,
    required String priority,
  }) async {
    await ensureInitialized();
    await executor.runUpdate(
      'UPDATE tasks SET title = ?, due_at = ?, priority = ? WHERE id = ?',
      [title, dueDate?.millisecondsSinceEpoch, priority, id],
    );
    emitChange();
  }

  Future<void> deleteTask(int id) async {
    await ensureInitialized();
    await executor.runDelete('DELETE FROM tasks WHERE id = ?', [id]);
    emitChange();
  }

  Future<void> updateEvent({
    required int id,
    required String title,
    required DateTime startAt,
    required DateTime? endAt,
    String? note,
  }) async {
    await ensureInitialized();
    await executor.runUpdate(
      'UPDATE events SET title = ?, start_at = ?, end_at = ?, note = ? WHERE id = ?',
      [
        title,
        startAt.millisecondsSinceEpoch,
        endAt?.millisecondsSinceEpoch,
        note,
        id
      ],
    );
    emitChange();
  }

  Future<void> deleteEvent(int id) async {
    await ensureInitialized();
    await executor.runDelete('DELETE FROM events WHERE id = ?', [id]);
    emitChange();
  }
}
