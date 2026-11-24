// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart'
    show LoopModeMessage;
import 'package:melodix/core/database/collections/playback_state_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/database/playback_state_local_storage.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/data/repositories/player_repository_impl.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fake_audio_native.dart';
import '../music_library/fixtures.dart';

class _Music extends Mock implements MusicLocalStorage {}

/// In-memory session storage that records what the player saves.
class _Session implements PlaybackStateLocalStorage {
  SavedPlayback? saved;
  List<int>? queueIds;
  int? savedIndex;
  Duration? savedPosition;

  @override
  Future<SavedPlayback?> loadPlayback() async => saved;

  @override
  Future<void> saveQueue({
    required List<int> queueSongIds,
    required int currentIndex,
    List<int>? originalQueueSongIds,
    PlaybackSource source = PlaybackSource.allSongs,
    int? sourceId,
    Duration position = Duration.zero,
  }) async {
    queueIds = queueSongIds;
    savedIndex = currentIndex;
  }

  @override
  Future<void> savePosition({
    required int currentIndex,
    required Duration position,
  }) async {
    savedIndex = currentIndex;
    savedPosition = position;
  }

  @override
  Future<void> saveSettings({
    bool? shuffle,
    List<int>? queueSongIds,
    int? currentIndex,
    PlayerRepeatMode? repeatMode,
    double? speed,
  }) async {}

  @override
  Future<void> clear() async {}
}

/// Song with id [logical] + 1 (so ids and logical indexes never coincide).
Song _song(int logical) => Song(
  id: logical + 1,
  title: 'Song ${logical + 1}',
  artist: 'Artist',
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 3),
  path: '/m/${logical + 1}.mp3',
  playbackUri: Uri.parse('content://media/external/audio/media/${logical + 1}'),
  isFavorite: false,
  playCount: 0,
);

List<Song> _songs(int count) => List.generate(count, _song);

/// Real AudioPlayer + repository over the simulated native player.
class _Harness {
  _Harness({int seed = 7}) : audio = FakeAudioNative.install() {
    player = AudioPlayer();
    music = _Music();
    when(() => music.recordPlay(any())).thenAnswer((invocation) async {
      plays.add(invocation.positionalArguments.first as int);
    });
    repository = PlayerRepositoryImpl(
      player: player,
      sessionStorage: session,
      musicStorage: music,
      mapper: const SongMapper(isAndroid: true),
      random: Random(seed),
    );
  }

  final FakeAudioNative audio;
  late final AudioPlayer player;
  late final _Music music;
  final session = _Session();
  late final PlayerRepositoryImpl repository;
  final plays = <int>[];

  FakeNativePlayer get native => audio.player!;
  NowPlaying get state => repository.current;
  int? get songId => state.currentSong?.id;

