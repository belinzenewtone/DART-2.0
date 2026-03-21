part of 'supabase_expenses_repository_impl.dart';

Future<void> _safeInsertReviewItemImpl(
  SupabaseExpensesRepositoryImpl repo,
  String userId,
  ParsedMpesaCandidate candidate,
) async {
  await _safeInsertImpl(
    repo,
    table: 'sms_review_queue',
    payload: {
      'owner_id': userId,
      'source_hash': candidate.sourceHash,
      'semantic_hash': candidate.semanticHash,
      'title': candidate.title,
      'category': candidate.category,
      'amount': candidate.amountKes,
      'occurred_at': candidate.occurredAt.toUtc().toIso8601String(),
      'raw_message': candidate.rawMessage,
      'confidence': candidate.confidenceScore,
      'status': 'pending',
    },
  );
}

Future<void> _safeInsertQuarantineItemImpl(
  SupabaseExpensesRepositoryImpl repo,
  String userId,
  ParsedMpesaCandidate candidate,
) async {
  await _safeInsertImpl(
    repo,
    table: 'sms_quarantine',
    payload: {
      'owner_id': userId,
      'source_hash': candidate.sourceHash,
      'semantic_hash': candidate.semanticHash,
      'raw_message': candidate.rawMessage,
      'reason': candidate.reason ?? 'Low confidence classification',
      'confidence': candidate.confidenceScore,
      'status': 'pending',
    },
  );
}

Future<void> _safePaybillAndFulizaImpl(
  SupabaseExpensesRepositoryImpl repo,
  String userId,
  ParsedMpesaCandidate candidate,
) async {
  if (candidate.paybillAccount != null &&
      candidate.paybillAccount!.isNotEmpty) {
    await _safeInsertImpl(
      repo,
      table: 'paybill_registry',
      payload: {
        'owner_id': userId,
        'paybill': candidate.paybillAccount,
        'display_name': candidate.title,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        'usage_count': 1,
      },
    );
  }
  final isFuliza =
      candidate.transactionType == MpesaTransactionType.fulizaDraw ||
          candidate.transactionType == MpesaTransactionType.fulizaRepayment;
  if (!isFuliza) {
    return;
  }
  await _safeInsertImpl(
    repo,
    table: 'fuliza_lifecycle_events',
    payload: {
      'owner_id': userId,
      'mpesa_code': candidate.mpesaCode,
      'event_kind': candidate.transactionType.name,
      'amount': candidate.amountKes,
      'occurred_at': candidate.occurredAt.toUtc().toIso8601String(),
      'raw_message': candidate.rawMessage,
      'source_hash': candidate.sourceHash,
    },
  );
}

Future<void> _safeAuditImpl(
  SupabaseExpensesRepositoryImpl repo, {
  required String userId,
  required ParsedMpesaCandidate candidate,
  required String decision,
}) async {
  await _safeInsertImpl(
    repo,
    table: 'sms_import_audit',
    payload: {
      'owner_id': userId,
      'source_hash': candidate.sourceHash,
      'semantic_hash': candidate.semanticHash,
      'route': candidate.route.name,
      'confidence': candidate.confidenceScore,
      'decision': decision,
      'status': 'done',
      'payload': _privacySafeAuditPayload(candidate),
    },
  );
}

Map<String, Object?> _privacySafeAuditPayload(ParsedMpesaCandidate candidate) {
  return {
    'channel': 'sms_import_v2',
    'transaction_family': candidate.transactionType.name,
    'amount_band': _amountBand(candidate.amountKes),
    'has_paybill': candidate.paybillAccount?.isNotEmpty == true,
    'has_fuliza':
        candidate.transactionType == MpesaTransactionType.fulizaDraw ||
            candidate.transactionType == MpesaTransactionType.fulizaRepayment,
  };
}

String _amountBand(double amountKes) {
  if (amountKes < 100) {
    return 'lt_100';
  }
  if (amountKes < 1000) {
    return 'lt_1000';
  }
  if (amountKes < 10000) {
    return 'lt_10000';
  }
  return 'gte_10000';
}

Future<int> _safeCountImpl(
  SupabaseExpensesRepositoryImpl repo, {
  required String table,
  required dynamic Function(dynamic) filters,
}) async {
  try {
    final rows = await filters(repo._client.from(table).select('id'));
    return (rows as List).length;
  } catch (_) {
    return 0;
  }
}

Future<List<Map<String, dynamic>>> _safeSelectImpl(
  SupabaseExpensesRepositoryImpl repo, {
  required String table,
  required dynamic Function(dynamic) filters,
}) async {
  try {
    final rows = await filters(repo._client.from(table));
    return (rows as List).cast<Map<String, dynamic>>();
  } catch (_) {
    return const [];
  }
}

Future<void> _safeInsertImpl(
  SupabaseExpensesRepositoryImpl repo, {
  required String table,
  required Map<String, Object?> payload,
}) async {
  try {
    await repo._client.from(table).insert(payload);
  } catch (_) {
    return;
  }
}
