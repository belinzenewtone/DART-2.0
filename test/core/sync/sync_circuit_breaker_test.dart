import 'package:beltech/core/sync/sync_circuit_breaker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SyncCircuitBreaker — closed state', () {
    test('circuit is closed with zero failures', () async {
      final cb = SyncCircuitBreaker(threshold: 3);
      expect(await cb.isOpen(), isFalse);
    });

    test('circuit remains closed below threshold', () async {
      final cb = SyncCircuitBreaker(threshold: 3);
      await cb.recordFailure();
      await cb.recordFailure();
      expect(await cb.isOpen(), isFalse);
    });

    test('recordSuccess resets failure count', () async {
      final cb = SyncCircuitBreaker(threshold: 3);
      await cb.recordFailure();
      await cb.recordFailure();
      await cb.recordSuccess();
      expect(await cb.isOpen(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('sync_circuit_failure_count'), 0);
    });
  });

  group('SyncCircuitBreaker — open state', () {
    test('circuit opens after threshold failures', () async {
      final cb = SyncCircuitBreaker(threshold: 3);
      await cb.recordFailure();
      await cb.recordFailure();
      await cb.recordFailure(); // hits threshold
      expect(await cb.isOpen(), isTrue);
    });

    test('additional failures beyond threshold do not reset opened_at', () async {
      final cb = SyncCircuitBreaker(threshold: 3);
      await cb.recordFailure();
      await cb.recordFailure();
      await cb.recordFailure(); // opens

      final prefs = await SharedPreferences.getInstance();
      final openedAt1 = prefs.getInt('sync_circuit_opened_at_ms');

      await cb.recordFailure(); // extra failure
      final openedAt2 = prefs.getInt('sync_circuit_opened_at_ms');

      // opened_at should not change on subsequent failures
      expect(openedAt2, openedAt1);
    });

    test('circuit blocks sync when open', () async {
      final cb = SyncCircuitBreaker(threshold: 2);
      await cb.recordFailure();
      await cb.recordFailure();
      expect(await cb.isOpen(), isTrue);
    });

    test('recordSuccess clears opened_at key', () async {
      final cb = SyncCircuitBreaker(threshold: 2);
      await cb.recordFailure();
      await cb.recordFailure();
      await cb.recordSuccess();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('sync_circuit_opened_at_ms'), isNull);
    });
  });

  group('SyncCircuitBreaker — half-open state', () {
    test('circuit becomes half-open after cooldown elapses', () async {
      // Use a very short cooldown so we can simulate it via backdated prefs.
      final cb = SyncCircuitBreaker(
        threshold: 2,
        cooldown: const Duration(minutes: 30),
      );

      // Manually seed state: count ≥ threshold and opened_at 60 minutes ago.
      final pastMs = DateTime.now()
          .subtract(const Duration(minutes: 60))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'sync_circuit_failure_count': 2,
        'sync_circuit_opened_at_ms': pastMs,
      });

      // After cooldown, isOpen() should return false (half-open = allow trial).
      expect(await cb.isOpen(), isFalse);

      // Count should be reset to threshold - 1 (i.e. 1).
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('sync_circuit_failure_count'), 1);
      expect(prefs.getInt('sync_circuit_opened_at_ms'), isNull);
    });

    test('half-open: success closes the circuit fully', () async {
      SharedPreferences.setMockInitialValues({
        'sync_circuit_failure_count': 2,
        'sync_circuit_opened_at_ms':
            DateTime.now().subtract(const Duration(minutes: 60)).millisecondsSinceEpoch,
      });

      final cb = SyncCircuitBreaker(threshold: 2, cooldown: const Duration(minutes: 30));

      // Transition to half-open.
      expect(await cb.isOpen(), isFalse);

      // Record success — should fully close (count → 0).
      await cb.recordSuccess();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('sync_circuit_failure_count'), 0);
      expect(await cb.isOpen(), isFalse);
    });

    test('half-open: failure reopens the circuit', () async {
      SharedPreferences.setMockInitialValues({
        'sync_circuit_failure_count': 2,
        'sync_circuit_opened_at_ms':
            DateTime.now().subtract(const Duration(minutes: 60)).millisecondsSinceEpoch,
      });

      final cb = SyncCircuitBreaker(threshold: 2, cooldown: const Duration(minutes: 30));

      // Transition to half-open (count reset to threshold - 1 = 1).
      await cb.isOpen();

      // One more failure should reopen (count 1 + 1 = 2 ≥ threshold).
      await cb.recordFailure();
      expect(await cb.isOpen(), isTrue);
    });
  });

  group('SyncCircuitBreaker — cooldown not yet elapsed', () {
    test('circuit stays open within cooldown window', () async {
      // opened_at 10 minutes ago, cooldown is 30 minutes → still open.
      SharedPreferences.setMockInitialValues({
        'sync_circuit_failure_count': 5,
        'sync_circuit_opened_at_ms':
            DateTime.now().subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
      });

      final cb = SyncCircuitBreaker(threshold: 5, cooldown: const Duration(minutes: 30));
      expect(await cb.isOpen(), isTrue);
    });
  });
}
