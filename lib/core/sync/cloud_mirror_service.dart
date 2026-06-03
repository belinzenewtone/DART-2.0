import 'package:beltech/core/sync/cloud_sync_dispatcher.dart';
import 'package:beltech/core/sync/sync_mutation_enqueuer.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudMirrorService {
  CloudMirrorService(
    this._store,
    this._mutationEnqueuer,
    this._dispatcher, [
    SharedPreferences? prefs,
  ]) : _prefs = prefs;

  final AppDriftStore _store;
  final SyncMutationEnqueuer _mutationEnqueuer;
  final CloudSyncDispatcher _dispatcher;
  final SharedPreferences? _prefs;

  static const _lastMirrorSyncKey = 'cloud_mirror_last_sync';

  Future<SharedPreferences> get _resolvePrefs =>
      _prefs != null ? Future.value(_prefs) : SharedPreferences.getInstance();

  Future<void> mirrorSync() async {
    final prefs = await _resolvePrefs;
    final lastSync = prefs.getInt(_lastMirrorSyncKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    await _scanTable('transactions', 'occurred_at', lastSync);
    await _scanTable('tasks', 'due_at', lastSync);
    await _scanTable('events', 'start_at', lastSync);
    await _scanTable('incomes', 'received_at', lastSync);
    await _scanTable('budgets', 'id', lastSync);
    await _scanTable('recurring_templates', 'next_run_at', lastSync);

    await _dispatcher.processQueue();

    await _resolvePrefs.then((p) => p.setInt(_lastMirrorSyncKey, now));
  }

  Future<void> _scanTable(String table, String dateColumn, int since) async {
    final rows = await _store.executor.runSelect(
      'SELECT id FROM $table WHERE $dateColumn > ? ORDER BY $dateColumn DESC LIMIT 200',
      [since],
    );
    for (final row in rows) {
      final id = _asInt(row['id']);
      final entityType = table == 'recurring_templates'
          ? 'recurring'
          : table.replaceAll(RegExp(r's$'), '');
      await _mutationEnqueuer.enqueuePush(entityType, id, {'id': id});
    }
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
