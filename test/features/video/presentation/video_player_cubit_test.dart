import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/fake_video_engine.dart';
import '../video_fixtures.dart';

void main() {
  late VideoPlayerHarness h;

  setUpAll(registerVideoFallbacks);
  setUp(() => h = VideoPlayerHarness());

  final a = testVideo('a');
  final b = testVideo('b');
  final c = testVideo('c');

  test('opens, plays, pauses the music and counts the play', () async {
    final cubit = h.cubit();
    await cubit.open([a, b], 0);

    expect(cubit.state.status, VideoPlayerStatus.ready);
    expect(cubit.state.engine!.value.isPlaying, isTrue);
    expect(h.musicPauses, 1);
    verify(() => h.recordPlay('a')).called(1);
    await cubit.close();
  });

  test('open is active at once (the player route can be pushed next)', () {
    final cubit = h.cubit();
    unawaited(cubit.open([a, b], 1));
    // No await: the full player is shown right after open() returns, and
    // its route sends you home when no video is open.
    expect(cubit.state.isActive, isTrue);
    expect(cubit.state.video, b);
  });

  test('resumes where it stopped, unless that was the very end', () async {
    h = VideoPlayerHarness(
      saved: {
        'a': const Duration(minutes: 3),
        'b': const Duration(minutes: 9, seconds: 58), // within 10 s of the end
      },
    );
    final cubit = h.cubit();
    await cubit.open([a, b], 0);
    expect(h.engines['a']!.seeks, [const Duration(minutes: 3)]);

    await cubit.next();
    expect(h.engines['b']!.seeks, isEmpty); // from the start
    await cubit.close();
  });

  test('a missing video is an error with a way on, not a jump', () async {
    h = VideoPlayerHarness(missing: ['a']);
    final cubit = h.cubit();
    await cubit.open([a, b], 0);

    expect(cubit.state.status, VideoPlayerStatus.failed);
    expect(cubit.state.error, VideoPlayerError.missing);
    expect(cubit.state.index, 0); // still on it
    expect(h.musicPauses, 0); // nothing played

    await cubit.next();
    expect(cubit.state.status, VideoPlayerStatus.ready);
    expect(cubit.state.video, b);
    await cubit.close();
  });

  test('an unplayable file says so, and its player is released', () async {
    h = VideoPlayerHarness(unplayable: ['a']);
    final cubit = h.cubit();
    await cubit.open([a], 0);

    expect(cubit.state.error, VideoPlayerError.unplayable);
    expect(h.engines['a']!.disposed, isTrue);
    verifyNever(() => h.recordPlay(any()));
    await cubit.close();
  });

  test('skipping on while one loads never lets the older one start', () async {
    final gates = <String, Completer<void>>{};
    h.engineFor = (uri) {
      final gate = gates[uri.pathSegments.last] = Completer<void>();
      return FakeVideoEngine(uri, initGate: gate);
    };
    final cubit = h.cubit();
    final first = cubit.open([a, b, c], 0);
    await pumpEventQueue();
    final second = cubit.next(); // while "a" still loads
    await pumpEventQueue();

    gates['b']!.complete();
    await second;
    gates['a']!.complete();
    await first;

    expect(cubit.state.video, b);
    expect(cubit.state.engine, same(h.engines['b']));
    expect(h.engines['a']!.disposed, isTrue);
    expect(h.engines['a']!.value.isPlaying, isFalse);
    verifyNever(() => h.recordPlay('a'));
    await cubit.close();
  });

  test('saves where it stopped: on pause, on switching and on close', () async {
    final cubit = h.cubit();
    await cubit.open([a, b], 0);
    final player = h.engines['a']!;

    player.advanceTo(const Duration(minutes: 2));
    await cubit.pause();
    verify(
      () => h.savePosition(
        'a',
        const Duration(minutes: 2),
        length: any(named: 'length'),
      ),
    ).called(1);

    await cubit.togglePlayPause();
    player.advanceTo(const Duration(minutes: 4));
    await cubit.next();
    verify(
      () => h.savePosition(
        'a',
        const Duration(minutes: 4),
        length: any(named: 'length'),
      ),
    ).called(greaterThanOrEqualTo(1));
    // Nothing shows it here, so it's released at once (on screen it waits
    // for its views to go; see video_player_engine_test).
    expect(player.disposed, isTrue);

    // Going back resumes at 4:00 (just saved).
    await cubit.previous();
    expect(cubit.state.video.id, 'a');
    expect(h.engines['a']!.seeks.last, const Duration(minutes: 4));

    h.engines['a']!.advanceTo(const Duration(minutes: 5));
    await cubit.close();
    verify(
      () => h.savePosition(
        'a',
        const Duration(minutes: 5),
        length: any(named: 'length'),
      ),
    ).called(1);
  });

  test('saves every so often while playing (a crash loses seconds)', () async {
    final cubit = h.cubit(saveEvery: const Duration(milliseconds: 30));
    await cubit.open([a], 0);
    h.engines['a']!.advanceTo(const Duration(seconds: 40));

    // Several periods, so a busy machine can't make it miss one.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    verify(
      () => h.savePosition(
        'a',
        const Duration(seconds: 40),
        length: any(named: 'length'),
      ),
    ).called(greaterThanOrEqualTo(1));

    // Paused: nothing new to save, so no more writes.
    await cubit.pause();
    clearInteractions(h.savePosition);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    verifyNever(
      () => h.savePosition(any(), any(), length: any(named: 'length')),
    );
    await cubit.close();
  });

  test('previous: restarts the video when past 5 s', () async {
    final cubit = h.cubit();
    await cubit.open([a, b], 1);
    h.engines['b']!.advanceTo(const Duration(seconds: 30));

    await cubit.previous();
    expect(cubit.state.video, b);
    expect(h.engines['b']!.value.position, Duration.zero);

    await cubit.previous();
    expect(cubit.state.video, a);
    await cubit.close();
  });

  test('seeks stay within the video', () async {
    final cubit = h.cubit();
    await cubit.open([a], 0);
    await cubit.seekBy(const Duration(seconds: -10));
    expect(h.engines['a']!.value.position, Duration.zero);
    await cubit.seek(const Duration(hours: 1));
    expect(h.engines['a']!.value.position, const Duration(minutes: 10));
    await cubit.close();
  });

  test('the speed carries over to the next video', () async {
    final cubit = h.cubit();
    await cubit.open([a, b], 0);
    await cubit.setSpeed(1.5);
    expect(h.engines['a']!.speed, 1.5);
    await cubit.next();
    expect(h.engines['b']!.speed, 1.5);
    await cubit.close();
  });

  test('play after the end starts over', () async {
    final cubit = h.cubit();
    await cubit.open([a], 0);
    h.engines['a']!.finish();
    await pumpEventQueue();

    await cubit.togglePlayPause();
    expect(h.engines['a']!.value.position, Duration.zero);
    expect(h.engines['a']!.value.isPlaying, isTrue);
    await cubit.close();
  });

  test('saving progress never changes the state (nothing redraws)', () async {
    final cubit = h.cubit();
    await cubit.open([a], 0);
    final states = <VideoPlayerState>[];
    final sub = cubit.stream.listen(states.add);

    h.engines['a']!.advanceTo(const Duration(minutes: 2));
    await cubit.pause(); // saves
    await pumpEventQueue();
    await sub.cancel();
    expect(states, isEmpty);
    await cubit.close();
  });

  test(
    'the end of a video is saved as watched (starts over next time)',
    () async {
      final cubit = h.cubit();
      await cubit.open([a, b], 0);
      h.engines['a']!.finish();
      await pumpEventQueue();

      await cubit.next();
      await cubit.previous(); // back to a
      expect(cubit.state.video, a);
      expect(h.engines['a']!.seeks, isEmpty); // from the start
      await cubit.close();
    },
  );

  group('app-wide session', () {
    test('starts with nothing open', () async {
      final cubit = h.cubit();
      expect(cubit.state.isActive, isFalse);
      // Nothing to act on: no errors.
      await cubit.togglePlayPause();
      await cubit.next();
      await cubit.retry();
      await cubit.close();
    });

    test('stop saves, releases the video and ends the session', () async {
      final cubit = h.cubit();
      await cubit.open([a], 0);
      cubit.setExpanded(true);
      h.engines['a']!.advanceTo(const Duration(minutes: 1));

      await cubit.stop();
      await pumpEventQueue();
      expect(cubit.state.isActive, isFalse);
      expect(cubit.state.expanded, isFalse);
      expect(cubit.state.engine, isNull);
      expect(h.engines['a']!.disposed, isTrue);
      verify(
        () => h.savePosition(
          'a',
          const Duration(minutes: 1),
          length: any(named: 'length'),
        ),
      ).called(1);
      await cubit.close();
    });

    test('opening another list replaces the video (old place saved)', () async {
      final cubit = h.cubit();
      await cubit.open([a, b], 0);
      h.engines['a']!.advanceTo(const Duration(minutes: 2));

      await cubit.open([c], 0);
      expect(cubit.state.video, c);
      expect(cubit.state.queue, [c]);
      verify(
        () => h.savePosition(
          'a',
          const Duration(minutes: 2),
          length: any(named: 'length'),
        ),
      ).called(1);
      await cubit.close();
    });

    test('music starting pauses the video', () async {
      final cubit = h.cubit();
      await cubit.open([a], 0);
      expect(h.engines['a']!.value.isPlaying, isTrue);

      h.musicPlaying.add(true);
      await pumpEventQueue();
      expect(h.engines['a']!.value.isPlaying, isFalse);
      await cubit.close();
    });

    test('minimizing keeps it playing', () async {
      final cubit = h.cubit();
      await cubit.open([a], 0);
      cubit
        ..setExpanded(true)
        ..setExpanded(false);
      expect(cubit.state.isActive, isTrue);
      expect(h.engines['a']!.value.isPlaying, isTrue);
      await cubit.close();
    });
  });

  group('play next / add to queue', () {
    test('nothing open: they start playing (and it says so)', () async {
      final cubit = h.cubit();
      expect(cubit.playNext([b, c]), isTrue);
      await pumpEventQueue();
      expect(cubit.state.video, b);
      expect(cubit.state.queue, [b, c]);
      await cubit.close();
    });

    test('play next: right after the current one, which carries on', () async {
      final cubit = h.cubit();
      await cubit.open([a, b], 0);
      final engine = cubit.state.engine;

      expect(cubit.playNext([c]), isFalse);
      expect(cubit.state.queue, [a, c, b]);
      expect(cubit.state.video, a);
      expect(cubit.state.engine, same(engine)); // not reopened

      await cubit.next();
      expect(cubit.state.video, c);
      await cubit.close();
    });

    test('add to queue: at the end', () async {
      final cubit = h.cubit();
      await cubit.open([a, b], 1);
      expect(cubit.addToQueue([c]), isFalse);
      expect(cubit.state.queue, [a, b, c]);
      expect(cubit.state.index, 1);
      expect(cubit.state.hasNext, isTrue);
      await cubit.close();
    });
  });

  group('listen as audio', () {
    test('switching keeps the same playback: no reload, no jump', () async {
      final cubit = h.cubit();
      await cubit.open([a, b], 0);
      final engine = h.engines['a']!..advanceTo(const Duration(minutes: 2));

      cubit.toggleAudioOnly();
      expect(cubit.state.audioOnly, isTrue);
      expect(cubit.state.engine, same(engine));
      expect(engine.value.isPlaying, isTrue);
      expect(engine.value.position, const Duration(minutes: 2));
      expect(engine.seeks, isEmpty);

      cubit.toggleAudioOnly();
      expect(cubit.state.audioOnly, isFalse);
      expect(cubit.state.engine, same(engine));
      expect(engine.value.isPlaying, isTrue);
      await cubit.close();
    });

    test('stays on for the next videos; stop turns it off', () async {
      final cubit = h.cubit();
      await cubit.open([a, b, c], 0);
      cubit.setAudioOnly(true);

      await cubit.next();
      expect(cubit.state.video, b);
      expect(cubit.state.audioOnly, isTrue);
      await cubit.playAt(2);
      expect(cubit.state.audioOnly, isTrue);

      await cubit.stop();
      expect(cubit.state.audioOnly, isFalse);
      await cubit.close();
    });

    test(
      'can open straight as audio; nothing to switch with no video',
      () async {
        final cubit = h.cubit();
        cubit.setAudioOnly(true);
        expect(cubit.state.audioOnly, isFalse); // nothing open

        await cubit.open([a], 0, audioOnly: true);
        expect(cubit.state.audioOnly, isTrue);
        expect(cubit.state.engine!.value.isPlaying, isTrue);

        await cubit.open([b], 0); // a fresh choice: watched
        expect(cubit.state.audioOnly, isFalse);
        await cubit.close();
      },
    );
  });

  group('app hidden', () {
    test('a watched video pauses, and plays on when back', () async {
      final cubit = h.cubit();
      await cubit.open([a], 0);
      final engine = cubit.state.engine!;

      await cubit.appHidden();
      expect(engine.value.isPlaying, isFalse);
      await cubit.appShown();
      expect(engine.value.isPlaying, isTrue);
      await cubit.close();
    });

    test('listened to as audio, it carries on', () async {
      final cubit = h.cubit();
      await cubit.open([a], 0, audioOnly: true);
      final engine = cubit.state.engine!;

      await cubit.appHidden();
      expect(engine.value.isPlaying, isTrue);
      await cubit.appShown();
      expect(engine.value.isPlaying, isTrue);
      await cubit.close();
    });

    test('paused before hiding: stays paused when back', () async {
      final cubit = h.cubit();
      await cubit.open([a], 0);
      await cubit.pause();

      await cubit.appHidden();
      await cubit.appShown();
      expect(cubit.state.engine!.value.isPlaying, isFalse);
      await cubit.close();
    });

    test('paused meanwhile (lock screen, music): stays paused', () async {
      final cubit = h.cubit();
      await cubit.open([a], 0);
      await cubit.appHidden();
      await cubit.togglePlayPause(); // played from the lock screen…
      await cubit.pause(); // …then paused there
      await cubit.appShown();
      expect(cubit.state.engine!.value.isPlaying, isFalse);

      // Music started while hidden: the video doesn't take over again.
      await cubit.togglePlayPause();
      await cubit.appHidden();
      h.musicPlaying.add(true);
      await pumpEventQueue();
      await cubit.appShown();
      expect(cubit.state.engine!.value.isPlaying, isFalse);
      await cubit.close();
    });

    test('another video opened meanwhile: not touched', () async {
      final cubit = h.cubit();
      await cubit.open([a, b], 0);
      await cubit.appHidden();
      await cubit.next();
      final engine = cubit.state.engine!;
      await engine.pause();

      await cubit.appShown();
      expect(engine.value.isPlaying, isFalse);
      await cubit.close();
    });
  });
}
