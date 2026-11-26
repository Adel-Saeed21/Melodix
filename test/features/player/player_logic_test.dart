import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/entities/playback_error.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';
import 'package:melodix/features/player/domain/usecases/play_queue_usecase.dart';
import 'package:melodix/features/player/presentation/utils/playback_error_text.dart';
import 'package:melodix/features/player/presentation/utils/playback_time_format.dart';
import 'package:mocktail/mocktail.dart';

import 'player_fixtures.dart';

class MockRepository extends Mock implements PlayerRepository {}

void main() {
  setUpAll(registerPlayerFallbacks);

  group('NowPlaying', () {
    test('idle has no song', () {
      expect(NowPlaying.idle.hasSong, isFalse);
      expect(NowPlaying.idle.currentSong, isNull);
    });

    test('derives the current song', () {
      final state = NowPlaying(
        queue: [playerSong(1), playerSong(2)],
        currentIndex: 1,
      );
      expect(state.currentSong?.id, 2);
    });

    test('an out-of-range index means no song', () {
      final state = NowPlaying(queue: [playerSong(1)], currentIndex: 5);
      expect(state.hasSong, isFalse);
    });
  });

  group('PlaybackProgress', () {
    test('nothing yet: no progress', () {
      expect(PlaybackProgress.zero.fraction, 0);
      expect(PlaybackProgress.zero.remaining, Duration.zero);
    });

    test('derives the remaining time and the fraction', () {
      const progress = PlaybackProgress(
        position: Duration(minutes: 1),
        duration: Duration(minutes: 4),
      );
      expect(progress.remaining, const Duration(minutes: 3));
      expect(progress.fraction, 0.25);
    });

    test('remaining is never negative; fraction stays within 0..1', () {
      const progress = PlaybackProgress(
        position: Duration(minutes: 5),
        duration: Duration(minutes: 4),
      );
      expect(progress.remaining, Duration.zero);
      expect(progress.fraction, 1);
    });
  });

  group('playback errors', () {
    test('every error has words for the user', () {
      for (final error in PlaybackError.values) {
        expect(playbackErrorText(error), isNotEmpty);
      }
      expect(
        playbackErrorText(PlaybackError.cannotPlay),
        "Can't play this song",
      );
    });
  });

  group('time format', () {
    test('pads minutes and seconds', () {
      expect(formatPlaybackTime(const Duration(seconds: 5)), '00:05');
      expect(
        formatPlaybackTime(const Duration(minutes: 1, seconds: 35)),
        '01:35',
      );
      expect(
        formatPlaybackTime(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
      expect(formatPlaybackTime(const Duration(seconds: -3)), '00:00');
    });

    test('elapsed and remaining', () {
      expect(
        formatElapsedAndRemaining(
          const Duration(minutes: 1, seconds: 35),
          const Duration(minutes: 2, seconds: 40),
        ),
        '01:35 / -02:40',
      );
    });
  });

  group('PlayQueueUseCase', () {
    test('ignores an empty list and clamps the start index', () async {
      final repository = MockRepository();
      when(
        () => repository.playQueue(
          any(),
          startIndex: any(named: 'startIndex'),
          title: any(named: 'title'),
        ),
      ).thenAnswer((_) async {});
      final useCase = PlayQueueUseCase(repository);

      await useCase(const PlayQueueParams([]));
      verifyNever(
        () => repository.playQueue(
          any(),
          startIndex: any(named: 'startIndex'),
          title: any(named: 'title'),
        ),
      );

      await useCase(
        PlayQueueParams([playerSong(1), playerSong(2)], startIndex: 9),
      );
      verify(() => repository.playQueue(any(), startIndex: 1, title: null))
          .called(1);
    });
  });

  group('PlayerCubit', () {
    late PlayerHarness harness;

    setUp(() => harness = PlayerHarness());
    tearDown(() => harness.dispose());

    test('mirrors the player state', () async {
      final playing = NowPlaying(
        queue: [playerSong(1)],
        currentIndex: 0,
        isPlaying: true,
      );
      await harness.emit(playing);
      expect(harness.cubit.state, playing);
    });

    test('play/pause follows the current state', () async {
      await harness.cubit.togglePlayPause();
      verify(() => harness.controls.play()).called(1);

      await harness.emit(
        NowPlaying(queue: [playerSong(1)], currentIndex: 0, isPlaying: true),
      );
      await harness.cubit.togglePlayPause();
      verify(() => harness.controls.pause()).called(1);
    });

    test('repeat cycles off → all → one → off', () async {
      Future<PlaybackRepeat> cycleFrom(PlaybackRepeat mode) async {
        await harness.emit(NowPlaying(repeatMode: mode));
        await harness.cubit.cycleRepeat();
        return verify(() => harness.controls.setRepeatMode(captureAny()))
                .captured
                .single
            as PlaybackRepeat;
      }

      expect(await cycleFrom(PlaybackRepeat.off), PlaybackRepeat.all);
      expect(await cycleFrom(PlaybackRepeat.all), PlaybackRepeat.one);
      expect(await cycleFrom(PlaybackRepeat.one), PlaybackRepeat.off);
    });

    test('commands reach the player', () async {
      final songs = [playerSong(1), playerSong(2)];
      await harness.cubit.playSongs(songs, 1, title: 'Road trip');
      final params =
          verify(() => harness.playQueue(captureAny())).captured.single
              as PlayQueueParams;
      expect(params.startIndex, 1);
      expect(params.songs, songs);
      expect(params.title, 'Road trip');

      await harness.cubit.playAt(0);
      verify(() => harness.controls.skipToIndex(0)).called(1);

      await harness.cubit.next();
      await harness.cubit.previous();
      await harness.cubit.seek(const Duration(seconds: 30));
      await harness.cubit.toggleShuffle();
      await harness.cubit.restore();
      verify(() => harness.controls.next()).called(1);
      verify(() => harness.controls.previous()).called(1);
      verify(() => harness.controls.seek(const Duration(seconds: 30)))
          .called(1);
      verify(() => harness.controls.setShuffle(true)).called(1);
      verify(() => harness.restore()).called(1);
    });
  });
}
