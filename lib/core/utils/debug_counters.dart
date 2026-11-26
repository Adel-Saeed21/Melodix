import 'package:flutter/foundation.dart';

/// Debug-only counters for expensive operations, used by tests to verify
/// work isn't repeated. Counting happens inside `assert`, so release builds
/// do no work here.
@visibleForTesting
class DebugCounters {
  DebugCounters._();

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
