import 'package:beltech/data/remote/supabase/supabase_parsers.dart';
import 'package:beltech/data/remote/supabase/supabase_polling.dart';
import 'package:beltech/features/expenses/data/services/category_inference_engine.dart';
import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:beltech/features/expenses/data/services/merchant_learning_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/domain/entities/fee_analytics.dart';
import 'package:beltech/features/expenses/domain/entities/merchant_detail.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_expenses_repository_impl_intelligence.dart';
part 'supabase_expenses_repository_impl_merchant_categories.dart';
part 'supabase_expenses_repository_impl_dedupe.dart';
part 'supabase_expenses_repository_impl_review.dart';
part 'supabase_expenses_repository_impl_support.dart';
part 'supabase_expenses_repository_impl_queue.dart';

class SupabaseExpensesRepositoryImpl implements ExpensesRepository {
  SupabaseExpensesRepositoryImpl(
    this._client,
    this._parser, [
    MerchantLearningService? merchantLearningService,
    DeviceSmsDataSource? deviceSmsDataSource,
  ]) : _merchantLearningService =
           merchantLearningService ?? MerchantLearningService(),
       _deviceSmsDataSource = deviceSmsDataSource ?? DeviceSmsDataSource();

  final SupabaseClient _client;
  final MpesaParserService _parser;
  final MerchantLearningService _merchantLearningService;
  final DeviceSmsDataSource _deviceSmsDataSource;

  @override
  Stream<ExpensesSnapshot> watchSnapshot() =>
      pollStream(() => _loadSnapshotImpl(this));

  @override
  Future<void> addManualTransaction({
    required String title,
    required String category,
    required double amountKes,
    DateTime? occurredAt,
  }) async {
    final userId = _requireUserId();
    await _learnMerchantCategoryImpl(
      this,
      userId: userId,
      merchantTitle: title,
      category: category,
    );
    await _client.from('transactions').insert({
      'owner_id': userId,
      'title': title,
      'category': category,
      'amount': amountKes,
      'occurred_at': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
      'transaction_type': 'expense',
      'source': 'manual',
      'source_hash': null,
      'balance_after': null,
    });
  }

  @override
  Future<void> updateTransaction({
    required int transactionId,
    required String title,
    required String category,
    required double amountKes,
    required DateTime occurredAt,
  }) async {
    final userId = _requireUserId();
    await _learnMerchantCategoryImpl(
      this,
      userId: userId,
      merchantTitle: title,
      category: category,
    );
    await _client
        .from('transactions')
        .update({
          'title': title,
          'category': category,
          'amount': amountKes,
          'occurred_at': occurredAt.toUtc().toIso8601String(),
          'transaction_type': 'expense',
          'source': 'manual',
          'source_hash': null,
          'balance_after': null,
        })
        .eq('id', transactionId)
        .eq('owner_id', userId);
  }

  @override
  Future<void> deleteTransaction(int transactionId) async {
    final userId = _requireUserId();
    await _client
        .from('transactions')
        .delete()
        .eq('id', transactionId)
        .eq('owner_id', userId);
  }

  @override
  Future<int> importSmsMessages(
    List<String> rawMessages, {
    DateTime? from,
  }) async {
    final userId = _requireUserId();
    final envelopes = rawMessages
        .map((message) => _QueuedSmsImport(message: message))
        .toList(growable: false);
    await _enqueueSmsImports(userId, envelopes);
    return _processQueuedImportsImpl(this, userId, from: from);
  }

  Future<void> _enqueueSmsImports(
    String userId,
    List<_QueuedSmsImport> envelopes,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    for (final envelope in envelopes) {
      final message = envelope.message.trim();
      if (message.isEmpty) {
        continue;
      }
      final candidate = _parser.parseSingleDetailed(
        message,
        fallbackOccurredAt: envelope.sourceTimestamp,
      );
      final sourceHash = candidate?.sourceHash ?? _parser.sourceHash(message);
      final semanticHash = candidate?.semanticHash ?? sourceHash;
      await _safeInsertImpl(
        this,
        table: 'sms_import_queue',
        payload: {
          'owner_id': userId,
          'raw_message': message,
          'source_hash': sourceHash,
          'semantic_hash': semanticHash,
          'source_timestamp': envelope.sourceTimestamp
              ?.toUtc()
              .toIso8601String(),
          'status': 'pending',
          'route': candidate?.route.name ?? MpesaParseRoute.quarantine.name,
          'confidence': candidate?.confidenceScore ?? 0,
          'attempt': 0,
          'created_at': now,
          'updated_at': now,
        },
      );
    }
  }

