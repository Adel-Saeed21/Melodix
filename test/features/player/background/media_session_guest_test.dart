import 'dart:async';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/service/media_session_guest.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_song_favorite_usecase.dart';
import 'package:melodix/features/player/data/background/melodix_audio_handler.dart';
import 'package:melodix/features/player/data/background/now_playing_artwork_files.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../player_fixtures.dart';

class MockPlayer extends Mock implements PlayerRepository {}

class MockArtworkFiles extends Mock implements NowPlayingArtworkFiles {}

class MockWatchFavorite extends Mock implements WatchSongFavoriteUseCase {}

class MockToggleFavorite extends Mock implements ToggleSongFavoriteUseCase {}

/// A video standing in as the guest; records the commands it gets.
class FakeGuest implements MediaSessionGuest {
  final _changes = StreamController<GuestMedia?>.broadcast(sync: true);
  final commands = <String>[];

  @override
  GuestMedia? current;

  void own(GuestMedia? media) {
    current = media;
    _changes.add(media);
  }

  @override
  Stream<GuestMedia?> get changes => _changes.stream;

  @override
  Future<Uint8List?> artwork(String id) async => null;

  @override
  Future<void> play() async => commands.add('play');
  @override
  Future<void> pause() async => commands.add('pause');
  @override
  Future<void> seek(Duration position) async =>
      commands.add('seek ${position.inSeconds}');
  @override
  Future<void> rewind() async => commands.add('rewind');
  @override
  Future<void> fastForward() async => commands.add('forward');
  @override
  Future<void> next() async => commands.add('next');
  @override
  Future<void> previous() async => commands.add('previous');
}

void main() {
  late MockPlayer player;
  late MockArtworkFiles artwork;
  late FakeGuest guest;
  late StreamController<NowPlaying> states;
  late StreamController<PlaybackProgress> progress;
  late MelodixAudioHandler handler;
  late List<PlaybackState> sent;
  late DateTime now;
  var current = NowPlaying.idle;

  final song = playerSong(1, title: 'Bad Guy');
  final music = NowPlaying(
    queue: [song],
    currentIndex: 0,
    isPlaying: false,
    duration: const Duration(minutes: 3),
  );

  GuestMedia video({
    bool playing = true,
    Duration position = Duration.zero,
    String id = 'video:a',
  }) => GuestMedia(
    id: id,
    title: 'Holiday',
    subtitle: 'Video · Melodix',
    duration: const Duration(minutes: 10),
    position: position,
    playing: playing,
  );

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(playerSong(0));
  });

  setUp(() async {
    player = MockPlayer();
    artwork = MockArtworkFiles();
    guest = FakeGuest();
    states = StreamController<NowPlaying>.broadcast();
    progress = StreamController<PlaybackProgress>.broadcast();
    now = DateTime(2026, 11, 25, 12);
    current = music;
    when(() => player.watch()).thenAnswer((_) => states.stream);
    when(() => player.watchProgress()).thenAnswer((_) => progress.stream);
    when(() => player.current).thenAnswer((_) => current);
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.pause()).thenAnswer((_) async {});
    when(() => player.next()).thenAnswer((_) async {});
    when(() => player.previous()).thenAnswer((_) async {});
    when(() => artwork.uriFor(any())).thenAnswer((_) async => null);
    when(() => artwork.uriForKey(any(), any()))
        .thenAnswer((_) async => Uri.parse('file:///thumb.jpg'));
    final watchFavorite = MockWatchFavorite();
    when(() => watchFavorite(any())).thenAnswer((_) => const Stream.empty());

    handler = MelodixAudioHandler(
      player,
      artwork: artwork,
      watchFavorite: watchFavorite,
      toggleFavorite: MockToggleFavorite(),
      guest: guest,
      clock: () => now,
    );
    sent = [];
    handler.playbackState.skip(1).listen(sent.add);
    states.add(music);
    await pumpEventQueue();
  });

  tearDown(() async {
    await handler.dispose();
    await states.close();
    await progress.close();
  });

  test('a playing video takes over the notification', () async {
    expect(handler.mediaItem.value?.title, 'Bad Guy');

    guest.own(video());
    await pumpEventQueue();

    final item = handler.mediaItem.value!;
    expect(item.id, 'video:a');
    expect(item.title, 'Holiday');
    expect(item.displaySubtitle, 'Video · Melodix');
    expect(item.artUri, Uri.parse('file:///thumb.jpg'));
    expect(sent.last.playing, isTrue);
    expect(
      [for (final c in sent.last.controls) c.androidIcon],
      [
        'drawable/ic_media_rewind',
        'drawable/ic_media_previous',
        'drawable/ic_media_pause',
        'drawable/ic_media_next',
        'drawable/ic_media_forward',
      ],
    );
  });

  test('while it owns them, every button controls the video', () async {
    guest.own(video());

    await handler.play();
    await handler.pause();
    await handler.seek(const Duration(seconds: 42));
    await handler.skipToNext();
    await handler.skipToPrevious();
    await handler.fastForward();
    await handler.rewind();
    await handler.customAction(MelodixAudioHandler.forwardAction);
    await handler.customAction(MelodixAudioHandler.rewindAction);

    expect(guest.commands, [
      'play',
      'pause',
      'seek 42',
      'next',
      'previous',
      'forward',
      'rewind',
      'forward',
      'rewind',
    ]);
    verifyNever(() => player.play());
    verifyNever(() => player.pause());
    verifyNever(() => player.next());
    verifyNever(() => player.previous());
  });

  test('music changes meanwhile are not shown over the video', () async {
    guest.own(video());
    await pumpEventQueue();
    current = NowPlaying(
      queue: [song],
      currentIndex: 0,
      isPlaying: true,
      duration: const Duration(minutes: 3),
    );
    states.add(current);
    await pumpEventQueue();

    expect(handler.mediaItem.value?.id, 'video:a');
  });

  test('position ticks are not re-sent; a seek is', () async {
    guest.own(video());
    await pumpEventQueue();
    final count = sent.length;

    now = now.add(const Duration(seconds: 5));
    guest.own(video(position: const Duration(seconds: 5)));
    await pumpEventQueue();
    expect(sent, hasLength(count));

    guest.own(video(position: const Duration(minutes: 4)));
    await pumpEventQueue();
    expect(sent, hasLength(count + 1));
    expect(sent.last.updatePosition, const Duration(minutes: 4));
  });

  test('closing the video gives the music its controls back', () async {
    guest.own(video());
    await pumpEventQueue();

    guest.own(null);
    await pumpEventQueue();

    expect(handler.mediaItem.value?.title, 'Bad Guy');
    expect(sent.last.playing, isFalse);
    await handler.play();
    verify(() => player.play()).called(1);
    expect(guest.commands, isEmpty);
  });

  test('without a guest, nothing changes for the music', () async {
    await handler.skipToNext();
    await handler.fastForward(); // a song has no jumps
    verify(() => player.next()).called(1);
    expect(guest.commands, isEmpty);
  });
}
