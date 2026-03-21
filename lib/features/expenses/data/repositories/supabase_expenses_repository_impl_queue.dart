part of 'supabase_expenses_repository_impl.dart';

Future<int> _processQueuedImportsImpl(
  SupabaseExpensesRepositoryImpl repo,
  String userId, {
  DateTime? from,
}) async {
  final now = DateTime.now().toUtc().toIso8601String();
  final rows = await _safeSelectImpl(
    repo,
    table: 'sms_import_queue',
    filters: (query) => query
        .select('id,raw_message,attempt')
        .eq('owner_id', userId)
        .inFilter('status', ['pending', 'retry'])
        .or('next_retry_at.is.null,next_retry_at.lte.$now')
        .order('created_at')
        .limit(400),
  );
  var imported = 0;
  for (final row in rows) {
    final queueId = parseInt(row['id']);
    final rawMessage = '${row['raw_message'] ?? ''}';
    var attempt = parseInt(row['attempt']);
    if (attempt < 0) {
      attempt = 0;
    } else if (attempt > 999) {
      attempt = 999;
    }
    try {
      final candidate = repo._parser.parseSingleDetailed(rawMessage) ??
          repo._parser
              .parseSingleDetailed('UNKNOWN Confirmed. Ksh0.00 $rawMessage');
      if (candidate == null) {
        await _markQueueStatusImpl(
          repo,
          userId,
          queueId,
          status: 'failed',
          lastError: 'Unparseable',
        );
        continue;
      }
      if (from != null && candidate.occurredAt.isBefore(from)) {
        await _markQueueStatusImpl(repo, userId, queueId, status: 'skipped');
        continue;
      }
      if (await _isDuplicateImpl(repo, userId, candidate)) {
        await _safeAuditImpl(
          repo,
          userId: userId,
          candidate: candidate,
          decision: 'duplicate',
        );
        await _markQueueStatusImpl(repo, userId, queueId, status: 'duplicate');
        continue;
      }
      switch (candidate.route) {
        case MpesaParseRoute.directLedger:
          final learned = await repo._merchantLearningService.resolveCategory(
            merchantTitle: candidate.title,
            fallbackCategory: candidate.category,
          );
          await repo._client.from('transactions').insert({
            'owner_id': userId,
            'title': candidate.title,
            'category': learned,
            'amount': candidate.amountKes,
            'occurred_at': candidate.occurredAt.toUtc().toIso8601String(),
            'source': 'sms',
            'source_hash': candidate.sourceHash,
          });
          await _safePaybillAndFulizaImpl(repo, userId, candidate);
          await _safeAuditImpl(
            repo,
            userId: userId,
            candidate: candidate,
            decision: 'imported',
          );
          imported += 1;
        case MpesaParseRoute.reviewQueue:
          await _safeInsertReviewItemImpl(repo, userId, candidate);
          await _safeAuditImpl(
            repo,
            userId: userId,
            candidate: candidate,
            decision: 'review_pending',
          );
        case MpesaParseRoute.quarantine:
          await _safeInsertQuarantineItemImpl(repo, userId, candidate);
          await _safeAuditImpl(
            repo,
            userId: userId,
            candidate: candidate,
            decision: 'quarantined',
          );
      }
      await _markQueueStatusImpl(repo, userId, queueId, status: 'done');
    } catch (error) {
      final nextAttempt = attempt + 1;
      if (nextAttempt >= 5) {
        await _markQueueStatusImpl(
          repo,
          userId,
          queueId,
          status: 'failed',
          lastError: '$error',
        );
        continue;
      }
      final retryAt = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 5 * 1))
          .add(Duration(minutes: 5 * nextAttempt))
          .toIso8601String();
      await _safeUpdateImpl(
        repo,
        table: 'sms_import_queue',
        payload: {
          'status': 'retry',
          'attempt': nextAttempt,
          'next_retry_at': retryAt,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'last_error': '$error',
        },
        filters: (query) => query.eq('owner_id', userId).eq('id', queueId),
      );
    }
  }
  return imported;
}

Future<int> _replayImportQueueImpl(
  SupabaseExpensesRepositoryImpl repo,
  String userId,
) async {
  await _safeUpdateImpl(
    repo,
    table: 'sms_import_queue',
    payload: {
      'status': 'pending',
      'next_retry_at': null,
      'last_error': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    },
    filters: (query) =>
        query.eq('owner_id', userId).inFilter('status', ['retry', 'failed']),
  );
  return _processQueuedImportsImpl(repo, userId);
}

Future<void> _markQueueStatusImpl(
  SupabaseExpensesRepositoryImpl repo,
  String userId,
  int queueId, {
  required String status,
  String? lastError,
}) {
  return _safeUpdateImpl(
    repo,
    table: 'sms_import_queue',
    payload: {
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'last_error': lastError,
    },
    filters: (query) => query.eq('owner_id', userId).eq('id', queueId),
  );
}

Future<void> _safeUpdateImpl(
  SupabaseExpensesRepositoryImpl repo, {
  required String table,
  required Map<String, Object?> payload,
  required dynamic Function(dynamic) filters,
}) async {
  try {
    await filters(repo._client.from(table).update(payload).select());
  } catch (_) {
    return;
  }
}
