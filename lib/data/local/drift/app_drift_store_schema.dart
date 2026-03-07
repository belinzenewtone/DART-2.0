part of 'app_drift_store.dart';

class _AppDriftSchema {
  static Future<void> ensureInitialized(AppDriftStore store) async {
    if (store._initialized) {
      return;
    }
    await store._db.ensureOpen(const _StoreQueryExecutorUser());

    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS transactions('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'title TEXT NOT NULL,'
      'category TEXT NOT NULL,'
      'amount REAL NOT NULL,'
      'occurred_at INTEGER NOT NULL,'
      'source TEXT NOT NULL,'
      'source_hash TEXT'
      ')',
    );
    await tryAddSourceHashColumn(store);

    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS tasks('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'title TEXT NOT NULL,'
      'completed INTEGER NOT NULL DEFAULT 0,'
      'due_at INTEGER,'
      'priority TEXT NOT NULL DEFAULT \'medium\''
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS events('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'title TEXT NOT NULL,'
      'start_at INTEGER NOT NULL,'
      'end_at INTEGER,'
      'note TEXT'
      ')',
    );

    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_tx_occurred_at ON transactions(occurred_at)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_tx_category ON transactions(category)',
    );
    await store._db.runCustom(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_tx_source_hash ON transactions(source_hash)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_tasks_completed ON tasks(completed)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_events_start_at ON events(start_at)',
    );

    await seedDataIfEmpty(store);
    store._initialized = true;
  }

  static Future<void> seedDataIfEmpty(AppDriftStore store) async {
    final txCount = await store._countRows('transactions');
    if (txCount == 0) {
      final now = DateTime.now();
      final entries = [
        (
          'HOTEL DELITOS Via Kopo Kopo',
          'Food',
          140.0,
          now.subtract(const Duration(days: 1))
        ),
        ('GRACE NGULI', 'Other', 100.0, now.subtract(const Duration(days: 2))),
        ('DELITOS HOTEL', 'Food', 400.0, now.subtract(const Duration(days: 3))),
        ('Unknown', 'Other', 623.53, now.subtract(const Duration(days: 4))),
        ('Unknown', 'Other', 865.93, now.subtract(const Duration(days: 5))),
        (
          'Airtime Topup',
          'Airtime',
          50.0,
          now.subtract(const Duration(days: 2))
        ),
        (
          'Electricity Token',
          'Bills',
          20.0,
          now.subtract(const Duration(days: 3))
        ),
      ];
      for (final entry in entries) {
        await store._db.runInsert(
          'INSERT INTO transactions(title, category, amount, occurred_at, source, source_hash) VALUES (?, ?, ?, ?, ?, ?)',
          [
            entry.$1,
            entry.$2,
            entry.$3,
            entry.$4.millisecondsSinceEpoch,
            'seed',
            null
          ],
        );
      }
    }

    final taskCount = await store._countRows('tasks');
    if (taskCount == 0) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await store._db.runInsert(
        'INSERT INTO tasks(title, completed, due_at, priority) VALUES (?, ?, ?, ?)',
        ['Prepare monthly spending review', 0, nowMs, 'high'],
      );
      await store._db.runInsert(
        'INSERT INTO tasks(title, completed, due_at, priority) VALUES (?, ?, ?, ?)',
        ['Submit transport expense report', 1, nowMs, 'medium'],
      );
    }
  }

  static Future<void> tryAddSourceHashColumn(AppDriftStore store) async {
    try {
      await store._db
          .runCustom('ALTER TABLE transactions ADD COLUMN source_hash TEXT');
    } catch (_) {
      return;
    }
  }
}
