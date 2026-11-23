import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/get_albums_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_artists_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_event.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/domain/entities/library_search_results.dart';
import 'package:melodix/features/music_library/domain/usecases/search_library_usecase.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/usecases/create_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/delete_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/rename_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_playlist_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_playlists_usecase.dart';
import 'package:melodix/features/music_library/presentation/widgets/music_home_view.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockMusicLibraryBloc extends Mock implements MusicLibraryBloc {}

class MockStorage extends Mock implements Storage {}

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

class MockGetAlbums extends Mock implements GetAlbumsUseCase {}

class MockGetArtists extends Mock implements GetArtistsUseCase {}

class MockSongActionsCubit extends Mock implements SongActionsCubit {}

class MockWatchPlaylists extends Mock implements WatchPlaylistsUseCase {}

class MockSearchLibrary extends Mock implements SearchLibraryUseCase {}

class MockCreatePlaylist extends Mock implements CreatePlaylistUseCase {}

class MockRenamePlaylist extends Mock implements RenamePlaylistUseCase {}

class MockDeletePlaylist extends Mock implements DeletePlaylistUseCase {}

class MockTogglePlaylistFavorite extends Mock
    implements TogglePlaylistFavoriteUseCase {}

final _songs = [
  for (var i = 1; i <= 3; i++)
    Song(
      id: i,
      title: 'Track $i',
      artist: 'Artist $i',
      album: 'Album',
      albumId: 1,
      duration: Duration(minutes: i, seconds: 5),
      path: '/m/$i.mp3',
      playbackUri: Uri.parse('content://media/external/audio/media/$i'),
      isFavorite: false,
      playCount: 0,
    ),
];

