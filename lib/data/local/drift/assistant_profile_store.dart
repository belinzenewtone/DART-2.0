import 'dart:async';

import 'package:dart_2_0/data/local/drift/assistant_profile_records.dart';
import 'package:dart_2_0/data/local/drift/drift_executor_factory.dart';
import 'package:drift/backends.dart';
import 'package:drift/drift.dart' show OpeningDetails;

class AssistantProfileStore {
  AssistantProfileStore()
      : _db = openDriftExecutor(name: 'dart_2_0_profile.sqlite', inMemory: true);
  AssistantProfileStore.persistent()
      : _db = openDriftExecutor(name: 'dart_2_0_profile.sqlite');

  final QueryExecutor _db;
  final StreamController<int> _changes = StreamController<int>.broadcast();

  bool _initialized = false;
  int _changeSeq = 0;

  Future<void> dispose() async {
    await _changes.close();
    await _db.close();
  }

  Stream<List<DriftAssistantMessageRecord>> watchMessages() =>
      _watch(_loadMessages);

  Stream<DriftProfileRecord> watchProfile() => _watch(_loadProfile);

  Future<void> addAssistantMessage({
    required String text,
    required bool isUser,
  }) async {
    await _ensureInitialized();
    await _db.runInsert(
      'INSERT INTO assistant_messages(text, is_user, created_at) VALUES (?, ?, ?)',
      [text, isUser ? 1 : 0, DateTime.now().millisecondsSinceEpoch],
    );
    _emitChange();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    await _ensureInitialized();
    await _db.runUpdate(
      'UPDATE user_profile SET name = ?, email = ?, phone = ? WHERE id = 1',
      [name, email, phone],
    );
    _emitChange();
  }

  Stream<T> _watch<T>(Future<T> Function() loader) {
    return Stream<T>.multi((controller) async {
      await _ensureInitialized();

      Future<void> publishSnapshot() async {
        if (!controller.isClosed) {
          controller.add(await loader());
        }
      }

      final subscription = _changes.stream.listen(
        (_) async => publishSnapshot(),
        onError: controller.addError,
      );

      await publishSnapshot();
      controller.onCancel = subscription.cancel;
    });
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await _db.ensureOpen(const _ProfileQueryExecutorUser());

    await _db.runCustom(
      'CREATE TABLE IF NOT EXISTS user_profile('
      'id INTEGER PRIMARY KEY,'
      'name TEXT NOT NULL,'
      'email TEXT NOT NULL,'
      'phone TEXT NOT NULL,'
      'member_since_label TEXT NOT NULL,'
      'verified INTEGER NOT NULL'
      ')',
    );
    await _db.runCustom(
      'CREATE TABLE IF NOT EXISTS assistant_messages('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'text TEXT NOT NULL,'
      'is_user INTEGER NOT NULL,'
      'created_at INTEGER NOT NULL'
      ')',
    );

    await _seedIfEmpty();
    _initialized = true;
  }

  Future<void> _seedIfEmpty() async {
    final profileCount = await _countRows('user_profile');
    if (profileCount == 0) {
      await _db.runInsert(
        'INSERT INTO user_profile(id, name, email, phone, member_since_label, verified) VALUES (?, ?, ?, ?, ?, ?)',
        [
          1,
          'testing',
          'newtonebelinzeojing@gmail.com',
          '07000000000000',
          'Friday, March 06, 2026',
          1,
        ],
      );
    }

    final messageCount = await _countRows('assistant_messages');
    if (messageCount == 0) {
      await _db.runInsert(
        'INSERT INTO assistant_messages(text, is_user, created_at) VALUES (?, ?, ?)',
        [
          "Hey! I'm your BELTECH assistant. Ask me about spending, tasks, or schedule.",
          0,
          DateTime.now().millisecondsSinceEpoch,
        ],
      );
    }
  }

  Future<DriftProfileRecord> _loadProfile() async {
    final rows = await _db.runSelect(
      'SELECT name, email, phone, member_since_label, verified FROM user_profile WHERE id = 1',
      const [],
    );
    final row = rows.first;
    return DriftProfileRecord(
      name: (row['name'] ?? '') as String,
      email: (row['email'] ?? '') as String,
      phone: (row['phone'] ?? '') as String,
      memberSinceLabel: (row['member_since_label'] ?? '') as String,
      verified: _asInt(row['verified']) == 1,
    );
  }

  Future<List<DriftAssistantMessageRecord>> _loadMessages() async {
    final rows = await _db.runSelect(
      'SELECT id, text, is_user, created_at FROM assistant_messages ORDER BY created_at ASC, id ASC',
      const [],
    );
    return rows
        .map(
          (row) => DriftAssistantMessageRecord(
            id: 'msg-${_asInt(row['id'])}',
            text: (row['text'] ?? '') as String,
            isUser: _asInt(row['is_user']) == 1,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(_asInt(row['created_at'])),
          ),
        )
        .toList();
  }

  Future<int> _countRows(String tableName) async {
    final rows = await _db
        .runSelect('SELECT COUNT(*) AS total FROM $tableName', const []);
    return _asInt(rows.first['total']);
  }

  void _emitChange() {
    _changeSeq += 1;
    _changes.add(_changeSeq);
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }
}

class _ProfileQueryExecutorUser implements QueryExecutorUser {
  const _ProfileQueryExecutorUser();

  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {}
}
