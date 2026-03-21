import 'dart:convert';

import 'package:beltech/core/sync/sync_backoff_policy.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/data/local/drift/app_drift_store_mutations.dart';
import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:beltech/features/expenses/data/services/merchant_learning_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';

part 'expenses_repository_impl_import_pipeline.dart';
part 'expenses_repository_impl_intelligence.dart';
part 'expenses_repository_impl_review.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  ExpensesRepositoryImpl(
    this._store,
    this._parser, [
    MerchantLearningService? merchantLearningService,
    DeviceSmsDataSource? deviceSmsDataSource,
    SyncBackoffPolicy? backoffPolicy,
  ])  : _merchantLearningService =
            merchantLearningService ?? MerchantLearningService(),
        _deviceSmsDataSource = deviceSmsDataSource ?? DeviceSmsDataSource(),
        _backoffPolicy = backoffPolicy ?? const SyncBackoffPolicy();

  final AppDriftStore _store;
  final MpesaParserService _parser;
  final MerchantLearningService _merchantLearningService;
  final DeviceSmsDataSource _deviceSmsDataSource;
  final SyncBackoffPolicy _backoffPolicy;

  @override
  Stream<ExpensesSnapshot> watchSnapshot() {
    return _store.watchExpensesSnapshot().map(
          (record) => ExpensesSnapshot(
            todayKes: record.todayKes,
            weekKes: record.weekKes,
            categories: record.categories
                .map(
                  (item) => CategoryExpenseTotal(
                    category: item.category,
                    totalKes: item.totalKes,
                  ),
                )
                .toList(),
            transactions: record.transactions
                .map(
                  (tx) => ExpenseItem(
                    id: tx.id,
                    title: tx.title,
                    category: tx.category,
                    amountKes: tx.amountKes,
                    occurredAt: tx.occurredAt,
                  ),
                )
                .toList(),
          ),
        );
  }

  @override
  Future<void> addManualTransaction({
    required String title,
    required String category,
    required double amountKes,
    DateTime? occurredAt,
  }) async {
    await _merchantLearningService.learn(
      merchantTitle: title,
      category: category,
    );
    await _store.addTransaction(
      title: title,
      category: category,
      amountKes: amountKes,
      occurredAt: occurredAt,
    );
  }

  @override
  Future<void> updateTransaction({
    required int transactionId,
    required String title,
    required String category,
    required double amountKes,
    required DateTime occurredAt,
  }) async {
    await _merchantLearningService.learn(
      merchantTitle: title,
      category: category,
    );
    await _store.updateTransaction(
      id: transactionId,
      title: title,
      category: category,
      amountKes: amountKes,
      occurredAt: occurredAt,
    );
  }

  @override
  Future<void> deleteTransaction(int transactionId) {
    return _store.deleteTransaction(transactionId);
  }

  @override
  Future<int> importSmsMessages(
    List<String> rawMessages, {
    DateTime? from,
  }) async {
    await _store.ensureInitialized();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final raw in rawMessages) {
      final message = raw.trim();
      if (message.isEmpty) {
        continue;
      }
      final candidate = _parser.parseSingleDetailed(message);
      final sourceHash = candidate?.sourceHash ?? _parser.sourceHash(message);
      final semanticHash = candidate?.semanticHash ?? sourceHash;
      await _store.executor.runInsert(
        'INSERT OR IGNORE INTO sms_import_queue('
        'scope, raw_message, source_hash, semantic_hash, status, route, confidence, created_at, updated_at'
        ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'local',
          message,
          sourceHash,
          semanticHash,
          'pending',
          candidate?.route.name ?? MpesaParseRoute.quarantine.name,
          candidate?.confidenceScore ?? 0,
          nowMs,
          nowMs,
        ],
      );
    }
    return _processDueQueueImpl(this, from: from);
  }

  @override
  Future<int> importFromDevice({
    DateTime? from,
  }) async {
    final messages =
        await _deviceSmsDataSource.loadLikelyMpesaMessages(from: from);
    if (messages.isNotEmpty) {
      await importSmsMessages(messages, from: from);
    }
    return _processDueQueueImpl(this, from: from);
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
  }) =>
      _resolveReviewItemImpl(this, reviewId: reviewId, approve: approve);

  @override
  Future<void> dismissQuarantineItem(int quarantineId) =>
      _dismissQuarantineItemImpl(this, quarantineId);

  @override
  Future<int> replayImportQueue() => _replayImportQueueImpl(this);

  Future<int> _count(
    String table, {
    required String where,
    required List<Object?> params,
  }) async {
    final rows = await _store.executor.runSelect(
      'SELECT COUNT(*) AS total FROM $table WHERE $where',
      params,
    );
    return _asInt(rows.first['total']);
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
