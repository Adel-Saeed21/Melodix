import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melodix/core/database/collections/playback_state_collection.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/database/playback_state_local_storage.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/player/data/repositories/player_repository_impl.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:mocktail/mocktail.dart';

import '../music_library/fixtures.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockSessionStorage extends Mock implements PlaybackStateLocalStorage {}

class MockMusicStorage extends Mock implements MusicLocalStorage {}

/// A fake player that, like the real one, reports the first song (index 0,
/// 0:00) while a queue loads, and the requested song once it's loaded.
class FakePlayer {
  FakePlayer() {
    when(() => player.playerStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => player.positionStream).thenAnswer((_) => const Stream.empty());
    when(() => player.durationStream).thenAnswer((_) => const Stream.empty());
    when(() => player.sequenceStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => player.currentIndexStream).thenAnswer((_) => index.stream);
    when(() => player.loopModeStream).thenAnswer((_) => loop.stream);
    when(() => player.shuffleModeEnabledStream)
        .thenAnswer((_) => shuffle.stream);
    when(() => player.currentIndex).thenAnswer((_) => currentIndex);
    when(() => player.position).thenAnswer((_) => position);
    when(() => player.duration).thenAnswer((_) => null);
    when(() => player.playing).thenReturn(false);
    when(() => player.processingState).thenAnswer((_) => ProcessingState.idle);
    when(() => player.loopMode).thenReturn(LoopMode.off);
    when(() => player.shuffleModeEnabled).thenReturn(false);
    when(() => player.hasNext).thenReturn(false);
    when(() => player.hasPrevious).thenReturn(false);
    when(() => player.setLoopMode(any())).thenAnswer((_) async {
      loop.add(LoopMode.off); // triggers an update mid-restore
    });
    when(() => player.setShuffleModeEnabled(any())).thenAnswer((_) async {
      shuffle.add(false);
    });
    when(
      () => player.setAudioSources(
        any(),
        initialIndex: any(named: 'initialIndex'),
        initialPosition: any(named: 'initialPosition'),
      ),
    ).thenAnswer((invocation) async {
      // While loading: the player still sits on the first song.
      currentIndex = 0;
      position = Duration.zero;
      index.add(0);
      await Future<void>.delayed(Duration.zero);
      // Loaded at the requested song and position.
      currentIndex = invocation.namedArguments[#initialIndex] as int;
      position = invocation.namedArguments[#initialPosition] as Duration;
      index.add(currentIndex);
      return null;
    });
  }

  final player = MockAudioPlayer();
  final index = StreamController<int?>.broadcast();
  final loop = StreamController<LoopMode>.broadcast();
  final shuffle = StreamController<bool>.broadcast();
  int? currentIndex;
  Duration position = Duration.zero;
}

void main() {
  setUpAll(() {
    registerFallbackValue(LoopMode.off);
    registerFallbackValue(<AudioSource>[]);
    registerFallbackValue(Duration.zero);
  });

  test(
    'restoring shows the last song from the start, never the first',
    () async {
      final fake = FakePlayer();
      final session = MockSessionStorage();
      when(
        () => session.savePosition(
          currentIndex: any(named: 'currentIndex'),
          position: any(named: 'position'),
        ),
      ).thenAnswer((_) async {});
      when(() => session.loadPlayback()).thenAnswer(
        (_) async => SavedPlayback(
          queue: [
            songRow(1, title: 'First'),
            songRow(2),
            songRow(3, title: 'Last'),
          ],
          originalQueue: const [],
          currentIndex: 2,
          position: const Duration(seconds: 42),
          shuffle: false,
          repeatMode: PlayerRepeatMode.off,
          speed: 1,
          source: PlaybackSource.allSongs,
          sourceId: null,
        ),
      );
      final repository = PlayerRepositoryImpl(
        player: fake.player,
        sessionStorage: session,
        musicStorage: MockMusicStorage(),
        mapper: const SongMapper(isAndroid: true),
      );

      final seen = <NowPlaying>[];
      final sub = repository.watch().listen(seen.add);

      await repository.restoreLastSession();
      await Future<void>.delayed(Duration.zero);

      final withSong = seen.where((s) => s.hasSong).toList();
      expect(withSong, isNotEmpty);
      // Every state that shows a song shows the saved one.
      expect(withSong.map((s) => s.currentSong!.title).toSet(), {'Last'});
      // The very first visible state already has the saved position.
      expect(withSong.first.position, const Duration(seconds: 42));
      expect(repository.current.currentSong?.title, 'Last');
      expect(repository.current.position, const Duration(seconds: 42));
      // Restoring never starts playback by itself.
      verifyNever(() => fake.player.play());

      await sub.cancel();
    },
  );
}
