import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/usecases/get_album_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_artist_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_playlist_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/pages/album_details_page.dart';
import 'package:melodix/features/music_library/presentation/pages/artist_details_page.dart';
import 'package:melodix/features/music_library/presentation/pages/playlist_details_page.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../player/player_fixtures.dart';

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

class MockActions extends Mock implements SongActionsCubit {}

class MockAlbumSongs extends Mock implements GetAlbumSongsUseCase {}

class MockArtistSongs extends Mock implements GetArtistSongsUseCase {}

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
  name: 'Artist',
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
    registerFallbackValue(_album);
  });

  setUp(() async {
    await getIt.reset();
    final artwork = MockGetArtwork();
    when(() => artwork(any())).thenAnswer((_) async => null);
    final albumSongs = MockAlbumSongs();
    when(() => albumSongs(any()))
        .thenAnswer((_) async => Right([playerSong(1)]));
    final artistSongs = MockArtistSongs();
    when(() => artistSongs(any()))
        .thenAnswer((_) async => Right([playerSong(1)]));
    final playlistSongs = MockPlaylistSongs();
    when(() => playlistSongs(any()))
        .thenAnswer((_) async => Right([playerSong(1)]));
    getIt
      ..registerSingleton<GetSongArtworkUseCase>(artwork)
      ..registerSingleton<GetAlbumSongsUseCase>(albumSongs)
      ..registerSingleton<GetArtistSongsUseCase>(artistSongs)
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

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    harness = PlayerHarness();
    addTearDown(harness.dispose);
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        child: BlocProvider<PlayerCubit>.value(
          value: harness.cubit,
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
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byTooltip('Open player'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
      // Same player: controls act on it.
      await tester.tap(find.byTooltip('Pause'));
      verify(() => harness.controls.pause()).called(1);
    });
  }
}
