part of 'supabase_expenses_repository_impl.dart';

Future<ExpenseImportMetrics> _fetchImportMetricsImpl(
  SupabaseExpensesRepositoryImpl repo,
) async {
  final userId = repo._requireUserId();
  final review = await _safeCountImpl(
    repo,
    table: 'sms_review_queue',
    filters: (query) => query.eq('owner_id', userId).eq('status', 'pending'),
  );
  final quarantine = await _safeCountImpl(
    repo,
    table: 'sms_quarantine',
    filters: (query) => query.eq('owner_id', userId).eq('status', 'pending'),
  );
  final retry = await _safeCountImpl(
    repo,
    table: 'sms_import_queue',
    filters: (query) => query.eq('owner_id', userId).eq('status', 'retry'),
  );
  return ExpenseImportMetrics(
    reviewQueueCount: review,
    quarantineCount: quarantine,
    retryQueueCount: retry,
  );
}

Future<List<ExpenseReviewItem>> _fetchReviewQueueImpl(
  SupabaseExpensesRepositoryImpl repo, {
  int limit = 20,
}) async {
  final userId = repo._requireUserId();
  final rows = await _safeSelectImpl(
    repo,
    table: 'sms_review_queue',
    filters: (query) => query
        .select('id,title,category,amount,occurred_at,confidence,raw_message')
        .eq('owner_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(limit),
  );
  return rows
      .map(
        (row) => ExpenseReviewItem(
          id: parseInt(row['id']),
          title: '${row['title'] ?? ''}',
          category: '${row['category'] ?? 'Other'}',
          amountKes: parseDouble(row['amount']),
          occurredAt: parseTimestamp(row['occurred_at']),
          confidence: parseDouble(row['confidence']),
          rawMessage: '${row['raw_message'] ?? ''}',
        ),
      )
      .toList();
}

Future<List<ExpenseQuarantineItem>> _fetchQuarantineItemsImpl(
  SupabaseExpensesRepositoryImpl repo, {
  int limit = 20,
}) async {
  final userId = repo._requireUserId();
  final rows = await _safeSelectImpl(
    repo,
    table: 'sms_quarantine',
    filters: (query) => query
        .select('id,reason,confidence,raw_message,created_at')
        .eq('owner_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(limit),
  );
  return rows
      .map(
        (row) => ExpenseQuarantineItem(
          id: parseInt(row['id']),
          reason: '${row['reason'] ?? 'Unknown reason'}',
          confidence: parseDouble(row['confidence']),
          rawMessage: '${row['raw_message'] ?? ''}',
          createdAt: parseTimestamp(row['created_at']),
        ),
      )
      .toList();
}

Future<void> _resolveReviewItemImpl(
  SupabaseExpensesRepositoryImpl repo, {
  required int reviewId,
  required bool approve,
}) async {
  final userId = repo._requireUserId();
  final rows = await _safeSelectImpl(
    repo,
    table: 'sms_review_queue',
    filters: (query) => query
        .select(
          'source_hash,semantic_hash,title,category,amount,occurred_at,raw_message,confidence',
        )
        .eq('owner_id', userId)
        .eq('id', reviewId)
        .eq('status', 'pending')
        .limit(1),
  );
  if (rows.isEmpty) {
    return;
  }
  final row = rows.first;
  if (approve) {
    await repo._client.from('transactions').insert({
      'owner_id': userId,
      'title': '${row['title'] ?? 'MPESA Transaction'}',
      'category': '${row['category'] ?? 'Other'}',
      'amount': parseDouble(row['amount']),
      'occurred_at':
          parseTimestamp(row['occurred_at']).toUtc().toIso8601String(),
      'source': 'sms_review',
      'source_hash': '${row['source_hash'] ?? ''}',
    });
  }
  await _safeUpdateImpl(
    repo,
    table: 'sms_review_queue',
    payload: {
      'status': 'resolved',
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
    },
    filters: (query) => query.eq('owner_id', userId).eq('id', reviewId),
  );
  await _safeAuditImpl(
    repo,
    userId: userId,
    candidate: ParsedMpesaCandidate(
      mpesaCode: 'REVIEW',
      title: '${row['title'] ?? 'MPESA Transaction'}',
      category: '${row['category'] ?? 'Other'}',
      amountKes: parseDouble(row['amount']),
      occurredAt: parseTimestamp(row['occurred_at']),
      rawMessage: '${row['raw_message'] ?? ''}',
      transactionType: MpesaTransactionType.unknown,
      confidence: MpesaConfidence.medium,
      route: MpesaParseRoute.reviewQueue,
      sourceHash: '${row['source_hash'] ?? ''}',
      semanticHash: '${row['semantic_hash'] ?? ''}',
    ),
    decision: approve ? 'review_approved' : 'review_rejected',
  );
}

Future<void> _dismissQuarantineItemImpl(
  SupabaseExpensesRepositoryImpl repo,
  int quarantineId,
) async {
  final userId = repo._requireUserId();
  await _safeUpdateImpl(
    repo,
    table: 'sms_quarantine',
    payload: {'status': 'dismissed'},
    filters: (query) => query.eq('owner_id', userId).eq('id', quarantineId),
  );
}

Future<ExpensesSnapshot> _loadSnapshotImpl(
  SupabaseExpensesRepositoryImpl repo,
) async {
  final userId = repo._requireUserId();
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final tomorrowStart = todayStart.add(const Duration(days: 1));
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));

  final rows = await repo._client
      .from('transactions')
      .select('id,title,category,amount,occurred_at')
      .eq('owner_id', userId)
      .order('occurred_at', ascending: false)
      .limit(5000);
  final transactionsRaw = (rows as List).cast<Map<String, dynamic>>();

  final transactions = transactionsRaw.map((row) {
    return ExpenseItem(
      id: parseInt(row['id']),
      title: '${row['title'] ?? ''}',
      category: '${row['category'] ?? 'Other'}',
      amountKes: parseDouble(row['amount']),
      occurredAt: parseTimestamp(row['occurred_at']),
    );
  }).toList();

  final categoryTotals = <String, double>{};
  for (final tx in transactions) {
    categoryTotals[tx.category] =
        (categoryTotals[tx.category] ?? 0) + tx.amountKes;
  }
  final categories = categoryTotals.entries
      .map(
        (entry) => CategoryExpenseTotal(
          category: entry.key,
          totalKes: entry.value,
        ),
      )
      .toList()
    ..sort((a, b) => b.totalKes.compareTo(a.totalKes));

  double sumBetween(DateTime start, DateTime end) {
    var total = 0.0;
    for (final tx in transactions) {
      if (!tx.occurredAt.isBefore(start) && tx.occurredAt.isBefore(end)) {
        total += tx.amountKes;
      }
    }
    return total;
  }

  return ExpensesSnapshot(
    todayKes: sumBetween(todayStart, tomorrowStart),
    weekKes: sumBetween(weekStart, weekEnd),
    categories: categories,
    transactions: transactions,
  );
}