void main() {
  late MockMusicLibraryBloc bloc;
  late MockGetAlbums albums;
  late StreamController<List<Playlist>> playlists;
  late MockSearchLibrary searchLibrary;

  setUpAll(() {
    registerFallbackValue(const SongArtworkParams(0));
    registerFallbackValue(const NoParams());
    registerFallbackValue(const MusicLibraryRefreshRequested());
  });

  setUp(() async {
    await getIt.reset();
    final storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    final artwork = MockGetArtwork();
    when(() => artwork(any())).thenAnswer((_) async => null);
    albums = MockGetAlbums();
    playlists = StreamController<List<Playlist>>.broadcast();
    searchLibrary = MockSearchLibrary();
    when(() => albums(any())).thenAnswer((_) async => const Right([]));
    final artists = MockGetArtists();
    when(() => artists(any())).thenAnswer((_) async => const Right([]));
    getIt
      ..registerSingleton<GetSongArtworkUseCase>(artwork)
      ..registerFactory<LibraryCollectionsCubit>(
        () => LibraryCollectionsCubit(getAlbums: albums, getArtists: artists),
      )
      ..registerFactory<SongActionsCubit>(() {
        final actions = MockSongActionsCubit();
        when(() => actions.state).thenReturn(null);
        when(() => actions.canDeleteSongs).thenReturn(true);
        when(() => actions.stream).thenAnswer((_) => const Stream.empty());
        when(() => actions.close()).thenAnswer((_) async {});
        return actions;
      })
      ..registerFactory<LibrarySearchCubit>(
        () =>
            LibrarySearchCubit(search: searchLibrary, debounce: Duration.zero),
      )
      ..registerFactory<PlaylistsCubit>(() {
        final watch = MockWatchPlaylists();
        when(() => watch()).thenAnswer((_) => playlists.stream);
        return PlaylistsCubit(
          watchPlaylists: watch,
          createPlaylist: MockCreatePlaylist(),
          renamePlaylist: MockRenamePlaylist(),
          deletePlaylist: MockDeletePlaylist(),
          toggleFavorite: MockTogglePlaylistFavorite(),
        );
      });

    bloc = MockMusicLibraryBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.close()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await playlists.close();
    await getIt.reset();
  });

  Future<void> pumpView(WidgetTester tester, MusicLibraryState state) async {
    when(() => bloc.state).thenReturn(state);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: BlocProvider<MusicLibraryBloc>.value(
              value: bloc,
              child: const MusicHomeView(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('asks for access and requests it on tap', (tester) async {
    await pumpView(
      tester,
      const MusicLibraryState(
        status: MusicLibraryStatus.permissionRequired,
        permission: LibraryPermission.denied,
      ),
    );

    expect(find.text('Allow access to your music'), findsOneWidget);
    await tester.tap(find.text('Allow access'));
    verify(() => bloc.add(const MusicLibraryPermissionRequested())).called(1);
  });

  testWidgets('offers settings when access is permanently denied', (
    tester,
  ) async {
    await pumpView(
      tester,
      const MusicLibraryState(
        status: MusicLibraryStatus.permissionRequired,
        permission: LibraryPermission.permanentlyDenied,
      ),
    );

    await tester.tap(find.text('Open settings'));
    verify(() => bloc.add(const MusicLibraryOpenSettingsRequested())).called(1);
  });

  testWidgets('shows progress during the first scan', (tester) async {
    await pumpView(
      tester,
      const MusicLibraryState(status: MusicLibraryStatus.scanning),
    );

    expect(find.text('Scanning your music…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an empty state with retry', (tester) async {
    await pumpView(
      tester,
      const MusicLibraryState(status: MusicLibraryStatus.ready),
    );

    expect(find.text('No music found'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const MusicLibraryRefreshRequested())).called(1);
  });

  testWidgets('lists songs with tabs when the library is ready', (
    tester,
  ) async {
    await pumpView(
      tester,
      MusicLibraryState(status: MusicLibraryStatus.ready, songs: _songs),
    );

    expect(find.text('3 songs'), findsOneWidget);
    expect(find.text('Songs'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
    expect(find.text('Artists'), findsOneWidget);
    expect(find.text('Track 1'), findsOneWidget);
    expect(find.text('Artist 2'), findsOneWidget);
    expect(find.text('3:05'), findsOneWidget);
  });

  for (final textScale in [1.0, 1.3, 2.0]) {
    testWidgets('albums grid does not overflow at text scale $textScale', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      when(() => albums(any())).thenAnswer(
        (_) async => const Right([
          Album(
            albumId: 1,
            title: 'A very long album title that keeps going and going',
            artist: 'An artist with a really long name as well',
            songCount: 12,
            duration: Duration(minutes: 48),
            artworkSongId: 1,
          ),
          Album(
            albumId: 2,
            title: 'Short',
            artist: 'Someone',
            songCount: 3,
            duration: Duration(minutes: 9),
            artworkSongId: 2,
          ),
        ]),
      );

      await pumpView(
        tester,
        MusicLibraryState(status: MusicLibraryStatus.ready, songs: _songs),
      );
      // With large text the tab bar scrolls; bring the tab into view first.
      await tester.ensureVisible(find.text('Albums'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Albums'));
      await tester.pumpAndSettle();

      expect(find.text('Short'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('playlists tab shows an empty state, then the playlists', (
    tester,
  ) async {
    await pumpView(
      tester,
      MusicLibraryState(status: MusicLibraryStatus.ready, songs: _songs),
    );
    await tester.tap(find.text('Playlists'));
    await tester.pump();
    playlists.add(const []);
    await tester.pumpAndSettle();

    expect(find.text('No playlists yet'), findsOneWidget);
    expect(find.text('New playlist'), findsOneWidget);

    playlists.add(const [
      Playlist(
        id: 1,
        name: 'Road trip',
        songCount: 2,
        isFavorite: true,
        artworkSongId: 1,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Road trip'), findsOneWidget);
    expect(find.text('2 songs'), findsOneWidget);
    expect(find.byTooltip('Playlist options'), findsOneWidget);
  });

  testWidgets('new playlist asks for a name', (tester) async {
    await pumpView(
      tester,
      MusicLibraryState(status: MusicLibraryStatus.ready, songs: _songs),
    );
    await tester.tap(find.text('Playlists'));
    await tester.pump();
    playlists.add(const []);
    await tester.pumpAndSettle();

    await tester.tap(find.text('New playlist'));
    await tester.pumpAndSettle();
    expect(find.text('Give your playlist a name'), findsOneWidget);
    expect(find.text('Playlist name'), findsOneWidget);

    ElevatedButton createButton() => tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Create'),
    );

    // Disabled until there's a name.
    expect(createButton().onPressed, isNull);

    // A suggestion fills the name and enables Create.
    await tester.tap(find.text('Road trip'));
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Road trip'), findsOneWidget);
    expect(createButton().onPressed, isNotNull);

    // Clearing disables it again.
    await tester.tap(find.byTooltip('Clear name'));
    await tester.pump();
    expect(createButton().onPressed, isNull);
  });

  testWidgets('search opens, shows grouped results and closes back home', (
    tester,
  ) async {
    when(() => searchLibrary(any())).thenAnswer(
      (_) async => Right(
        LibrarySearchResults(
          songs: [_songs.first],
          artists: const [
            Artist(
              name: 'Artist 1',
              songCount: 1,
              albumCount: 1,
              artworkSongId: 1,
            ),
          ],
        ),
      ),
    );
    await pumpView(
      tester,
      MusicLibraryState(status: MusicLibraryStatus.ready, songs: _songs),
    );

    // Closed: title + tabs, no results.
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);
    expect(find.text('Find your music'), findsNothing);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    // Open: prompt shown, tabs folded away.
    expect(find.text('Find your music'), findsOneWidget);
    expect(find.text('Playlists'), findsNothing);

    await tester.enterText(find.byType(TextField), 'track');
    await tester.pump();
    await tester.pumpAndSettle();

    verify(() => searchLibrary('track')).called(1);
    expect(find.text('Songs'), findsOneWidget);
    expect(find.text('Artists'), findsOneWidget);
    expect(find.text('Artist 1'), findsWidgets);

    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();

    // Back home: title + tabs again, search reset.
    expect(find.text('Find your music'), findsNothing);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the search pill visibly expands and collapses', (tester) async {
    await pumpView(
      tester,
      MusicLibraryState(status: MusicLibraryStatus.ready, songs: _songs),
    );
    double pillWidth() => tester.getSize(find.byType(ClipRRect).first).width;

    final collapsed = pillWidth();
    await tester.tap(find.byTooltip('Search'));
    await tester.pump(); // starts
    await tester.pump(const Duration(milliseconds: 300)); // halfway
    final halfway = pillWidth();
    await tester.pumpAndSettle();
    final open = pillWidth();

    expect(halfway, greaterThan(collapsed));
    expect(open, greaterThan(halfway));

    await tester.tap(find.byTooltip('Close search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250)); // halfway back
    final closing = pillWidth();
    await tester.pumpAndSettle();

    expect(closing, lessThan(open));
    expect(closing, greaterThan(collapsed));
    expect(pillWidth(), collapsed);
  });

  testWidgets('search shows a message when nothing matches', (tester) async {
    when(() => searchLibrary(any()))
        .thenAnswer((_) async => const Right(LibrarySearchResults.empty));
    await pumpView(
      tester,
      MusicLibraryState(status: MusicLibraryStatus.ready, songs: _songs),
    );

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('No results for "zzz"'), findsOneWidget);
  });

  testWidgets('sorting reorders the songs list', (tester) async {
    Song song(int id, String title, DateTime added, int plays) => Song(
      id: id,
      title: title,
      artist: 'Artist',
      album: 'Album',
      albumId: 1,
      duration: const Duration(minutes: 3),
      path: '/m/$id.mp3',
      playbackUri: Uri.parse('content://media/external/audio/media/$id'),
      isFavorite: false,
      playCount: plays,
      dateAdded: added,
    );
    await pumpView(
      tester,
      MusicLibraryState(
        status: MusicLibraryStatus.ready,
        songs: [
          song(1, 'Bravo', DateTime(2026, 1, 1), 1),
          song(2, 'Alpha', DateTime(2026, 3, 1), 0),
          song(3, 'Charlie', DateTime(2026, 2, 1), 7),
        ],
      ),
    );

    List<String> order() {
      final titles = ['Alpha', 'Bravo', 'Charlie'];
      titles.sort(
        (a, b) => tester
            .getTopLeft(find.text(a))
            .dy
            .compareTo(tester.getTopLeft(find.text(b)).dy),
      );
      return titles;
    }

    // Default: recently added.
    expect(find.text('Recently added'), findsOneWidget);
    expect(order(), ['Alpha', 'Charlie', 'Bravo']);

    await tester.tap(find.byTooltip('Sort by'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A–Z').last);
    await tester.pumpAndSettle();
    expect(order(), ['Alpha', 'Bravo', 'Charlie']);

    await tester.tap(find.byTooltip('Sort by'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Most played').last);
    await tester.pumpAndSettle();
    expect(order(), ['Charlie', 'Bravo', 'Alpha']);
    expect(find.text('Artist · 7 plays'), findsOneWidget);
  });
}
