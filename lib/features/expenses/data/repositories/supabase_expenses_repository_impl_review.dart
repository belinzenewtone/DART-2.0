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
  final failed = await _safeCountImpl(
    repo,
    table: 'sms_import_queue',
    filters: (query) => query.eq('owner_id', userId).eq('status', 'failed'),
  );
  return ExpenseImportMetrics(
    reviewQueueCount: review,
    quarantineCount: quarantine,
    retryQueueCount: retry,
    failedQueueCount: failed,
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
    final title = '${row['title'] ?? 'MPESA Transaction'}';
    final category = '${row['category'] ?? 'Other'}';
    final learned = await _resolveLearnedCategoryImpl(
      repo,
      userId: userId,
      merchantTitle: title,
      fallbackCategory: category,
    );
    await repo._client.from('transactions').insert({
      'owner_id': userId,
      'title': title,
      'category': learned,
      'amount': parseDouble(row['amount']),
      'occurred_at': parseTimestamp(
        row['occurred_at'],
      ).toUtc().toIso8601String(),
      'transaction_type': 'expense',
      'source': 'sms_review',
      'source_hash': '${row['source_hash'] ?? ''}',
      'balance_after': null,
    });
    await _learnMerchantCategoryImpl(
      repo,
      userId: userId,
      merchantTitle: title,
      category: learned,
    );
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
      .select('id,title,category,amount,occurred_at,balance_after')
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
      balanceAfterKes: row['balance_after'] == null
          ? null
          : parseDouble(row['balance_after']),
    );
  }).toList();

  final categoryTotals = <String, double>{};
  for (final tx in transactions) {
    categoryTotals[tx.category] =
        (categoryTotals[tx.category] ?? 0) + tx.amountKes;
  }
  final categories =
      categoryTotals.entries
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
