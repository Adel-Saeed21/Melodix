import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_song_favorite_usecase.dart';
import 'package:melodix/features/player/data/background/melodix_audio_handler.dart';
import 'package:melodix/features/player/data/background/now_playing_artwork_files.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../player_fixtures.dart';

import 'package:melodix/features/player/domain/entities/playback_progress.dart';

class MockPlayer extends Mock implements PlayerRepository {}

class MockArtworkFiles extends Mock implements NowPlayingArtworkFiles {}

class MockWatchFavorite extends Mock implements WatchSongFavoriteUseCase {}

class MockToggleFavorite extends Mock implements ToggleSongFavoriteUseCase {}

void main() {
  late MockPlayer player;
  late MockArtworkFiles artwork;
  late MockWatchFavorite watchFavorite;
  late MockToggleFavorite toggleFavorite;

  /// Live favourite flag per song id, as storage would report it.
  late Map<int, StreamController<bool>> favorites;
  late StreamController<NowPlaying> states;
  late StreamController<PlaybackProgress> progress;
  late DateTime now;
  late MelodixAudioHandler handler;
  late List<PlaybackState> sent;
  NowPlaying current = NowPlaying.idle;

  final songs = [playerSong(1, title: 'Bad Guy'), playerSong(2)];

  NowPlaying playing({
    int index = 0,
    bool isPlaying = true,
    Duration duration = const Duration(minutes: 3),
  }) => NowPlaying(
    queue: songs,
    currentIndex: index,
    isPlaying: isPlaying,
    duration: duration,
    hasNext: true,
  );

  List<String> icons(PlaybackState state) => [
    for (final control in state.controls) control.androidIcon,
  ];

  /// The player publishes [state].
  /// The player publishes [state], [position] into the song (the
  /// position on its own stream, like the real player).
  Future<void> publish(
    NowPlaying state, {
    Duration position = Duration.zero,
  }) async {
    current = state;
    states.add(state);
    progress.add(
      PlaybackProgress(position: position, duration: state.duration),
    );
    await pumpEventQueue();
  }

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(PlaybackRepeat.off);
    registerFallbackValue(playerSong(0));
  });

  setUp(() {
    player = MockPlayer();
    artwork = MockArtworkFiles();
    states = StreamController<NowPlaying>.broadcast();
    now = DateTime(2026, 11, 24, 12);
    current = NowPlaying.idle;
    when(() => player.watch()).thenAnswer((_) => states.stream);
    progress = StreamController<PlaybackProgress>.broadcast();
    when(() => player.watchProgress()).thenAnswer((_) => progress.stream);
    when(() => player.current).thenAnswer((_) => current);
    for (final call in <Future<void> Function()>[
      player.play,
      player.pause,
      player.next,
      player.previous,
    ]) {
      when(call).thenAnswer((_) async {});
    }
    when(() => player.seek(any())).thenAnswer((_) async {});
    when(() => player.skipToIndex(any())).thenAnswer((_) async {});
    when(() => player.setRepeatMode(any())).thenAnswer((_) async {});
    when(() => player.setShuffle(any())).thenAnswer((_) async {});
    when(() => artwork.uriFor(any())).thenAnswer((_) async => null);

    watchFavorite = MockWatchFavorite();
    toggleFavorite = MockToggleFavorite();
    favorites = {};
    when(() => watchFavorite(any())).thenAnswer(
      (i) =>
          (favorites[i.positionalArguments.single as int] ??=
                  StreamController<bool>.broadcast())
              .stream,
    );

    handler = MelodixAudioHandler(
      player,
      artwork: artwork,
      watchFavorite: watchFavorite,
      toggleFavorite: toggleFavorite,
      clock: () => now,
    );
    sent = [];
    handler.playbackState.skip(1).listen(sent.add); // skip the seed
  });

  tearDown(() async {
    await handler.dispose();
    await progress.close();
    for (final c in favorites.values) {
      await c.close();
    }
    await states.close();
  });

  group('state to the system', () {
    test('a playing song shows as playing, with its details', () async {
      await publish(playing());

      final state = sent.last;
      expect(state.playing, isTrue);
      expect(state.processingState, AudioProcessingState.ready);
      expect(icons(state), [
        'drawable/ic_media_favorite_border',
        'drawable/ic_media_previous',
        'drawable/ic_media_pause',
        'drawable/ic_media_next',
        'drawable/ic_media_shuffle',
      ]);
      expect(state.queueIndex, 0);

      final item = handler.mediaItem.value!;
      expect(item.id, '1');
      expect(item.title, 'Bad Guy');
      expect(item.artist, songs.first.artist);
      expect(item.duration, const Duration(minutes: 3));
    });

    test('paused shows a play button', () async {
      await publish(playing(isPlaying: false));

      expect(sent.last.playing, isFalse);
      expect(icons(sent.last)[2], 'drawable/ic_media_play');
    });

    test('nothing loaded is idle, with no song', () async {
      await publish(NowPlaying.idle);

      expect(sent.last.processingState, AudioProcessingState.idle);
      expect(handler.mediaItem.value, isNull);
    });

    test('repeat and shuffle are mirrored', () async {
      await publish(
        NowPlaying(
          queue: songs,
          currentIndex: 0,
          repeatMode: PlaybackRepeat.one,
          shuffle: true,
        ),
      );

      expect(sent.last.repeatMode, AudioServiceRepeatMode.one);
      expect(sent.last.shuffleMode, AudioServiceShuffleMode.all);
    });

    test('position ticks while playing are not re-sent', () async {
      await publish(playing());
      final before = sent.length;

      // A minute of normal playback, one tick per second.
      for (var s = 1; s <= 60; s++) {
        now = now.add(const Duration(seconds: 1));
        await publish(playing(), position: Duration(seconds: s));
      }

      expect(sent.length, before);
    });

    test('a seek is sent', () async {
      await publish(playing());
      final before = sent.length;

      now = now.add(const Duration(seconds: 1));
      await publish(playing(), position: const Duration(minutes: 2));

      expect(sent.length, before + 1);
      expect(sent.last.updatePosition, const Duration(minutes: 2));
    });

    test('a seek while paused is sent', () async {
      await publish(playing(isPlaying: false));
      final before = sent.length;

      now = now.add(const Duration(seconds: 30)); // time passes, paused
      await publish(playing(isPlaying: false));
      expect(sent.length, before); // still in place: nothing to send

      await publish(
        playing(isPlaying: false),
        position: const Duration(seconds: 40),
      );
      expect(sent.length, before + 1);
    });

    test('the next song updates the details', () async {
      await publish(playing());
      await publish(playing(index: 1));

      expect(sent.last.queueIndex, 1);
      expect(handler.mediaItem.value!.id, '2');
    });
  });

  group('covers', () {
    test('the cover is added once its file is ready', () async {
      final cover = Completer<Uri?>();
      when(() => artwork.uriFor(songs[0])).thenAnswer((_) => cover.future);

      await publish(playing());
      expect(handler.mediaItem.value!.artUri, isNull); // details first

      cover.complete(Uri.file('/cache/1.jpg'));
      await pumpEventQueue();
      expect(handler.mediaItem.value!.artUri, Uri.file('/cache/1.jpg'));
    });

    test('a late cover never lands on the next song', () async {
      final cover = Completer<Uri?>();
      when(() => artwork.uriFor(songs[0])).thenAnswer((_) => cover.future);

      await publish(playing());
      await publish(playing(index: 1));
      cover.complete(Uri.file('/cache/1.jpg'));
      await pumpEventQueue();

      expect(handler.mediaItem.value!.id, '2');
      expect(handler.mediaItem.value!.artUri, isNull);
    });

    test('a corrected duration keeps the cover', () async {
      when(() => artwork.uriFor(songs[0]))
          .thenAnswer((_) async => Uri.file('/cache/1.jpg'));
      await publish(playing(duration: Duration.zero)); // not known yet
      await pumpEventQueue();

      await publish(playing(duration: const Duration(minutes: 3, seconds: 2)));

      final item = handler.mediaItem.value!;
      expect(item.duration, const Duration(minutes: 3, seconds: 2));
      expect(item.artUri, Uri.file('/cache/1.jpg'));
      verify(() => artwork.uriFor(songs[0])).called(1);
    });
  });

  group('what the system shows', () {
    Song tagged(String artist, String album) => Song(
      id: 1,
      title: 'Bad Guy',
      artist: artist,
      album: album,
      albumId: 1,
      duration: const Duration(minutes: 3),
      path: '/m/1.mp3',
      playbackUri: Uri.parse('content://media/external/audio/media/1'),
      isFavorite: false,
      playCount: 0,
    );

    MediaItem item(String artist, String album) =>
        MelodixAudioHandler.mediaItemFor(
          tagged(artist, album),
          duration: const Duration(minutes: 3),
        );

    test('title, then "Artist · Album"', () {
      final shown = item('Billie Eilish', 'When We All Fall Asleep');

      expect(shown.displayTitle, 'Bad Guy');
      expect(shown.displaySubtitle, 'Billie Eilish · When We All Fall Asleep');
      expect(shown.artist, 'Billie Eilish');
      expect(shown.album, 'When We All Fall Asleep');
    });

    test('a missing album is left out', () {
      final shown = item('Billie Eilish', 'Unknown album');

      expect(shown.displaySubtitle, 'Billie Eilish');
      expect(shown.album, isNull);
    });

    test('a missing artist is left out, not reported as a name', () {
      final shown = item('Unknown artist', 'Live');

      expect(shown.displaySubtitle, 'Live');
      expect(shown.artist, isNull);
    });

    test('with nothing known, the subtitle still reads sensibly', () {
      final shown = item('Unknown artist', 'Unknown album');

      expect(shown.displaySubtitle, 'Unknown artist');
    });

    test('collapsed view keeps previous, play/pause and next', () async {
      await publish(playing());

      // Indices count only the standard buttons (♥ / shuffle are custom).
      expect(sent.last.androidCompactActionIndices, [0, 1, 2]);
      final standard = [
        for (final c in sent.last.controls)
          if (c.customAction == null) c.action,
      ];
      expect(standard, [
        MediaAction.skipToPrevious,
        MediaAction.pause,
        MediaAction.skipToNext,
      ]);
    });

    test('no ♥ or shuffle without a song', () async {
      await publish(NowPlaying.idle);

      expect(icons(sent.last), [
        'drawable/ic_media_previous',
        'drawable/ic_media_play',
        'drawable/ic_media_next',
      ]);
    });
  });

  group('♥ favourite', () {
    test('follows changes made anywhere in the app', () async {
      await publish(playing());
      expect(icons(sent.last).first, 'drawable/ic_media_favorite_border');

      favorites[1]!.add(true); // e.g. ♥ tapped in the app
      await pumpEventQueue();
      expect(icons(sent.last).first, 'drawable/ic_media_favorite');
      expect(sent.last.controls.first.label, 'Remove from favourites');

      favorites[1]!.add(false);
      await pumpEventQueue();
      expect(icons(sent.last).first, 'drawable/ic_media_favorite_border');
    });

    test('tapping it toggles the current song at once', () async {
      when(() => toggleFavorite(1)).thenAnswer((_) async => const Right(true));
      await publish(playing());

      await handler.customAction(MelodixAudioHandler.favoriteAction);
      await pumpEventQueue();

      verify(() => toggleFavorite(1)).called(1);
      expect(icons(sent.last).first, 'drawable/ic_media_favorite');
    });

    test('a failed toggle puts the button back', () async {
      when(() => toggleFavorite(1))
          .thenAnswer((_) async => const Left(LibraryFailure('nope')));
      await publish(playing());

      await handler.customAction(MelodixAudioHandler.favoriteAction);
      await pumpEventQueue();

      expect(icons(sent.last).first, 'drawable/ic_media_favorite_border');
    });

    test('the next song shows its own state', () async {
      await publish(playing());
      favorites[1]!.add(true);
      await pumpEventQueue();

      await publish(playing(index: 1));
      expect(icons(sent.last).first, 'drawable/ic_media_favorite_border');

      // A late answer about the previous song changes nothing.
      favorites[1]!.add(false);
      favorites[1]!.add(true);
      await pumpEventQueue();
      expect(icons(sent.last).first, 'drawable/ic_media_favorite_border');
      verify(() => watchFavorite(2)).called(1);
    });
  });

  group('shuffle', () {
    test('tapping it flips shuffle on the player', () async {
      current = playing();
      await handler.customAction(MelodixAudioHandler.shuffleAction);
      verify(() => player.setShuffle(true)).called(1);
    });

    test('the button follows the player\'s shuffle', () async {
      await publish(playing());
      expect(icons(sent.last).last, 'drawable/ic_media_shuffle');

      await publish(
        NowPlaying(
          queue: songs,
          currentIndex: 0,
          isPlaying: true,
          duration: const Duration(minutes: 3),
          shuffle: true,
        ),
      );
      expect(icons(sent.last).last, 'drawable/ic_media_shuffle_on');
      expect(sent.last.controls.last.label, 'Turn shuffle off');
    });
  });

  group('commands from the system', () {
    test('go to the player', () async {
      await handler.play();
      await handler.pause();
      await handler.seek(const Duration(seconds: 42));
      await handler.skipToNext();
      await handler.skipToPrevious();
      await handler.skipToQueueItem(5);

      verify(() => player.play()).called(1);
      verify(() => player.pause()).called(1);
      verify(() => player.seek(const Duration(seconds: 42))).called(1);
      verify(() => player.next()).called(1);
      verify(() => player.previous()).called(1);
      verify(() => player.skipToIndex(5)).called(1);
    });

    test('repeat and shuffle modes map to the player', () async {
      await handler.setRepeatMode(AudioServiceRepeatMode.all);
      await handler.setRepeatMode(AudioServiceRepeatMode.group);
      await handler.setRepeatMode(AudioServiceRepeatMode.one);
      await handler.setRepeatMode(AudioServiceRepeatMode.none);
      await handler.setShuffleMode(AudioServiceShuffleMode.all);
      await handler.setShuffleMode(AudioServiceShuffleMode.none);

      verify(() => player.setRepeatMode(PlaybackRepeat.all)).called(2);
      verify(() => player.setRepeatMode(PlaybackRepeat.one)).called(1);
      verify(() => player.setRepeatMode(PlaybackRepeat.off)).called(1);
      verify(() => player.setShuffle(true)).called(1);
      verify(() => player.setShuffle(false)).called(1);
    });

    test(
      'stop pauses and removes the notification until playing again',
      () async {
        await publish(playing(isPlaying: false));

        await handler.stop();

        await pumpEventQueue();
        verify(() => player.pause()).called(1);
        expect(sent.last.processingState, AudioProcessingState.idle);
        expect(handler.mediaItem.value, isNull);

        // Still paused: stays hidden.
        await publish(playing(isPlaying: false), position: Duration.zero);
        expect(sent.last.processingState, AudioProcessingState.idle);

        // Played from the app: back.
        await publish(playing());
        expect(sent.last.processingState, AudioProcessingState.ready);
        expect(handler.mediaItem.value, isNotNull);
      },
    );

    test('closing the app while playing stops everything', () async {
      await publish(playing());

      await handler.onTaskRemoved();
      await pumpEventQueue();

      // Paused (which saves the song and position)…
      verify(() => player.pause()).called(1);
      // …and idle: the service ends and the notification goes away.
      expect(sent.last.playing, isFalse);
      expect(sent.last.processingState, AudioProcessingState.idle);
      expect(handler.mediaItem.value, isNull);
    });

    test('after closing, playing again in the app brings it back', () async {
      await publish(playing());
      await handler.onTaskRemoved();
      await pumpEventQueue();

      // The player still pauses its last ticks: stays hidden.
      await publish(playing(isPlaying: false));
      expect(sent.last.processingState, AudioProcessingState.idle);

      // Reopened and played.
      await publish(playing());
      expect(sent.last.processingState, AudioProcessingState.ready);
      expect(handler.mediaItem.value, isNotNull);
    });

    test('closing the app while paused ends the session', () async {
      await publish(playing(isPlaying: false));

      await handler.onTaskRemoved();

      await pumpEventQueue();

      expect(sent.last.processingState, AudioProcessingState.idle);
    });
  });
}
