part of 'expenses_repository_impl.dart';

Future<int> _processDueQueueImpl(
  ExpensesRepositoryImpl repo, {
  DateTime? from,
}) async {
  final now = DateTime.now();
  final rows = await repo._store.executor.runSelect(
    'SELECT id, raw_message, attempt '
    'FROM sms_import_queue '
    'WHERE scope = ? AND status IN (?, ?) AND (next_retry_at IS NULL OR next_retry_at <= ?) '
    'ORDER BY created_at ASC LIMIT 400',
    ['local', 'pending', 'retry', now.millisecondsSinceEpoch],
  );
  var imported = 0;
  for (final row in rows) {
    final queueId = repo._asInt(row['id']);
    final rawMessage = '${row['raw_message'] ?? ''}';
    var attempt = repo._asInt(row['attempt']);
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
        await _markDoneImpl(repo, queueId,
            status: 'failed', lastError: 'Unparseable');
        continue;
      }
      if (from != null && candidate.occurredAt.isBefore(from)) {
        await _markDoneImpl(repo, queueId, status: 'skipped');
        continue;
      }
      if (await _isDuplicateImpl(repo, candidate)) {
        await _logAuditImpl(
          repo,
          sourceHash: candidate.sourceHash,
          semanticHash: candidate.semanticHash,
          route: candidate.route.name,
          confidence: candidate.confidenceScore,
          decision: 'duplicate',
          status: 'done',
          payload: _auditPayloadForCandidate(candidate),
        );
        await _markDoneImpl(repo, queueId, status: 'duplicate');
        continue;
      }
      switch (candidate.route) {
        case MpesaParseRoute.directLedger:
          await _insertDirectImpl(repo, candidate);
          imported += 1;
        case MpesaParseRoute.reviewQueue:
          await _insertReviewImpl(repo, candidate);
        case MpesaParseRoute.quarantine:
          await _insertQuarantineImpl(repo, candidate);
      }
      await _markDoneImpl(repo, queueId, status: 'done');
    } catch (error) {
      final nextAttempt = attempt + 1;
      if (nextAttempt >= 5) {
        await _markDoneImpl(repo, queueId,
            status: 'failed', lastError: '$error');
        continue;
      }
      final retryAt = repo._backoffPolicy.nextRetryAt(attempt: nextAttempt);
      await repo._store.executor.runUpdate(
        'UPDATE sms_import_queue SET status = ?, attempt = ?, next_retry_at = ?, updated_at = ?, last_error = ? WHERE id = ?',
        [
          'retry',
          nextAttempt,
          retryAt.millisecondsSinceEpoch,
          DateTime.now().millisecondsSinceEpoch,
          '$error',
          queueId,
        ],
      );
    }
  }
  repo._store.emitChange();
  return imported;
}

Future<void> _insertDirectImpl(
  ExpensesRepositoryImpl repo,
  ParsedMpesaCandidate candidate,
) async {
  final learnedCategory = await repo._merchantLearningService.resolveCategory(
    merchantTitle: candidate.title,
    fallbackCategory: candidate.category,
  );
  await repo._store.addTransaction(
    title: candidate.title,
    category: learnedCategory,
    amountKes: candidate.amountKes,
    occurredAt: candidate.occurredAt,
    source: 'sms',
    sourceHash: candidate.sourceHash,
  );
  await repo._merchantLearningService.learn(
    merchantTitle: candidate.title,
    category: learnedCategory,
  );
  await _upsertPaybillAndFulizaImpl(repo, candidate);
  await _logAuditImpl(
    repo,
    sourceHash: candidate.sourceHash,
    semanticHash: candidate.semanticHash,
    route: candidate.route.name,
    confidence: candidate.confidenceScore,
    decision: 'imported',
    status: 'done',
    payload: _auditPayloadForCandidate(candidate),
  );
}

Future<void> _insertReviewImpl(
  ExpensesRepositoryImpl repo,
  ParsedMpesaCandidate candidate,
) async {
  await repo._store.executor.runInsert(
    'INSERT OR IGNORE INTO sms_review_queue('
    'scope, source_hash, semantic_hash, title, category, amount, occurred_at, raw_message, confidence, status, created_at'
    ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      'local',
      candidate.sourceHash,
      candidate.semanticHash,
      candidate.title,
      candidate.category,
      candidate.amountKes,
      candidate.occurredAt.millisecondsSinceEpoch,
      candidate.rawMessage,
      candidate.confidenceScore,
      'pending',
      DateTime.now().millisecondsSinceEpoch,
    ],
  );
  await _logAuditImpl(
    repo,
    sourceHash: candidate.sourceHash,
    semanticHash: candidate.semanticHash,
    route: candidate.route.name,
    confidence: candidate.confidenceScore,
    decision: 'review_pending',
    status: 'done',
    payload: _auditPayloadForCandidate(candidate),
  );
}

Future<void> _insertQuarantineImpl(
  ExpensesRepositoryImpl repo,
  ParsedMpesaCandidate candidate,
) async {
  await repo._store.executor.runInsert(
    'INSERT OR IGNORE INTO sms_quarantine('
    'scope, source_hash, semantic_hash, raw_message, reason, confidence, status, created_at'
    ') VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [
      'local',
      candidate.sourceHash,
      candidate.semanticHash,
      candidate.rawMessage,
      candidate.reason ?? 'Low confidence classification',
      candidate.confidenceScore,
      'pending',
      DateTime.now().millisecondsSinceEpoch,
    ],
  );
  await _logAuditImpl(
    repo,
    sourceHash: candidate.sourceHash,
    semanticHash: candidate.semanticHash,
    route: candidate.route.name,
    confidence: candidate.confidenceScore,
    decision: 'quarantined',
    status: 'done',
    payload: _auditPayloadForCandidate(candidate),
  );
}

Future<void> _upsertPaybillAndFulizaImpl(
  ExpensesRepositoryImpl repo,
  ParsedMpesaCandidate candidate,
) async {
  if (candidate.paybillAccount != null &&
      candidate.paybillAccount!.isNotEmpty) {
    await repo._store.executor.runInsert(
      'INSERT INTO paybill_registry(paybill, display_name, last_seen_at, usage_count) '
      'VALUES (?, ?, ?, 1) '
      'ON CONFLICT(paybill) DO UPDATE SET '
      'display_name = excluded.display_name, '
      'last_seen_at = excluded.last_seen_at, '
      'usage_count = paybill_registry.usage_count + 1',
      [
        candidate.paybillAccount!,
        candidate.title,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }
  final isFuliza =
      candidate.transactionType == MpesaTransactionType.fulizaDraw ||
          candidate.transactionType == MpesaTransactionType.fulizaRepayment;
  if (!isFuliza) {
    return;
  }
  await repo._store.executor.runInsert(
    'INSERT OR IGNORE INTO fuliza_lifecycle_events('
    'scope, mpesa_code, event_kind, amount, occurred_at, raw_message, source_hash'
    ') VALUES (?, ?, ?, ?, ?, ?, ?)',
    [
      'local',
      candidate.mpesaCode,
      candidate.transactionType.name,
      candidate.amountKes,
      candidate.occurredAt.millisecondsSinceEpoch,
      candidate.rawMessage,
      candidate.sourceHash,
    ],
  );
}
