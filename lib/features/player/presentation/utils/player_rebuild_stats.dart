import 'package:flutter/foundation.dart';

/// Debug-only build counters for the player UI, used by tests to verify
/// which widgets rebuild on position ticks. Counting happens inside
/// `assert`, so release builds do no work here.
@visibleForTesting
class PlayerRebuildStats {
  PlayerRebuildStats._();

  static final Map<String, int> counts = {};

  static void hit(String key) {
    assert(() {
      counts[key] = (counts[key] ?? 0) + 1;
      return true;
    }());
  }

  static int of(String key) => counts[key] ?? 0;

  static void reset() => counts.clear();
}
