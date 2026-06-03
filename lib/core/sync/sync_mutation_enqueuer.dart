import 'dart:convert';

import 'package:beltech/core/sync/cloud_sync_job.dart';
import 'package:beltech/data/local/drift/sync_job_store.dart';

class SyncMutationEnqueuer {
  SyncMutationEnqueuer(this._store);

  final SyncJobStore _store;

  Future<void> enqueuePush(
    String entityType,
    int entityId,
    Map<String, dynamic> data,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final isDuplicate = await _store.hasDuplicateActive(
      SyncJobType.push,
      entityType,
      entityId,
    );
    if (isDuplicate) return;

    await _store.enqueue(
      SyncJob(
        jobType: SyncJobType.push,
        entityType: entityType,
        entityId: entityId,
        payload: jsonEncode(data),
        status: SyncJobStatus.queued,
        attemptCount: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> enqueuePull(String entityType, int entityId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final isDuplicate = await _store.hasDuplicateActive(
      SyncJobType.pull,
      entityType,
      entityId,
    );
    if (isDuplicate) return;

    await _store.enqueue(
      SyncJob(
        jobType: SyncJobType.pull,
        entityType: entityType,
        entityId: entityId,
        status: SyncJobStatus.queued,
        attemptCount: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