Future<bool> _isDuplicateImpl(
  SupabaseExpensesRepositoryImpl repo,
  String userId,
  ParsedMpesaCandidate candidate,
) async {
  final sourceRows = await repo._client
      .from('transactions')
      .select('id')
      .eq('owner_id', userId)
      .eq('source_hash', candidate.sourceHash)
      .limit(1);
  if ((sourceRows as List).isNotEmpty) {
    return true;
  }
  final semanticRows = await _safeSelectImpl(
    repo,
    table: 'sms_import_audit',
    filters: (query) => query
        .select('id')
        .eq('owner_id', userId)
        .eq('semantic_hash', candidate.semanticHash)
        .inFilter(
            'decision', ['imported', 'duplicate', 'review_pending']).limit(1),
  );
  if (semanticRows.isNotEmpty) {
    return true;
  }
  final nearRows = await _safeSelectImpl(
    repo,
    table: 'transactions',
    filters: (query) => query
        .select('id')
        .eq('owner_id', userId)
        .eq('title', candidate.title)
        .gte(
          'occurred_at',
          candidate.occurredAt
              .subtract(const Duration(minutes: 2))
              .toUtc()
              .toIso8601String(),
        )
        .lte(
          'occurred_at',
          candidate.occurredAt
              .add(const Duration(minutes: 2))
              .toUtc()
              .toIso8601String(),
        )
        .limit(1),
  );
  return nearRows.isNotEmpty;
}
