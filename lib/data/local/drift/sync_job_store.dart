import 'package:beltech/core/sync/cloud_sync_job.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';

class SyncJobStore {
  SyncJobStore(this._store);

  final AppDriftStore _store;

  Future<void> ensureInitialized() async {
    await _store.ensureInitialized();
    await _store.executor.runCustom(
      'CREATE TABLE IF NOT EXISTS sync_jobs('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'job_type TEXT NOT NULL,'
      'entity_type TEXT NOT NULL,'
      'entity_id INTEGER NOT NULL,'
      'payload TEXT,'
      'status TEXT NOT NULL DEFAULT \'queued\','
      'attempt_count INTEGER NOT NULL DEFAULT 0,'
      'last_error TEXT,'
      'created_at INTEGER NOT NULL,'
      'updated_at INTEGER NOT NULL'
      ')',
    );
    await _store.executor.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_sync_jobs_status ON sync_jobs(status)',
    );
    await _store.executor.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_sync_jobs_entity ON sync_jobs(entity_type, entity_id)',
    );
  }

  Future<void> enqueue(SyncJob job) async {
    await ensureInitialized();
    await _store.executor.runInsert(
      'INSERT INTO sync_jobs(job_type, entity_type, entity_id, payload, status, attempt_count, last_error, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        job.jobType.name,
        job.entityType,
        job.entityId,
        job.payload,
        job.status.name,
        job.attemptCount,
        job.lastError,
        job.createdAt,
        job.updatedAt,
      ],
    );
  }

  Future<List<SyncJob>> fetchPending({int limit = 50}) async {
    await ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT id, job_type, entity_type, entity_id, payload, status, attempt_count, last_error, created_at, updated_at '
      'FROM sync_jobs WHERE status = ? ORDER BY created_at ASC LIMIT ?',
      [SyncJobStatus.queued.name, limit],
    );
    return rows.map(_rowToJob).toList();
  }

  Future<void> updateStatus(
    int id,
    SyncJobStatus status, {
    String? error,
  }) async {
    await ensureInitialized();
    final now = DateTime.now().millisecondsSinceEpoch;
    final sets = <String>['status = ?', 'updated_at = ?'];
    final args = <Object?>[status.name, now];
    if (error != null) {
      sets.add('last_error = ?');
      args.add(error);
    }
    args.add(id);
    await _store.executor.runUpdate(
      'UPDATE sync_jobs SET ${sets.join(', ')} WHERE id = ?',
      args,
    );
  }

  Future<void> incrementAttempt(int id) async {
    await ensureInitialized();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _store.executor.runUpdate(
      'UPDATE sync_jobs SET attempt_count = attempt_count + 1, updated_at = ? WHERE id = ?',
      [now, id],
    );
  }

  Future<void> removeCompleted(int olderThanMs) async {
    await ensureInitialized();
    await _store.executor.runDelete(
      'DELETE FROM sync_jobs WHERE status IN (?, ?) AND updated_at < ?',
      [SyncJobStatus.synced.name, SyncJobStatus.failed.name, olderThanMs],
    );
  }

  Future<bool> hasDuplicateActive(
    SyncJobType type,
    String entityType,
    int entityId,
  ) async {
    await ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT COUNT(*) as cnt FROM sync_jobs '
      'WHERE job_type = ? AND entity_type = ? AND entity_id = ? '
      'AND status IN (?, ?)',
      [
        type.name,
        entityType,
        entityId,
        SyncJobStatus.queued.name,
        SyncJobStatus.syncing.name,
      ],
    );
    final cnt = rows.firstOrNull?['cnt'];
    return _asInt(cnt) > 0;
  }

  SyncJob _rowToJob(Map<String, dynamic> row) {
    return SyncJob(
      id: _asInt(row['id']),
      jobType: SyncJobType.values.byName(row['job_type'] as String),
      entityType: row['entity_type'] as String,
      entityId: _asInt(row['entity_id']),
      payload: row['payload'] as String?,
      status: SyncJobStatus.values.byName(row['status'] as String),
      attemptCount: _asInt(row['attempt_count']),
      lastError: row['last_error'] as String?,
      createdAt: _asInt(row['created_at']),
      updatedAt: _asInt(row['updated_at']),
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
