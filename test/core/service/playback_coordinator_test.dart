import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/service/playback_coordinator.dart';

void main() {
  test('a video starting pauses the music', () async {
    var pauses = 0;
    final coordinator = PlaybackCoordinator(
      pauseMusic: () async => pauses++,
      musicPlaying: const Stream.empty(),
    );
    await coordinator.videoStarting();
    expect(pauses, 1);
  });

  test('announces music starting once per start, not per update', () async {
    final playing = StreamController<bool>();
    final coordinator = PlaybackCoordinator(
      pauseMusic: () async {},
      musicPlaying: playing.stream,
    );
    var starts = 0;
    final sub = coordinator.musicStarted.listen((_) => starts++);

    // Now-playing updates repeat "playing" many times (position, etc.).
    for (final p in [false, true, true, true, false, false, true]) {
      playing.add(p);
    }
    await pumpEventQueue();
    await sub.cancel();
    await playing.close();
    expect(starts, 2);
  });
}