  /// Lets queued operations, player events and stream updates run.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  Future<void> play(List<Song> songs, int index) async {
    await repository.playQueue(songs, startIndex: index, title: 'Songs');
    await settle();
  }

  Future<void> finishSong() async {
    native.finishSong();
    await settle();
  }

  /// What the user sees is what is actually playing; the window is small.
  void expectConsistent() {
    expect(songId, native.currentSongId, reason: 'state vs audio');
    expect(state.queue[state.currentIndex!].id, songId, reason: 'index');
    // At most 3 × behind + current + 2 × ahead (2 and 4 by default).
    expect(native.playlist.length, lessThanOrEqualTo(3 * 2 + 1 + 2 * 4));
    expect(player.audioSources.length, native.playlist.length);
  }

  Future<void> dispose() => player.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Harness h;
  setUp(() => h = _Harness());
  tearDown(() => h.dispose());

  group('starting a queue', () {
    test('1. first, middle and last song of a 10,000-song queue', () async {
      final queue = _songs(10000);
      for (final (index, hasPrevious, hasNext) in [
        (0, false, true),
        (5000, true, true),
        (9999, true, false),
      ]) {
        await h.play(queue, index);

        expect(h.state.currentIndex, index);
        expect(h.songId, index + 1);
        expect(h.state.queue, hasLength(10000));
        expect(h.state.hasPrevious, hasPrevious);
        expect(h.state.hasNext, hasNext);
        expect(h.native.playing, isTrue);
        h.expectConsistent();
      }
    });

    test('14. the first playlist is small whatever the queue size', () async {
      for (final size in [100, 1000, 10000]) {
        // (The native side exists once the first queue is played.)
        final before = size == 100 ? 0 : h.native.sourcesReceived;
        await h.play(_songs(size), size ~/ 2);

        expect(h.native.loadSizes.last, 7, reason: 'size $size');
        expect(h.player.audioSources, hasLength(7));
        expect(h.native.sourcesReceived - before, 7);
      }
    });

    test('regression: tapping in 10,000 songs does not create 10,000 '
        'AudioSources', () async {
      await h.play(_songs(10000), 4321);

      expect(h.player.audioSources.length, lessThanOrEqualTo(7));
      expect(h.native.sourcesReceived, lessThanOrEqualTo(7));
      expect(h.native.loads, 1);
    });

    test('a queue that fits the window is loaded whole', () async {
      await h.play(_songs(5), 3);

      expect(h.native.playlist, hasLength(5));
      expect(h.songId, 4);
    });

    test(
      '13. the first state after a tap already shows the tapped song',
      () async {
        final albumA = [for (var i = 0; i < 10; i++) _song(i)];
        final albumB = [for (var i = 100; i < 110; i++) _song(i)];
        await h.play(albumA, 2);
        final seen = <NowPlaying>[];
        final sub = h.repository.watch().skip(1).listen(seen.add);

        final tap = h.repository.playQueue(albumB, startIndex: 7);
        // Synchronously after the tap, before anything loaded:
        expect(h.state.currentSong?.id, 108);
        expect(h.state.currentIndex, 7);
        await tap;
        await h.settle();
        await sub.cancel();

        expect(seen, isNotEmpty);
        expect({for (final s in seen) s.currentSong?.id}, {108});
        expect(h.songId, 108);
        h.expectConsistent();
      },
    );
  });

  group('navigation', () {
    test('2. next and previous inside the window', () async {
      await h.play(_songs(10000), 5000);

      await h.repository.next();
      await h.settle();
      expect(h.state.currentIndex, 5001);
      h.expectConsistent();

      await h.repository.previous();
      await h.settle();
      expect(h.state.currentIndex, 5000);
      h.expectConsistent();
      expect(h.native.loads, 1, reason: 'no reload between neighbours');
    });

    test('3. next and previous across window boundaries', () async {
      await h.play(_songs(10000), 5000);

      for (var i = 1; i <= 25; i++) {
        await h.repository.next();
        await h.settle();
        expect(h.state.currentIndex, 5000 + i);
        h.expectConsistent();
      }
      for (var i = 24; i >= 0; i--) {
        await h.repository.previous();
        await h.settle();
        expect(h.state.currentIndex, 5000 + i);
        h.expectConsistent();
      }
      expect(h.native.loads, 1, reason: 'the window slid, never reloaded');
    });

    test('previous restarts the song after the first seconds', () async {
      await h.play(_songs(100), 50);
      h.native.advance(const Duration(seconds: 5));
      await h.settle();

      await h.repository.previous();
      await h.settle();

      expect(h.state.currentIndex, 50);
      expect(h.native.position, Duration.zero);
    });

    test(
      'skipping to a queue song: nearby is a seek, far is a reload',
      () async {
        await h.play(_songs(10000), 100);

        await h.repository.skipToIndex(102);
        await h.settle();
        expect(h.state.currentIndex, 102);
        expect(h.native.loads, 1);
        h.expectConsistent();

        await h.repository.skipToIndex(9000);
        await h.settle();
        expect(h.state.currentIndex, 9000);
        expect(h.native.loads, 2);
        expect(h.native.loadSizes.last, 7);
        h.expectConsistent();
      },
    );

    test('4 + 12. songs advance on their own across windows, none skipped '
        'or repeated', () async {
      await h.play(_songs(10000), 0);
      final seen = <int>[h.songId!];

      for (var i = 0; i < 40; i++) {
        await h.finishSong();
        seen.add(h.songId!);
        h.expectConsistent();
      }

      expect(seen, [for (var id = 1; id <= 41; id++) id]);
      expect(h.plays, [for (var id = 1; id <= 41; id++) id]);
      expect(h.native.loads, 1);
      // A handful of small updates, not one per song.
      expect(h.native.playlistUpdates, lessThan(40));
    });

    test('9. rapid next / previous', () async {
      await h.play(_songs(10000), 100);

      await Future.wait([for (var i = 0; i < 15; i++) h.repository.next()]);
      await h.settle();
      expect(h.state.currentIndex, 115);
      h.expectConsistent();

      await Future.wait([for (var i = 0; i < 15; i++) h.repository.previous()]);
      await h.settle();
      expect(h.state.currentIndex, 100);
      h.expectConsistent();
    });
  });

  group('shuffle', () {
    test(
      '5. covers the entire queue, each song once, from the current one',
      () async {
        await h.play(_songs(60), 10);
        await h.repository.setShuffle(true);
        await h.settle();
        expect(h.songId, 11, reason: 'the current song keeps playing');

        final order = <int>[h.songId!];
        while (h.state.hasNext) {
          await h.repository.next();
          await h.settle();
          h.expectConsistent();
          order.add(h.songId!);
        }

        expect(order, hasLength(60));
        expect(order.toSet(), {for (var id = 1; id <= 60; id++) id});
        expect(order, isNot([for (var id = 1; id <= 60; id++) id]));
        expect(h.state.shuffle, isTrue);
      },
    );

    test('the shuffled order is stable when moving back and forth', () async {
      await h.play(_songs(1000), 500);
      await h.repository.setShuffle(true);
      await h.settle();
      final forward = <int>[h.songId!];
      for (var i = 0; i < 20; i++) {
        await h.repository.next();
        await h.settle();
        forward.add(h.songId!);
      }
      final backward = <int>[h.songId!];
      for (var i = 0; i < 20; i++) {
        await h.repository.previous();
        await h.settle();
        backward.add(h.songId!);
      }

      expect(backward, forward.reversed.toList());
      h.expectConsistent();
    });

    test('shuffle spans the whole 10,000-song queue, not the window', () async {
      await h.play(_songs(10000), 5000);
      await h.repository.setShuffle(true);
      await h.settle();
      final ids = <int>{h.songId!};
      for (var i = 0; i < 20; i++) {
        await h.repository.next();
        await h.settle();
        ids.add(h.songId!);
        h.expectConsistent();
      }

      expect(ids, hasLength(21));
      expect(ids.where((id) => (id - 5001).abs() > 1000), isNotEmpty);
      expect(h.native.loads, 1);
    });

    test('switching shuffle off continues in queue order', () async {
      await h.play(_songs(1000), 500);
      await h.repository.setShuffle(true);
      for (var i = 0; i < 5; i++) {
        await h.repository.next();
      }
      await h.settle();
      final here = h.state.currentIndex!;

      await h.repository.setShuffle(false);
      await h.settle();
      expect(h.state.currentIndex, here);
      await h.repository.next();
      await h.settle();

      expect(h.state.currentIndex, here + 1);
      h.expectConsistent();
    });

    test('a new queue with shuffle on starts at the tapped song', () async {
      await h.play(_songs(10), 0);
      await h.repository.setShuffle(true);

      await h.play(_songs(1000), 321);

      expect(h.state.currentIndex, 321);
      expect(h.state.hasPrevious, isFalse);
      h.expectConsistent();
    });
  });

  group('repeat', () {
    test('6. repeat one replays the song; next restarts it', () async {
      await h.play(_songs(10000), 40);
      await h.repository.setRepeatMode(PlaybackRepeat.one);
      await h.settle();
      expect(h.native.loopMode, LoopModeMessage.one);

      await h.finishSong();
      expect(h.state.currentIndex, 40);

      h.native.advance(const Duration(seconds: 30));
      await h.repository.next();
      await h.settle();
      expect(h.state.currentIndex, 40);
      expect(h.native.position, Duration.zero);
      expect(h.state.hasNext, isTrue);
      expect(h.state.hasPrevious, isTrue);
    });

    test('7. repeat all goes from the last song to the first', () async {
      await h.play(_songs(10000), 9998);
      await h.repository.setRepeatMode(PlaybackRepeat.all);
      await h.settle();

      await h.finishSong(); // 9998 → 9999
      await h.finishSong(); // 9999 → 0
      expect(h.state.currentIndex, 0);
      h.expectConsistent();
      await h.repository.next();
      await h.settle();
      expect(h.state.currentIndex, 1);

      await h.repository.previous();
      await h.repository.previous();
      await h.settle();
      expect(h.state.currentIndex, 9999, reason: 'previous wraps too');
      h.expectConsistent();
      expect(h.state.hasNext, isTrue);
      expect(h.native.loads, 1);
    });

    test('repeat all on a queue that fits the window', () async {
      await h.play(_songs(5), 4);
      await h.repository.setRepeatMode(PlaybackRepeat.all);
      await h.settle();

      await h.finishSong();

      expect(h.state.currentIndex, 0);
      expect(h.native.loopMode, LoopModeMessage.all);
      h.expectConsistent();
    });

    test('repeat off: the queue ends, and play starts it over', () async {
      await h.play(_songs(10000), 9999);

      await h.finishSong();
      expect(h.state.isCompleted, isTrue);
      expect(h.state.hasNext, isFalse);

      await h.repository.play();
      await h.settle();
      expect(h.state.currentIndex, 0);
      expect(h.state.isCompleted, isFalse);
      h.expectConsistent();
    });

    test('turning repeat all off after wrapping around', () async {
      await h.play(_songs(10000), 9999);
      await h.repository.setRepeatMode(PlaybackRepeat.all);
      await h.settle();
      await h.finishSong(); // wrapped to the first song

      await h.repository.setRepeatMode(PlaybackRepeat.off);
      await h.settle();

      expect(h.state.currentIndex, 0);
      expect(h.state.hasPrevious, isFalse);
      await h.repository.next();
      await h.settle();
      expect(h.state.currentIndex, 1);
      h.expectConsistent();
    });
  });

  group('8. restoring a session', () {
    SavedPlayback saved(
      List<SongCollection> rows,
      int index,
      Duration position, {
      bool shuffle = false,
    }) => SavedPlayback(
      queue: rows,
      originalQueue: const [],
      currentIndex: index,
      position: position,
      shuffle: shuffle,
      repeatMode: PlayerRepeatMode.off,
      speed: 1,
      source: PlaybackSource.allSongs,
      sourceId: null,
    );

    test('shows the last song from the start, never the first', () async {
      h.session.saved = saved(
        [songRow(1, title: 'First'), songRow(2), songRow(3, title: 'Last')],
        2,
        const Duration(seconds: 42),
      );
      final seen = <NowPlaying>[];
      final sub = h.repository.watch().listen(seen.add);

      await h.repository.restoreLastSession();
      await h.settle();
      await sub.cancel();

      final withSong = seen.where((s) => s.hasSong).toList();
      expect(withSong, isNotEmpty);
      expect(withSong.map((s) => s.currentSong!.title).toSet(), {'Last'});
      expect(withSong.first.position, const Duration(seconds: 42));
      expect(h.state.currentSong?.title, 'Last');
      expect(h.state.position, const Duration(seconds: 42));
      expect(h.native.playing, isFalse, reason: 'restoring never plays');
    });

    test('restores the logical index in a 10,000-song queue', () async {
      h.session.saved = saved(
        [for (var i = 1; i <= 10000; i++) songRow(i)],
        7777,
        const Duration(seconds: 42),
      );

      await h.repository.restoreLastSession();
      await h.settle();

      expect(h.state.currentIndex, 7777);
      expect(h.songId, 7778);
      expect(h.native.currentSongId, 7778);
      expect(h.native.position, const Duration(seconds: 42));
      expect(h.native.loadSizes.single, 7);
      expect(h.native.playing, isFalse);

      await h.repository.play();
      await h.repository.next();
      await h.settle();
      expect(h.state.currentIndex, 7778);
      h.expectConsistent();
    });

    test('the saved position is the logical index', () async {
      await h.play(_songs(10000), 3000);
      for (var i = 0; i < 10; i++) {
        await h.repository.next();
      }
      await h.repository.pause();
      await h.settle();

      expect(h.session.savedIndex, 3010);
    });
  });

  group('races', () {
    test('10. a second tap while the first queue is still loading', () async {
      await h.play(_songs(10), 0);
      final hold = h.native.holdLoad = Completer<void>();
      final queueA = _songs(10000);
      final queueB = [for (var i = 500; i < 600; i++) _song(i)];
      final seen = <NowPlaying>[];

      final tapA = h.repository.playQueue(queueA, startIndex: 5);
      final sub = h.repository.watch().skip(1).listen(seen.add);
      final tapB = h.repository.playQueue(queueB, startIndex: 9);
      final afterB = seen.length;
      hold.complete();
      await Future.wait([tapA, tapB]);
      await h.settle();
      await sub.cancel();

      expect(h.songId, 510);
      expect(h.state.currentIndex, 9);
      expect(
        {for (final s in seen.skip(afterB)) s.currentSong?.id},
        {510},
        reason: 'after the second tap only its song is shown',
      );
      expect(h.native.currentSongId, 510);
      expect(h.session.savedIndex, 9);
      h.expectConsistent();
    });

    test('9b. rapid next while a window update is still in flight', () async {
      await h.play(_songs(10000), 100);
      final hold = h.native.holdUpdate = Completer<void>();

      final moves = Future.wait([
        for (var i = 0; i < 10; i++) h.repository.next(),
      ]);
      await h.settle();
      hold.complete();
      await moves;
      await h.settle();

      expect(h.state.currentIndex, 110);
      expect(h.native.loads, 1, reason: 'waited for the window, no reload');
      h.expectConsistent();
    });

    test('11. seeking while the window is being updated', () async {
      await h.play(_songs(10000), 100);
      // Three nexts leave one song ahead: the window grows (held open).
      final hold = h.native.holdUpdate = Completer<void>();
      final moves = Future.wait([
        for (var i = 0; i < 3; i++) h.repository.next(),
      ]);
      await h.settle();

      await h.repository.seek(const Duration(seconds: 90));
      hold.complete();
      await moves;
      await h.settle();

      expect(h.state.currentIndex, 103);
      expect(h.native.position, const Duration(seconds: 90));
      // The player extrapolates while playing: 90 s plus a few ms.
      expect(
        h.state.position - const Duration(seconds: 90),
        lessThan(const Duration(milliseconds: 200)),
      );
      expect(
        h.state.position,
        greaterThanOrEqualTo(const Duration(seconds: 90)),
      );
      h.expectConsistent();
    });
  });
}
