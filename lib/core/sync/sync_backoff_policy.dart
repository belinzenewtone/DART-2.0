import 'dart:math';

class SyncBackoffPolicy {
  const SyncBackoffPolicy();

  DateTime nextRetryAt({required int attempt, DateTime? now}) {
    final baseTime = now ?? DateTime.now();
    final boundedAttempt = attempt.clamp(1, 7);
    final exponentialMs = pow(2, boundedAttempt).toInt() * 1000;
    final jitterMs = Random().nextInt(900);
    final cappedMs = exponentialMs.clamp(0, 15 * 60 * 1000);
    return baseTime.add(Duration(milliseconds: cappedMs + jitterMs));
  }
}
