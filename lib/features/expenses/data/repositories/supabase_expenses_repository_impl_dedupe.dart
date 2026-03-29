part of 'supabase_expenses_repository_impl.dart';

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
        .inFilter('decision', ['imported', 'duplicate', 'review_pending'])
        .limit(1),
  );
  if (semanticRows.isNotEmpty) {
    return true;
  }
  final dayStart = DateTime(
    candidate.occurredAt.year,
    candidate.occurredAt.month,
    candidate.occurredAt.day,
  );
  final dayEnd = dayStart.add(const Duration(days: 1));
  final nearRows = await _safeSelectImpl(
    repo,
    table: 'transactions',
    filters: (query) => query
        .select('id')
        .eq('owner_id', userId)
        .eq('title', candidate.title)
        .gte('amount', candidate.amountKes - 1.0)
        .lte('amount', candidate.amountKes + 1.0)
        .gte('occurred_at', dayStart.toUtc().toIso8601String())
        .lte('occurred_at', dayEnd.toUtc().toIso8601String())
        .limit(1),
  );
  return nearRows.isNotEmpty;
}
