import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/player/data/equalizer/android_equalizer_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('melodix/equalizer-test');

  late List<MethodCall> calls;
  late StreamController<int?> sessions;

  /// What `attach` answers (or throws, like the Realme's equalizer).
  late Object? Function(int sessionId) attach;

  void fakeNative() => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'attach') {
          return attach((call.arguments as Map)['sessionId'] as int);
        }
        return null;
      });

  Map<String, Object> bands() => {
    'centers': [60.0, 1000.0, 14000.0],
    'minDb': -15.0,
    'maxDb': 15.0,
  };

  setUp(() {
    calls = [];
    sessions = StreamController<int?>();
    attach = (_) => bands();
    fakeNative();
  });

  tearDown(() async {
    await sessions.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  AndroidEqualizerEngine engine() => AndroidEqualizerEngine(
    audioSessionIds: sessions.stream,
    channel: channel,
  );

  List<String> methods() => [for (final c in calls) c.method];

  test('settings chosen before the player has a session apply once it has '
      'one: each band its centre gain, within the limits', () async {
    final eq = engine();
    await eq.setGains((hz) => hz < 100 ? 20 : -3); // 20 is past the max
    await eq.setEnabled(true);
    expect(calls, isEmpty); // nothing to talk to yet

    sessions.add(null); // the player has no session yet
    sessions.add(42);
    await pumpEventQueue();
    expect(methods(), ['attach', 'setGains', 'setEnabled']);
    expect((calls[0].arguments as Map)['sessionId'], 42);
    expect((calls[1].arguments as Map)['gains'], [15.0, -3.0, -3.0]);
    expect((calls[2].arguments as Map)['enabled'], isTrue);
    await eq.dispose();
  });

  test('changes go straight through once attached', () async {
    final eq = engine();
    sessions.add(7);
    await pumpEventQueue();
    calls.clear();

    await eq.setEnabled(true);
    await eq.setGains((_) => 2);
    expect(methods(), ['setEnabled', 'setGains']);
    expect((calls[1].arguments as Map)['gains'], [2.0, 2.0, 2.0]);
    await eq.dispose();
  });

  test('a new session gets a new equalizer, with the same settings', () async {
    final eq = engine();
    await eq.setEnabled(true);
    sessions.add(7);
    await pumpEventQueue();
    calls.clear();

    sessions
      ..add(7) // the same one again: nothing to do
      ..add(9);
    await pumpEventQueue();
    expect(methods(), ['attach', 'setEnabled']);
    expect((calls[0].arguments as Map)['sessionId'], 9);
    await eq.dispose();
  });

  test('a phone whose equalizer fails: nothing throws, and it tries again '
      'with the next session', () async {
    attach = (_) => throw PlatformException(code: 'equalizer_failed');
    final eq = engine();
    sessions.add(7);
    await pumpEventQueue();
    // Settings still accepted (and nothing sent to a broken equalizer).
    await eq.setEnabled(true);
    await eq.setGains((_) => 1);
    expect(methods(), ['attach']);

    attach = (_) => bands();
    sessions.add(8);
    await pumpEventQueue();
    expect(methods(), ['attach', 'attach', 'setGains', 'setEnabled']);
    await eq.dispose();
  });

  test(
    'an odd answer from the phone is ignored; later calls still run',
    () async {
      attach = (_) => {'centers': 'nonsense'};
      final eq = engine();
      sessions.add(7);
      await pumpEventQueue();

      attach = (_) => bands();
      sessions.add(8);
      await pumpEventQueue();
      await eq.setEnabled(true);
      expect(methods().last, 'setEnabled');
      await eq.dispose();
    },
  );

  test('dispose releases the equalizer', () async {
    final eq = engine();
    sessions.add(7);
    await pumpEventQueue();
    await eq.dispose();
    expect(methods().last, 'release');
  });
}
