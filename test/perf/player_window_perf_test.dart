// ignore_for_file: avoid_print
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melodix/core/database/collections/playback_state_collection.dart';
import 'package:melodix/core/database/playback_state_local_storage.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/data/repositories/player_repository_impl.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';

import '../support/fake_audio_native.dart';

import 'package:melodix/features/player/domain/repositories/play_recorder.dart';

class _Music extends Fake implements PlayRecorder {
  @override
  Future<void> recordPlay(int songId) async {}
}

/// Accepts every save; nothing to restore.
class _Session extends Fake implements PlaybackStateLocalStorage {
  @override
  Future<void> saveQueue({
    required List<int> queueSongIds,
    required int currentIndex,
    List<int>? originalQueueSongIds,
    PlaybackSource source = PlaybackSource.allSongs,
    int? sourceId,
    Duration position = Duration.zero,
  }) async {}

  @override
  Future<void> savePosition({
    required int currentIndex,
    required Duration position,
  }) async {}

  @override
  Future<void> saveSettings({
    bool? shuffle,
    List<int>? queueSongIds,
    int? currentIndex,
    PlayerRepeatMode? repeatMode,
    double? speed,
  }) async {}
}

final _clock = Stopwatch()..start();
double _now() => _clock.elapsedMicroseconds / 1000;

Song _song(int i) => Song(
  id: i + 1,
  title: 'Song ${i + 1}',
  artist: 'Artist',
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 3),
  path: '/m/${i + 1}.mp3',
  playbackUri: Uri.parse('content://media/external/audio/media/${i + 1}'),
  isFavorite: false,
  playCount: 0,
);

/// Longest gap between 1 ms timer ticks: the longest the main isolate was
/// blocked (> 16 ms means dropped frames).
class _Stalls {
  Timer? _timer;
  double _last = 0;
  double max = 0;
  void start() {
    _last = _now();
    _timer = Timer.periodic(const Duration(milliseconds: 1), (_) => _tick());
  }

  void _tick() {
    final t = _now();
    if (t - _last > max) max = t - _last;
    _last = t;
  }

  void stop() {
    _tick();
    _timer?.cancel();
  }
}

double _median(List<double> v) => (List.of(v)..sort())[v.length ~/ 2];
String _f(double v) => v.toStringAsFixed(1);

/// Tap-to-play cost through the real AudioPlayer and repository, over the
/// simulated native side (native prepare time is not included).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [12, 1000, 10000]) {
    test('tap → play with a queue of $size songs', () async {
      final audio = FakeAudioNative.install();
      final player = AudioPlayer();
      final music = _Music();
      final session = _Session();
      final repo = PlayerRepositoryImpl(
        player: player,
        sessionStorage: session,
        playRecorder: music,
        mapper: const SongMapper(isAndroid: true),
      );
      final songs = List.generate(size, _song);

      final rows = <String, List<double>>{};
      void add(String k, double v) => (rows[k] ??= []).add(v);
      for (var run = 0; run <= 5; run++) {
        final index = (run * 7919 + 3) % size;
        final id = index + 1;
        double? shownAt, playAt;
        final sub = repo.watch().listen((NowPlaying s) {
          if (shownAt == null && s.currentSong?.id == id) shownAt = _now();
        });
        // Paused, so play() really reaches the native side.
        await player.pause();
        final sentBefore = audio.player?.sourcesReceived ?? 0;
        audio.player?.onPlay = () => playAt ??= _now();
        final stalls = _Stalls()..start();

        final t0 = _now();
        final tap = repo.playQueue(songs, startIndex: index, title: 'Songs');
        if (repo.current.currentSong?.id == id) shownAt ??= _now();
        audio.player?.onPlay ??= () => playAt ??= _now();
        await tap;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        stalls.stop();
        await sub.cancel();
        audio.player!.onPlay = null;
        if (run == 0) continue; // warm-up (first tap configures the session)

        final native = audio.player!;
        add('tapped song in PlayerState (ms)', shownAt! - t0);
        add('play requested at native (ms)', (playAt ?? double.nan) - t0);
        add(
          'AudioSources sent to just_audio',
          native.sourcesReceived - sentBefore.toDouble(),
        );
        add('longest main-isolate stall (ms)', stalls.max);
      }

      // Normal playback: 100 songs play to the end one after another.
      final native = audio.player!;
      await repo.playQueue(songs, startIndex: 0);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final loadsBefore = native.loads, updatesBefore = native.playlistUpdates;
      final steps = size < 100 ? size - 1 : 100;
      for (var i = 0; i < steps; i++) {
        native.finishSong();
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(repo.current.currentSong?.id, steps + 1);
      add(
        'reloads during $steps auto-advances',
        (native.loads - loadsBefore).toDouble(),
      );
      add(
        'playlist updates during $steps auto-advances',
        (native.playlistUpdates - updatesBefore).toDouble(),
      );

      // Creating that many AudioSources, measured on its own.
      final count = rows['AudioSources sent to just_audio']!.first.toInt();
      final sw = Stopwatch()..start();
      for (var r = 0; r < 5; r++) {
        [
          for (var i = 0; i < count; i++)
            AudioSource.uri(songs[i].playbackUri, tag: i),
        ];
      }
      add('creating those AudioSources (ms)', sw.elapsedMicroseconds / 5000);

      print('PLAYER queue=$size (median of 5 taps)');
      for (final e in rows.entries) {
        print('  ${e.key.padRight(44)} ${_f(_median(e.value))}');
      }
      await player.dispose();
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}
