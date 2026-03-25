import 'package:beltech/core/sync/background_sync_coordinator.dart';
import 'package:beltech/core/sync/sync_circuit_breaker.dart';
import 'package:beltech/core/sync/sync_status_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class _MockCoordinator extends Mock implements BackgroundSyncCoordinator {}

class _MockCircuitBreaker extends Mock implements SyncCircuitBreaker {}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockCoordinator coordinator;
  late _MockCircuitBreaker circuit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    coordinator = _MockCoordinator();
    circuit = _MockCircuitBreaker();
  });

  SyncStatusNotifier _notifier() => SyncStatusNotifier(
        coordinator,
        circuitBreaker: circuit,
      );

  group('SyncStatusNotifier — initial state', () {
    test('starts in idle phase with no lastSyncedAt', () async {
      when(() => circuit.isOpen()).thenAnswer((_) async => false);

      final notifier = _notifier();
      expect(notifier.state.phase, SyncPhase.idle);
      expect(notifier.state.lastSyncedAt, isNull);
      notifier.dispose();
    });

    test('reads persisted last-sync timestamp from SharedPreferences',
        () async {
      final savedMs = DateTime(2026, 3, 21, 14, 0).millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'mpesa_auto_sync_last_ms_default': savedMs,
      });

      when(() => circuit.isOpen()).thenAnswer((_) async => false);

      final notifier = _notifier();
      // Allow the async _loadPersistedLastSync to complete.
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.lastSyncedAt,
          DateTime.fromMillisecondsSinceEpoch(savedMs));
      notifier.dispose();
    });

    test('picks the latest timestamp when multiple keys exist', () async {
      final older = DateTime(2026, 3, 20).millisecondsSinceEpoch;
      final newer = DateTime(2026, 3, 22).millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'mpesa_auto_sync_last_ms_acc1': older,
        'mpesa_auto_sync_last_ms_acc2': newer,
      });

      when(() => circuit.isOpen()).thenAnswer((_) async => false);

      final notifier = _notifier();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.lastSyncedAt,
          DateTime.fromMillisecondsSinceEpoch(newer));
      notifier.dispose();
    });
  });

  group('SyncStatusNotifier — runSync success path', () {
    test('transitions syncing → done → idle', () async {
      when(() => circuit.isOpen()).thenAnswer((_) async => false);
      when(() => circuit.recordSuccess()).thenAnswer((_) async {});
      when(() => coordinator.syncNow()).thenAnswer((_) async {});

      final notifier = _notifier();
      final phases = <SyncPhase>[];
      notifier.addListener((status) => phases.add(status.phase));

      await notifier.runSync();

      // After runSync the phase is 'done'; idle happens after auto-reset timer.
      expect(phases, contains(SyncPhase.syncing));
      expect(phases, contains(SyncPhase.done));
      expect(notifier.state.lastSyncedAt, isNotNull);

      verify(() => circuit.recordSuccess()).called(1);
      notifier.dispose();
    });

    test('re-entrant call while syncing is silently dropped', () async {
      when(() => circuit.isOpen()).thenAnswer((_) async => false);
      when(() => circuit.recordSuccess()).thenAnswer((_) async {});

      // Coordinator never completes — keeps notifier in syncing state.
      final completer = Future<void>.delayed(const Duration(seconds: 10));
      when(() => coordinator.syncNow()).thenAnswer((_) => completer);

      final notifier = _notifier();
      // Start first sync (don't await — it hangs).
      unawaited(notifier.runSync());
      // Verify we're in syncing state.
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.phase, SyncPhase.syncing);

      // Second call should be dropped.
      await notifier.runSync();
      // Only one syncNow call was made.
      verify(() => coordinator.syncNow()).called(1);
      notifier.dispose();
    });
  });

  group('SyncStatusNotifier — runSync failure path', () {
    test('transitions syncing → failed when coordinator throws', () async {
      when(() => circuit.isOpen()).thenAnswer((_) async => false);
      when(() => circuit.recordFailure()).thenAnswer((_) async {});
      when(() => coordinator.syncNow()).thenThrow(Exception('network error'));

      final notifier = _notifier();
      await notifier.runSync();

      expect(notifier.state.phase, SyncPhase.failed);
      verify(() => circuit.recordFailure()).called(1);
      notifier.dispose();
    });

    test('does not modify lastSyncedAt on failure', () async {
      final savedMs = DateTime(2026, 3, 21).millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'mpesa_auto_sync_last_ms_x': savedMs,
      });

      when(() => circuit.isOpen()).thenAnswer((_) async => false);
      when(() => circuit.recordFailure()).thenAnswer((_) async {});
      when(() => coordinator.syncNow()).thenThrow(Exception('timeout'));

      final notifier = _notifier();
      await Future<void>.delayed(Duration.zero); // load prefs
      await notifier.runSync();

      expect(notifier.state.lastSyncedAt,
          DateTime.fromMillisecondsSinceEpoch(savedMs));
      notifier.dispose();
    });
  });

  group('SyncStatusNotifier — circuit breaker integration', () {
    test('skips sync when circuit is open', () async {
      when(() => circuit.isOpen()).thenAnswer((_) async => true);

      final notifier = _notifier();
      await notifier.runSync();

      // Phase stays idle; coordinator never called.
      expect(notifier.state.phase, SyncPhase.idle);
      verifyNever(() => coordinator.syncNow());
      notifier.dispose();
    });
  });
}

// Silence unawaited future lint for test purposes.
void unawaited(Future<void> future) {}
