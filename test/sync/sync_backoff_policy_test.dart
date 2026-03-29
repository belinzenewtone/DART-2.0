import 'package:beltech/core/sync/sync_backoff_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = SyncBackoffPolicy();

  test('retry windows increase with attempts and remain capped', () {
    final now = DateTime(2026, 3, 21, 10, 0, 0);
    final first = policy.nextRetryAt(attempt: 1, now: now);
    final third = policy.nextRetryAt(attempt: 3, now: now);
    final tenth = policy.nextRetryAt(attempt: 10, now: now);

    expect(first.isAfter(now), isTrue);
    expect(third.isAfter(first), isTrue);

    final maxDelay = const Duration(minutes: 15, milliseconds: 900);
    expect(tenth.difference(now) <= maxDelay, isTrue);
  });
}
