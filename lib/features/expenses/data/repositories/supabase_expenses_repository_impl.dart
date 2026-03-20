import 'package:beltech/data/remote/supabase/supabase_parsers.dart';
import 'package:beltech/data/remote/supabase/supabase_polling.dart';
import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:beltech/features/expenses/data/services/merchant_learning_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_expenses_repository_impl_review.dart';
part 'supabase_expenses_repository_impl_support.dart';

class SupabaseExpensesRepositoryImpl implements ExpensesRepository {
  SupabaseExpensesRepositoryImpl(
    this._client,
    this._parser, [
    MerchantLearningService? merchantLearningService,
    DeviceSmsDataSource? deviceSmsDataSource,
  ])  : _merchantLearningService =
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
    await _merchantLearningService.learn(
      merchantTitle: title,
      category: category,
    );
    await _client.from('transactions').insert({
      'owner_id': userId,
      'title': title,
      'category': category,
      'amount': amountKes,
      'occurred_at': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
      'source': 'manual',
      'source_hash': null,
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
    await _merchantLearningService.learn(
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
          'source': 'manual',
          'source_hash': null,
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
    var imported = 0;
    for (final raw in rawMessages) {
      final candidate = _parser.parseSingleDetailed(raw.trim());
      if (candidate == null) {
        continue;
      }
      if (from != null && candidate.occurredAt.isBefore(from)) {
        continue;
      }
      if (await _isDuplicateImpl(this, userId, candidate)) {
        await _safeAuditImpl(
          this,
          userId: userId,
          candidate: candidate,
          decision: 'duplicate',
        );
        continue;
      }
      if (candidate.route == MpesaParseRoute.directLedger) {
        final learned = await _merchantLearningService.resolveCategory(
          merchantTitle: candidate.title,
          fallbackCategory: candidate.category,
        );
        await _client.from('transactions').insert({
          'owner_id': userId,
          'title': candidate.title,
          'category': learned,
          'amount': candidate.amountKes,
          'occurred_at': candidate.occurredAt.toUtc().toIso8601String(),
          'source': 'sms',
          'source_hash': candidate.sourceHash,
        });
        await _safePaybillAndFulizaImpl(this, userId, candidate);
        await _safeAuditImpl(
          this,
          userId: userId,
          candidate: candidate,
          decision: 'imported',
        );
        imported += 1;
        continue;
      }
      if (candidate.route == MpesaParseRoute.reviewQueue) {
        await _safeInsertReviewItemImpl(this, userId, candidate);
        await _safeAuditImpl(
          this,
          userId: userId,
          candidate: candidate,
          decision: 'review_pending',
        );
        continue;
      }
      await _safeInsertQuarantineItemImpl(this, userId, candidate);
      await _safeAuditImpl(
        this,
        userId: userId,
        candidate: candidate,
        decision: 'quarantined',
      );
    }
    return imported;
  }

  @override
  Future<int> importFromDevice({DateTime? from}) async {
    final messages = await _deviceSmsDataSource.loadLikelyMpesaMessages(
      from: from,
    );
    if (messages.isEmpty) {
      return 0;
    }
    return importSmsMessages(messages, from: from);
  }

  @override
  Future<ExpenseImportMetrics> fetchImportMetrics() =>
      _fetchImportMetricsImpl(this);

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

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Sign in is required.');
    }
    return userId;
  }
}
