import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/utils/lru_cache.dart';
import 'package:melodix/core/utils/single_flight.dart';

void main() {
  group('SingleFlight', () {
    test(
      'concurrent callers share one run; a later call starts anew',
      () async {
        final flight = SingleFlight<int>();
        final gate = Completer<int>();
        var runs = 0;
        Future<int> task() {
          runs++;
          return runs == 1 ? gate.future : Future.value(runs);
        }

        final a = flight.run(task);
        final b = flight.run(task);
        gate.complete(1);

        expect(await a, 1);
        expect(await b, 1);
        expect(runs, 1);
        expect(flight.running, isNull);
        expect(await flight.run(task), 2);
      },
    );

    test('runAfterCurrent waits, then gets its own run', () async {
      final flight = SingleFlight<String>();
      final gate = Completer<String>();
      final order = <String>[];

      final first = flight.run(() => gate.future);
      final forced = flight.runAfterCurrent(() async {
        order.add('forced');
        return 'forced';
      });
      order.add('released');
      gate.complete('first');

      expect(await first, 'first');
      expect(await forced, 'forced');
      expect(order, ['released', 'forced']);
    });

    test('a failed run is cleared so the next call retries', () async {
      final flight = SingleFlight<int>();
      await expectLater(
        flight.run(() async => throw StateError('x')),
        throwsStateError,
      );
      expect(await flight.run(() async => 3), 3);
    });
  });

  group('LruCache', () {
    test('evicts the least recently used entry', () {
      final cache = LruCache<String, int>(capacity: 2)
        ..put('a', 1)
        ..put('b', 2);
      cache.get('a'); // a is now most recent
      cache.put('c', 3);

      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
      expect(cache.length, 2);
    });

    test('caches null values', () {
      final cache = LruCache<int, String?>(capacity: 1)..put(1, null);

      expect(cache.containsKey(1), isTrue);
      expect(cache.get(1), isNull);
    });
  });
}
