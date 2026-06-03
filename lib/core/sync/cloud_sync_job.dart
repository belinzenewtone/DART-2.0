import 'dart:convert';

enum SyncJobType { push, pull }

enum SyncJobStatus { queued, syncing, synced, failed, conflict }

class SyncJob {
  final int? id;
  final SyncJobType jobType;
  final String entityType;
  final int entityId;
  final String? payload;
  final SyncJobStatus status;
  final int attemptCount;
  final String? lastError;
  final int createdAt;
  final int updatedAt;

  const SyncJob({
    this.id,
    required this.jobType,
    required this.entityType,
    required this.entityId,
    this.payload,
    this.status = SyncJobStatus.queued,
    this.attemptCount = 0,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  SyncJob copyWith({
    int? id,
    SyncJobType? jobType,
    String? entityType,
    int? entityId,
    String? payload,
    SyncJobStatus? status,
    int? attemptCount,
    String? lastError,
    int? createdAt,
    int? updatedAt,
  }) {
    return SyncJob(
      id: id ?? this.id,
      jobType: jobType ?? this.jobType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'job_type': jobType.name,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload,
      'status': status.name,
      'attempt_count': attemptCount,
      'last_error': lastError,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory SyncJob.fromMap(Map<String, dynamic> map) {
    return SyncJob(
      id: map['id'] as int?,
      jobType: SyncJobType.values.byName(map['job_type'] as String),
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as int,
      payload: map['payload'] as String?,
      status: SyncJobStatus.values.byName(map['status'] as String),
      attemptCount: map['attempt_count'] as int,
      lastError: map['last_error'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  factory SyncJob.fromJson(String json) => SyncJob.fromMap(jsonDecode(json));
}
