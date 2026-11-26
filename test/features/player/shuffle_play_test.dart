import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/player/domain/usecases/play_queue_usecase.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:mocktail/mocktail.dart';

import 'player_fixtures.dart';

void main() {
  setUpAll(registerPlayerFallbacks);

  PlayerCubit cubitFor(PlayerHarness h, {int seed = 1}) => PlayerCubit(
    watchNowPlaying: h.watch,
    playQueue: h.playQueue,
    controls: h.controls,
    restore: h.restore,
    editQueue: h.editQueue,
    random: Random(seed),
  );

  test('plays the songs shuffled, from a random one, in one step', () async {
    final h = PlayerHarness();
    final cubit = cubitFor(h);
    final songs = [for (var i = 1; i <= 20; i++) playerSong(i)];

    await cubit.shufflePlay(songs, title: 'Favourites');

    final params =
        verify(() => h.playQueue(captureAny())).captured.single
            as PlayQueueParams;
    expect(params.songs, songs);
    expect(params.startIndex, Random(1).nextInt(20));
    expect(params.title, 'Favourites');
    expect(params.shuffle, isTrue);
    // The old queue is never reshuffled just to be replaced.
    verifyNever(() => h.controls.setShuffle(any()));
    await cubit.close();
    await h.dispose();
  });

  test('nothing to play: nothing happens', () async {
    final h = PlayerHarness();
    final cubit = cubitFor(h);

    await cubit.shufflePlay(const []);

    verifyNever(() => h.playQueue(any()));
    await cubit.close();
    await h.dispose();
  });
}
