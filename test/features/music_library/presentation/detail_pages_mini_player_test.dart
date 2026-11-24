import '../../../support/landscape.dart';

import 'package:melodix/core/widgets/app_screen_util_init.dart';

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/get_playlist_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/pages/album_details_page.dart';
import 'package:melodix/features/music_library/presentation/pages/artist_details_page.dart';
import 'package:melodix/features/music_library/presentation/pages/playlist_details_page.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../player/player_fixtures.dart';

import 'package:melodix/features/player/presentation/logic/playback_progress_cubit.dart';

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

class MockActions extends Mock implements SongActionsCubit {}

class MockLibrary extends Mock implements MusicLibraryBloc {}

class MockPlaylistSongs extends Mock implements GetPlaylistSongsUseCase {}

class MockPlaylists extends Mock implements PlaylistsCubit {}

const _album = Album(
  albumId: 1,
  title: 'Album',
  artist: 'Artist',
  songCount: 1,
  duration: Duration(minutes: 3),
  artworkSongId: 1,
);
const _artist = Artist(
  name: 'Artist 1',
  songCount: 1,
  albumCount: 1,
  artworkSongId: 1,
);
const _playlist = Playlist(
  id: 4,
  name: 'Road trip',
  songCount: 1,
  isFavorite: false,
  artworkSongId: 1,
);

void main() {
  late PlayerHarness harness;

  setUpAll(() {
    registerPlayerFallbacks();
    registerFallbackValue(const SongArtworkParams(0));
  });

  setUp(() async {
    await getIt.reset();
    final artwork = MockGetArtwork();
    when(() => artwork(any())).thenAnswer((_) async => null);
    final playlistSongs = MockPlaylistSongs();
    when(() => playlistSongs(any()))
        .thenAnswer((_) async => Right([playerSong(1)]));
    getIt
      ..registerSingleton<GetSongArtworkUseCase>(artwork)
      ..registerSingleton<GetPlaylistSongsUseCase>(playlistSongs)
      ..registerFactory<SongActionsCubit>(() {
        final actions = MockActions();
        when(() => actions.state).thenReturn(null);
        when(() => actions.stream).thenAnswer((_) => const Stream.empty());
        when(() => actions.close()).thenAnswer((_) async {});
        when(() => actions.canDeleteSongs).thenReturn(true);
        return actions;
      })
      ..registerFactory<PlaylistsCubit>(() {
        final playlists = MockPlaylists();
        const state = PlaylistsState(isLoading: false, playlists: [_playlist]);
        when(() => playlists.state).thenReturn(state);
        when(() => playlists.stream).thenAnswer((_) => const Stream.empty());
        when(() => playlists.close()).thenAnswer((_) async {});
        return playlists;
      });
  });

  tearDown(() => getIt.reset());

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    Stream<List<Song>>? librarySongs,
  }) async {
    // The library the album / artist pages read their songs from.
    final library = MockLibrary();
    final songs = [playerSong(1)];
    when(() => library.state).thenReturn(MusicLibraryState(songs: songs));
    when(() => library.stream).thenAnswer((_) => const Stream.empty());
    when(() => library.librarySongs())
        .thenAnswer((_) => librarySongs ?? Stream.value(songs));
    when(() => library.close()).thenAnswer((_) async {});
    harness = PlayerHarness();
    addTearDown(harness.dispose);
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<PlayerCubit>.value(value: harness.cubit),
            BlocProvider<PlaybackProgressCubit>.value(
              value: harness.progressCubit,
            ),
            BlocProvider<MusicLibraryBloc>.value(value: library),
          ],
          child: MaterialApp(theme: AppTheme.darkTheme, home: page),
        ),
      ),
    );
    await tester.pump();
  }

  final playing = NowPlaying(
    queue: [playerSong(1, title: 'Bad Guy')],
    currentIndex: 0,
    isPlaying: true,
    duration: const Duration(minutes: 3),
  );

  final pages = <String, Widget>{
    'album': const AlbumDetailsPage(album: _album),
    'artist': const ArtistDetailsPage(artist: _artist),
    'playlist': const PlaylistDetailsPage(playlist: _playlist),
  };

  for (final entry in pages.entries) {
    testWidgets('${entry.key} page keeps the mini player', (tester) async {
      await pumpPage(tester, entry.value);
      expect(find.byTooltip('Open player'), findsNothing); // nothing loaded

      harness.states.add(playing);
      // Not "settle": the playing song's equalizer bars keep moving.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byTooltip('Open player'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
      // Same player: controls act on it.
      await tester.tap(find.byTooltip('Pause'));
      verify(() => harness.controls.pause()).called(1);
    });
  }

  for (final entry in pages.entries) {
    testWidgets('${entry.key} page fits sideways', (tester) async {
      await pumpPage(tester, entry.value);
      harness.states.add(playing);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await turnSideways(tester);
      expect(find.byTooltip('Open player'), findsOneWidget);
      // The header is one row (cover beside the words): the songs show.
      expect(find.text('Song 1').hitTestable(), findsOneWidget);
      await turnUpright(tester);
      expect(find.text('Song 1'), findsOneWidget);
    });
  }

  testWidgets('album page follows the library live', (tester) async {
    final library = StreamController<List<Song>>();
    addTearDown(library.close);
    await pumpPage(
      tester,
      const AlbumDetailsPage(album: _album),
      librarySongs: library.stream,
    );
    final other = Song(
      id: 9,
      title: 'Elsewhere',
      artist: 'Someone',
      album: 'Other album',
      albumId: 2,
      duration: const Duration(minutes: 1),
      path: '/m/9.mp3',
      playbackUri: Uri.parse('content://media/external/audio/media/9'),
      isFavorite: false,
      playCount: 0,
    );

    library.add([playerSong(1), playerSong(2), other]);
    await tester.pumpAndSettle();
    expect(find.text('Song 1'), findsOneWidget);
    expect(find.text('Song 2'), findsOneWidget);
    expect(find.text('Elsewhere'), findsNothing); // another album
    expect(find.textContaining('2 songs'), findsOneWidget); // live header

    // Song 2 hidden elsewhere: gone here too, no reload needed.
    library.add([playerSong(1), other]);
    await tester.pumpAndSettle();
    expect(find.text('Song 2'), findsNothing);
    expect(find.textContaining('1 song'), findsOneWidget);
  });
}
