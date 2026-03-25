import 'package:beltech/core/logger/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prevents sync storms after repeated consecutive failures.
///
/// The circuit opens after [threshold] consecutive failures and stays open
/// for [cooldown]. Once the cooldown elapses the circuit moves to half-open
/// (one trial allowed); a success closes it, another failure reopens it.
///
/// All state is persisted in [SharedPreferences] so the breaker survives
/// app restarts and works across foreground + background isolates.
class SyncCircuitBreaker {
  SyncCircuitBreaker({
    this.threshold = 5,
    this.cooldown = const Duration(minutes: 30),
  });

  final int threshold;
  final Duration cooldown;

  static const String _failureCountKey = 'sync_circuit_failure_count';
  static const String _openedAtKey = 'sync_circuit_opened_at_ms';

  /// Returns `true` when the circuit is open and sync should be skipped.
  Future<bool> isOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_failureCountKey) ?? 0;
    if (count < threshold) return false;

    final openedAtMs = prefs.getInt(_openedAtKey);
    if (openedAtMs == null) return false;

    final openedAt = DateTime.fromMillisecondsSinceEpoch(openedAtMs);
    final elapsed = DateTime.now().difference(openedAt);

    if (elapsed >= cooldown) {
      // Cooldown elapsed — allow one half-open trial by resetting count to
      // threshold - 1, so a single success fully closes the circuit.
      await prefs.setInt(_failureCountKey, threshold - 1);
      await prefs.remove(_openedAtKey);
      AppLogger.info(
        'Sync circuit half-open after ${elapsed.inMinutes}m cooldown',
        tag: 'SyncCircuit',
      );
      return false;
    }

    return true;
  }

  /// Call after a successful sync to fully close the circuit.
  Future<void> recordSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_failureCountKey, 0);
    await prefs.remove(_openedAtKey);
  }

  /// Call after a failed sync to increment the failure count.
  /// Opens the circuit when [threshold] is reached.
  Future<void> recordFailure() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_failureCountKey) ?? 0) + 1;
    await prefs.setInt(_failureCountKey, count);

    if (count >= threshold) {
      final alreadyOpen = prefs.getInt(_openedAtKey) != null;
      if (!alreadyOpen) {
        await prefs.setInt(
          _openedAtKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        AppLogger.warning(
          'Sync circuit opened after $count consecutive failures',
          tag: 'SyncCircuit',
        );
      }
    }
  }
}
