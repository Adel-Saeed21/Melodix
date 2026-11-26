import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/service/media_session_guest.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/playback/video_media_session.dart';

import '../video_fixtures.dart';

void main() {
  late VideoPlayerHarness h;
  late VideoPlayerCubit cubit;
  late StreamController<void> musicStarted;
  late VideoMediaSession media;
  var step = const Duration(seconds: 10);

  setUpAll(registerVideoFallbacks);

  setUp(() {
    h = VideoPlayerHarness();
    cubit = h.cubit();
    musicStarted = StreamController<void>.broadcast(sync: true);
    step = const Duration(seconds: 10);
    media = VideoMediaSession(
      session: cubit,
      musicStarted: musicStarted.stream,
      seekStep: () => step,
      thumbnail: (_) async => null,
    );
  });

  tearDown(() async {
    await media.dispose();
    await cubit.close();
    await musicStarted.close();
  });

  test('takes the controls when a video plays', () async {
    expect(media.current, isNull);
    await cubit.open([testVideo('a'), testVideo('b')], 0);

    final GuestMedia now = media.current!;
    expect(now.id, 'video:a');
    expect(now.title, 'Video a');
    expect(now.playing, isTrue);
    expect(now.hasNext, isTrue);
  });

  test('keeps them while paused; hands them back on close', () async {
    await cubit.open([testVideo('a')], 0);
    await cubit.pause();
    expect(media.current?.playing, isFalse);

    await cubit.stop();
    await pumpEventQueue();
    expect(media.current, isNull);
  });

  test('music starting takes them back', () async {
    await cubit.open([testVideo('a')], 0);
    await cubit.pause(); // as music starting does
    musicStarted.add(null);
    expect(media.current, isNull);

    // The video playing again takes them again.
    await cubit.togglePlayPause();
    await pumpEventQueue();
    expect(media.current?.playing, isTrue);
  });

  test('jumps use the skip length from Settings', () async {
    await cubit.open([testVideo('a')], 0);
    final engine = h.engines['a']!..advanceTo(const Duration(seconds: 60));

    await media.fastForward();
    expect(engine.value.position, const Duration(seconds: 70));
    step = const Duration(seconds: 5);
    await media.rewind();
    expect(engine.value.position, const Duration(seconds: 65));
  });

  test('next: the next video, or a jump when it is the last', () async {
    await cubit.open([testVideo('a'), testVideo('b')], 0);
    await media.next();
    expect(cubit.state.video.id, 'b');

    h.engines['b']!.advanceTo(const Duration(seconds: 20));
    await media.next();
    expect(cubit.state.video.id, 'b');
    expect(h.engines['b']!.value.position, const Duration(seconds: 30));
  });

  test('play and pause', () async {
    await cubit.open([testVideo('a')], 0);
    await media.pause();
    expect(h.engines['a']!.value.isPlaying, isFalse);
    await media.play();
    expect(h.engines['a']!.value.isPlaying, isTrue);
    await media.play(); // already playing: stays playing
    expect(h.engines['a']!.value.isPlaying, isTrue);
  });
}