  @override
  Future<int> importFromDevice({DateTime? from}) async {
    final userId = _requireUserId();
    final entries = await _deviceSmsDataSource.loadLikelyMpesaEntries(
      from: from,
    );
    if (entries.isEmpty) {
      return 0;
    }
    await _enqueueSmsImports(
      userId,
      entries
          .map(
            (entry) => _QueuedSmsImport(
              message: entry.body,
              sourceTimestamp: entry.receivedAt,
            ),
          )
          .toList(growable: false),
    );
    return _processQueuedImportsImpl(this, userId, from: from);
  }

  @override
  Future<ExpenseImportMetrics> fetchImportMetrics() =>
      _fetchImportMetricsImpl(this);

  @override
  Future<List<PaybillProfile>> fetchPaybillProfiles({int limit = 10}) =>
      _fetchPaybillProfilesImpl(this, limit: limit);

  @override
  Future<List<FulizaLifecycleEvent>> fetchFulizaLifecycle({int limit = 12}) =>
      _fetchFulizaLifecycleImpl(this, limit: limit);

  @override
  Future<List<ExpenseReviewItem>> fetchReviewQueue({int limit = 20}) =>
      _fetchReviewQueueImpl(this, limit: limit);

  @override
  Future<List<ExpenseQuarantineItem>> fetchQuarantineItems({int limit = 20}) =>
      _fetchQuarantineItemsImpl(this, limit: limit);

  @override
  Future<void> resolveReviewItem({
    required int reviewId,
    required bool approve,
  }) => _resolveReviewItemImpl(this, reviewId: reviewId, approve: approve);

  @override
  Future<void> dismissQuarantineItem(int quarantineId) =>
      _dismissQuarantineItemImpl(this, quarantineId);

  @override
  Future<int> replayImportQueue() {
    final userId = _requireUserId();
    return _replayImportQueueImpl(this, userId);
  }

  @override
  Future<MerchantDetail> fetchMerchantDetail(String merchantTitle) async {
    final userId = _requireUserId();
    final rows = await _client
        .from('transactions')
        .select('id,amount,occurred_at,category,balance_after,title')
        .eq('owner_id', userId)
        .ilike('title', '%$merchantTitle%')
        .order('occurred_at', ascending: false)
        .limit(50);
    if (rows.isEmpty) {
      return MerchantDetail(
        merchantTitle: merchantTitle,
        transactions: [],
        totalSpent: 0,
        transactionCount: 0,
        firstSeen: DateTime.now(),
        lastSeen: DateTime.now(),
        averageAmount: 0,
        category: 'Unknown',
      );
    }
    final txs = rows.map((r) => MerchantTransaction(
      id: r['id'] as int,
      amount: (r['amount'] as num).toDouble(),
      date: DateTime.parse(r['occurred_at'] as String),
      category: r['category'] as String? ?? 'Unknown',
      balanceAfter: (r['balance_after'] as num?)?.toDouble(),
    )).toList();
    final total = txs.fold<double>(0, (sum, t) => sum + t.amount);
    return MerchantDetail(
      merchantTitle: merchantTitle,
      transactions: txs,
      totalSpent: total,
      transactionCount: txs.length,
      firstSeen: txs.last.date,
      lastSeen: txs.first.date,
      averageAmount: txs.isNotEmpty ? total / txs.length : 0,
      category: txs.first.category,
    );
  }

  @override
  Future<FeeAnalytics> fetchFeeAnalytics() async {
    final userId = _requireUserId();
    final rows = await _client
        .from('transactions')
        .select('amount,occurred_at,category')
        .eq('owner_id', userId)
        .eq('transaction_type', 'expense')
        .order('occurred_at', ascending: false)
        .limit(500);
    final feeKeywords = ['fee', 'charge', 'commission', ' levy ', 'tariff', 'service fee'];
    final feeRows = rows.where((r) {
      final title = (r['title'] as String? ?? '').toLowerCase();
      final cat = (r['category'] as String? ?? '').toLowerCase();
      return feeKeywords.any((k) => title.contains(k) || cat.contains(k));
    }).toList();
    final totalFees = feeRows.fold<double>(0, (s, r) => s + (r['amount'] as num).toDouble());
    final byCategory = <String, double>{};
    for (final r in feeRows) {
      byCategory[r['category'] as String? ?? 'Other'] =
          (byCategory[r['category'] as String? ?? 'Other'] ?? 0) + (r['amount'] as num).toDouble();
    }
    final topCats = byCategory.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return FeeAnalytics(
      totalFees: totalFees,
      feeCount: feeRows.length,
      averageFee: feeRows.isNotEmpty ? totalFees / feeRows.length : 0,
      topFeeCategories: topCats.take(10).toList(),
      monthlyFees: [],
    );
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Sign in is required.');
    }
    return userId;
  }
}

class _QueuedSmsImport {
  const _QueuedSmsImport({required this.message, this.sourceTimestamp});

  final String message;
  final DateTime? sourceTimestamp;
}
