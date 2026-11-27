import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/player/data/session/listening_tracker.dart';
import 'package:melodix/features/player/domain/repositories/play_recorder.dart';

class _Recorder implements PlayRecorder {
  final plays = <int>[];
  final listened = <int, Duration>{};
  var failWrites = false;

  @override
  Future<void> recordPlay(int songId) async {
    if (failWrites) throw StateError('disk full');
    plays.add(songId);
  }

  @override
  Future<void> addListening(int songId, Duration heard) async {
    if (failWrites) throw StateError('disk full');
    listened[songId] = (listened[songId] ?? Duration.zero) + heard;
  }
}

const _song = Duration(minutes: 3);
Duration _s(int seconds) => Duration(seconds: seconds);

void main() {
  late _Recorder recorder;
  late ListeningTracker tracker;

  setUp(() {
    recorder = _Recorder();
    tracker = ListeningTracker(recorder)..newQueue();
  });

  /// Song [id] plays from [from] to [to], one update per second.
  void play(int id, int from, int to, {Duration length = _song}) {
    for (var t = from; t <= to; t++) {
      tracker.update(
        songId: id,
        length: length,
        position: _s(t),
        listening: true,
      );
    }
  }

  /// The player stops (pause, end, buffering) at [at].
  void stop(int id, int at, {Duration length = _song}) => tracker.update(
    songId: id,
    length: length,
    position: _s(at),
    listening: false,
  );

  group('thresholds', () {
    test('30 s for normal songs, half for songs under a minute', () {
      expect(ListeningTracker.thresholdFor(_song), _s(30));
      expect(ListeningTracker.thresholdFor(_s(60)), _s(30));
      expect(ListeningTracker.thresholdFor(_s(40)), _s(20));
      expect(ListeningTracker.thresholdFor(_s(10)), _s(5));
      // Unknown length: the normal rule.
      expect(ListeningTracker.thresholdFor(Duration.zero), _s(30));
    });

    test('29 s is no play; 30 s is', () async {
      play(1, 0, 29);
      stop(1, 29);
      await pumpEventQueue();
      expect(recorder.plays, isEmpty);
      expect(recorder.listened[1], _s(29));

      play(1, 29, 30);
      await pumpEventQueue();
      expect(recorder.plays, [1]);
    });

    test('a short song counts after half of it', () async {
      play(5, 0, 19, length: _s(40));
      await pumpEventQueue();
      expect(recorder.plays, isEmpty);
      play(5, 19, 20, length: _s(40));
      await pumpEventQueue();
      expect(recorder.plays, [5]);
    });
  });

  test('paused and buffering time is not heard', () async {
    play(1, 0, 20);
    stop(1, 20); // pause
    stop(1, 20); // still paused (updates while paused)
    play(1, 20, 25); // resumed
    stop(1, 25); // buffering
    play(1, 25, 40);
    stop(1, 40);
    await pumpEventQueue();

    expect(recorder.listened[1], _s(40));
    expect(recorder.plays, [1]);
  });

  test('a seek is not heard, forward or back', () async {
    play(1, 0, 10);
    tracker.seeked();
    play(1, 150, 155); // jumped ahead
    tracker.seeked();
    play(1, 0, 5); // and back to the start: not a new listen
    stop(1, 5);
    await pumpEventQueue();

    expect(recorder.listened[1], _s(20));
    expect(recorder.plays, isEmpty);
  });

  group('loops', () {
    test('the song starting over by itself is a new listen', () async {
      play(1, 0, 180);
      play(1, 0, 31); // repeat one: back to 0 with no seek
      await pumpEventQueue();
      expect(recorder.plays, [1, 1]);
    });

    test('a restart (Next on repeat one) is a new listen', () async {
      play(1, 0, 40);
      tracker.restarted();
      play(1, 0, 30);
      await pumpEventQueue();
      expect(recorder.plays, [1, 1]);
    });

    test('a loop skipped early counts nothing more', () async {
      play(1, 0, 180);
      play(1, 0, 10);
      stop(1, 10);
      await pumpEventQueue();
      expect(recorder.plays, [1]);
      expect(recorder.listened[1], _s(190));
    });
  });

  group('song and queue changes', () {
    test('each song is its own listen; time goes to the right song', () async {
      play(1, 0, 40);
      play(2, 0, 10); // next song (auto-advance or skip)
      play(3, 0, 35);
      stop(3, 35);
      await pumpEventQueue();

      expect(recorder.plays, [1, 3]);
      expect(recorder.listened, {1: _s(40), 2: _s(10), 3: _s(35)});
    });

    test('the same song in a new queue is a new listen', () async {
      play(1, 0, 35);
      tracker.newQueue();
      play(1, 0, 35);
      await pumpEventQueue();
      expect(recorder.plays, [1, 1]);
    });

    test('while the player is busy, nothing is compared across it', () async {
      play(1, 0, 10);
      tracker.interrupted(); // loading the next song…
      play(1, 100, 105); // (stale position reports, then settled)
      stop(1, 105);
      await pumpEventQueue();
      expect(recorder.listened[1], _s(15));
    });
  });

  group('saving', () {
    test('saved every 10 s while playing, not only when it stops', () async {
      play(1, 0, 25);
      await pumpEventQueue();
      // Never paused: two batches saved, at most one batch outstanding.
      expect(recorder.listened[1], _s(20));

      stop(1, 25);
      await pumpEventQueue();
      expect(recorder.listened[1], _s(25), reason: 'the rest on stopping');
    });

    test('nothing is saved twice', () async {
      play(1, 0, 12);
      stop(1, 12);
      stop(1, 12);
      tracker
        ..interrupted()
        ..flush()
        ..newQueue();
      await pumpEventQueue();
      expect(recorder.listened[1], _s(12));
    });

    test('rare updates (screen off) still count in full', () async {
      tracker.update(
        songId: 1,
        length: _song,
        position: _s(0),
        listening: true,
      );
      tracker.update(
        songId: 1,
        length: _song,
        position: _s(90),
        listening: true,
      );
      await pumpEventQueue();
      expect(recorder.plays, [1]);
      expect(recorder.listened[1], _s(90));
    });

    test('a failed write never breaks playback tracking', () async {
      recorder.failWrites = true;
      play(1, 0, 35);
      stop(1, 35);
      await pumpEventQueue();
      recorder.failWrites = false;
      play(2, 0, 31);
      await pumpEventQueue();
      expect(recorder.plays, [2]);
    });
  });

  group('restored session', () {
    test('a song restored past the threshold is not counted again', () async {
      tracker
        ..newQueue()
        ..resume(songId: 1, length: _song, position: _s(42));
      play(1, 42, 100);
      stop(1, 100);
      await pumpEventQueue();
      expect(recorder.plays, isEmpty);
      expect(recorder.listened[1], _s(58), reason: 'only the new listening');
    });

    test('a song restored early finishes its listen', () async {
      tracker
        ..newQueue()
        ..resume(songId: 1, length: _song, position: _s(20));
      play(1, 20, 29);
      await pumpEventQueue();
      expect(recorder.plays, isEmpty);
      play(1, 29, 30);
      await pumpEventQueue();
      expect(recorder.plays, [1]);
    });
  });
}
