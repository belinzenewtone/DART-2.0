import 'dart:convert';

import 'package:beltech/core/config/supabase_config.dart';
import 'package:beltech/core/sync/cloud_sync_job.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/data/local/drift/sync_job_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudSyncDispatcher {
  CloudSyncDispatcher(
    this._jobStore,
    this._localStore, [
    SupabaseClient? client,
  ]) : _client = client;

  final SyncJobStore _jobStore;
  final AppDriftStore _localStore;
  SupabaseClient? _client;

  SupabaseClient get _requireClient {
    if (_client != null) return _client!;
    return Supabase.instance.client;
  }

  static const int _maxRetries = 3;
  static const int _pruneAgeMs = 86400000; // 24 hours

  Future<void> processQueue() async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }
    final jobs = await _jobStore.fetchPending();
    for (final job in jobs) {
      try {
        final id = job.id;
        if (id == null) continue;

        final isDuplicate = await _jobStore.hasDuplicateActive(
          job.jobType,
          job.entityType,
          job.entityId,
        );
        if (isDuplicate && job.status == SyncJobStatus.queued) {
          continue;
        }

        await _jobStore.updateStatus(id, SyncJobStatus.syncing);

        if (job.jobType == SyncJobType.push) {
          await _executePush(job, id);
        } else {
          await _executePull(job, id);
        }
      } catch (e) {
        final id = job.id;
        if (id == null) continue;
        final newAttempt = job.attemptCount + 1;
        await _jobStore.incrementAttempt(id);
        if (newAttempt >= _maxRetries) {
          await _jobStore.updateStatus(id, SyncJobStatus.failed, error: '$e');
        } else {
          await _jobStore.updateStatus(id, SyncJobStatus.queued, error: '$e');
        }
      }
    }

    final cutoff = DateTime.now().millisecondsSinceEpoch - _pruneAgeMs;
    await _jobStore.removeCompleted(cutoff);
  }

  Future<void> _executePush(SyncJob job, int jobId) async {
    if (job.payload == null) {
      throw Exception(
        'Push job missing payload for ${job.entityType}:${job.entityId}',
      );
    }
    final data = jsonDecode(job.payload!) as Map<String, dynamic>;
    final client = _requireClient;
    final tableName = _tableNameFor(job.entityType);
    await client.from(tableName).upsert(data, onConflict: 'id');
    await _jobStore.updateStatus(jobId, SyncJobStatus.synced);
  }

  Future<void> _executePull(SyncJob job, int jobId) async {
    final client = _requireClient;
    final tableName = _tableNameFor(job.entityType);
    final response = await client
        .from(tableName)
        .select()
        .eq('id', job.entityId)
        .maybeSingle();

    if (response == null) {
      await _jobStore.updateStatus(jobId, SyncJobStatus.synced);
      return;
    }

    final remoteData = response;
    final remoteUpdatedAt = _extractUpdatedAt(remoteData);

    if (job.payload != null) {
      final localData = jsonDecode(job.payload!) as Map<String, dynamic>;
      final localUpdatedAt = localData['updated_at'] as int?;

      if (localUpdatedAt != null && remoteUpdatedAt != null) {
        if (remoteUpdatedAt <= localUpdatedAt) {
          await _jobStore.updateStatus(jobId, SyncJobStatus.synced);
          return;
        }
      }
    }

    await _persistPulledData(job.entityType, remoteData);
    await _jobStore.updateStatus(jobId, SyncJobStatus.synced);
  }

  Future<void> _persistPulledData(
    String entityType,
    Map<String, dynamic> remoteData,
  ) async {
    final localTable = _localTableNameFor(entityType);
    final entityId = remoteData['id'] as int?;
    if (entityId == null) return;

    await _localStore.ensureInitialized();
    final existing = await _localStore.executor.runSelect(
      'SELECT id FROM $localTable WHERE id = ?',
      [entityId],
    );

    final columns = remoteData.keys.toList();
    final values = columns.map((k) => remoteData[k]).toList();

    if (existing.isNotEmpty) {
      final setClause = columns.where((c) => c != 'id').map((c) => '$c = ?').join(', ');
      final updateValues = columns.where((c) => c != 'id').map((c) => remoteData[c]).toList();
      if (setClause.isNotEmpty) {
        await _localStore.executor.runCustom(
          'UPDATE $localTable SET $setClause WHERE id = ?',
          [...updateValues, entityId],
        );
      }
    } else {
      final cols = columns.join(', ');
      final placeholders = columns.map((_) => '?').join(', ');
      await _localStore.executor.runCustom(
        'INSERT INTO $localTable ($cols) VALUES ($placeholders)',
        values,
      );
    }
  }

  String _tableNameFor(String entityType) {
    switch (entityType) {
      case 'transaction':
        return 'transactions';
      case 'task':
        return 'tasks';
      case 'event':
        return 'events';
      case 'budget':
        return 'budgets';
      case 'income':
        return 'incomes';
      case 'recurring':
        return 'recurring_templates';
      default:
        return entityType;
    }
  }

  String _localTableNameFor(String entityType) {
    switch (entityType) {
      case 'transaction':
        return 'transactions';
      case 'task':
        return 'tasks';
      case 'event':
        return 'events';
      case 'budget':
        return 'budgets';
      case 'income':
        return 'incomes';
      case 'recurring':
        return 'recurring_templates';
      default:
        return entityType;
    }
  }

  int? _extractUpdatedAt(Map<String, dynamic> data) {
    final raw = data['updated_at'];
    if (raw is int) return raw;
    if (raw is String) {
      final dt = DateTime.tryParse(raw);
      return dt?.millisecondsSinceEpoch;
    }
    return null;
  }
}
