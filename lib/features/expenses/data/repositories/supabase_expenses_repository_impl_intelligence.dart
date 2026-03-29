part of 'supabase_expenses_repository_impl.dart';

Future<List<PaybillProfile>> _fetchPaybillProfilesImpl(
  SupabaseExpensesRepositoryImpl repo, {
  int limit = 10,
}) async {
  final userId = repo._requireUserId();
  final rows = await _safeSelectImpl(
    repo,
    table: 'paybill_registry',
    filters: (query) => query
        .select('id,paybill,display_name,last_seen_at,usage_count')
        .eq('owner_id', userId)
        .order('last_seen_at', ascending: false)
        .limit(limit),
  );
  return rows
      .map(
        (row) => PaybillProfile(
          id: parseInt(row['id']),
          paybill: '${row['paybill'] ?? ''}',
          displayName: '${row['display_name'] ?? ''}',
          lastSeenAt: parseTimestamp(row['last_seen_at']),
          usageCount: parseInt(row['usage_count']),
        ),
      )
      .toList();
}

Future<List<FulizaLifecycleEvent>> _fetchFulizaLifecycleImpl(
  SupabaseExpensesRepositoryImpl repo, {
  int limit = 12,
}) async {
  final userId = repo._requireUserId();
  final rows = await _safeSelectImpl(
    repo,
    table: 'fuliza_lifecycle_events',
    filters: (query) => query
        .select('id,mpesa_code,event_kind,amount,occurred_at')
        .eq('owner_id', userId)
        .order('occurred_at', ascending: false)
        .limit(limit),
  );
  return rows
      .map(
        (row) => FulizaLifecycleEvent(
          id: parseInt(row['id']),
          mpesaCode: '${row['mpesa_code'] ?? ''}',
          kind: '${row['event_kind'] ?? ''}' ==
                  MpesaTransactionType.fulizaDraw.name
              ? FulizaLifecycleKind.draw
              : FulizaLifecycleKind.repayment,
          amountKes: parseDouble(row['amount']),
          occurredAt: parseTimestamp(row['occurred_at']),
        ),
      )
      .toList();
}
