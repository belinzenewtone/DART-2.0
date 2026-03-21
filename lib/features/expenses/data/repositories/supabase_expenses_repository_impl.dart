import 'package:beltech/data/remote/supabase/supabase_parsers.dart';
import 'package:beltech/data/remote/supabase/supabase_polling.dart';
import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:beltech/features/expenses/data/services/merchant_learning_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_expenses_repository_impl_intelligence.dart';
part 'supabase_expenses_repository_impl_review.dart';
part 'supabase_expenses_repository_impl_support.dart';
part 'supabase_expenses_repository_impl_queue.dart';

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
    final now = DateTime.now().toUtc().toIso8601String();
    for (final raw in rawMessages) {
      final message = raw.trim();
      if (message.isEmpty) {
        continue;
      }
      final candidate = _parser.parseSingleDetailed(message);
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
          'status': 'pending',
          'route': candidate?.route.name ?? MpesaParseRoute.quarantine.name,
          'confidence': candidate?.confidenceScore ?? 0,
          'attempt': 0,
          'created_at': now,
          'updated_at': now,
        },
      );
    }
    return _processQueuedImportsImpl(this, userId, from: from);
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
  Future<int> replayImportQueue() {
    final userId = _requireUserId();
    return _replayImportQueueImpl(this, userId);
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Sign in is required.');
    }
    return userId;
  }
}
