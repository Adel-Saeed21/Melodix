import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/utils/latest_value.dart';
import 'package:melodix/core/utils/serial_runner.dart';
import 'package:melodix/features/player/data/queue/pause_requests.dart';

void main() {
  group('SerialRunner', () {
    test('runs operations one at a time, in order', () async {
      final runner = SerialRunner();
      final log = <String>[];
      final first = Completer<void>();

      final a = runner.run(() async {
        log.add('a starts');
        await first.future;
        log.add('a ends');
      });
      final b = runner.run(() async => log.add('b'));
      await pumpEventQueue();
      expect(log, ['a starts'], reason: 'b waits for a');

      first.complete();
      await Future.wait([a, b]);
      expect(log, ['a starts', 'a ends', 'b']);
    });

    test('a failed operation does not block the next one', () async {
      final runner = SerialRunner();
      final failing = runner.run<void>(() async => throw StateError('boom'));
      await expectLater(failing, throwsStateError);
      expect(await runner.run(() async => 42), 42);
    });

    test('is busy while running and says when it goes idle', () async {
      var idle = 0;
      late SerialRunner runner;
      runner = SerialRunner(onIdle: () => idle++);
      final gate = Completer<void>();
      final running = runner.run(() => gate.future);
      final queued = runner.run(() async {});
      await pumpEventQueue();
      expect(runner.isBusy, isTrue);

      gate.complete();
      await Future.wait([running, queued]);
      expect(runner.isBusy, isFalse);
      expect(idle, greaterThanOrEqualTo(1));
    });
  });

  group('LatestValue', () {
    test('watch gives the current value, then changes', () async {
      final value = LatestValue<int>(1);
      final seen = <int>[];
      final sub = value.watch().listen(seen.add);
      value
        ..set(2)
        ..set(3);
      await pumpEventQueue();
      expect(seen, [1, 2, 3]);
      await sub.cancel();
      await value.close();
    });

    test('an equal value is not sent again', () async {
      final value = LatestValue<int>(1);
      final seen = <int>[];
      final sub = value.watch().listen(seen.add);
      value
        ..set(1)
        ..set(2)
        ..set(2);
      await pumpEventQueue();
      expect(seen, [1, 2]);
      await sub.cancel();
      await value.close();
    });

    test('a change right after listening is never lost', () async {
      final value = LatestValue<int>(0);
      final seen = <int>[];
      final sub = value.watch().listen(seen.add);
      value.set(1); // before any event was delivered
      await pumpEventQueue();
      expect(seen, [0, 1]);
      await sub.cancel();
      await value.close();
    });
  });

  test('PauseRequests: a pause after the mark wins', () {
    final pauses = PauseRequests();
    final before = pauses.mark();
    expect(pauses.noneSince(before), isTrue);
    pauses.record();
    expect(pauses.noneSince(before), isFalse);
    expect(pauses.noneSince(pauses.mark()), isTrue);
  });
}
