import 'package:melodix/core/search/search_history.dart';
import '../../../support/landscape.dart';

import 'package:melodix/core/widgets/app_screen_util_init.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/build_library_catalog_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_event.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/usecases/create_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/delete_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/rename_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_playlist_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_playlists_usecase.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_tabs/songs_tab.dart';
import 'package:melodix/features/music_library/presentation/widgets/music_home_view.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:melodix/core/utils/debug_counters.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/widgets/equalizer_bars.dart';
import 'package:mocktail/mocktail.dart';

import '../../player/player_fixtures.dart';

class MockMusicLibraryBloc extends Mock implements MusicLibraryBloc {}

class MockStorage extends Mock implements Storage {}

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

class MockSongActionsCubit extends Mock implements SongActionsCubit {}

class MockWatchPlaylists extends Mock implements WatchPlaylistsUseCase {}

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
  late MockGetArtwork artwork;
  late StreamController<List<Playlist>> playlists;

  setUpAll(() {
    registerPlayerFallbacks();
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
    artwork = MockGetArtwork();
    when(() => artwork(any())).thenAnswer((_) async => null);
    playlists = StreamController<List<Playlist>>.broadcast();
    getIt
      ..registerSingleton<GetSongArtworkUseCase>(artwork)
      ..registerFactory<LibraryCollectionsCubit>(
        () => LibraryCollectionsCubit(
          buildCatalog: const BuildLibraryCatalogUseCase(),
        ),
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
        () => LibrarySearchCubit(debounce: Duration.zero),
      )
      ..registerLazySingleton<SearchHistoryCubit>(SearchHistoryCubit.new)
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

  /// When set, the view gets this player above it (like the app).
  PlayerHarness? player;
  setUp(() => player = null);

  Future<void> pumpView(WidgetTester tester, MusicLibraryState state) async {
    when(() => bloc.state).thenReturn(state);
    // A phone held upright (the default 800×600 test screen is landscape
    // and shorter than any phone the app targets).
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: _withPlayer(
          player,
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: BlocProvider<MusicLibraryBloc>.value(
                value: bloc,
                child: const MusicHomeView(),
              ),
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

  testWidgets('rotating the phone: the library fits sideways, and back', (
    tester,
  ) async {
    await pumpView(
      tester,
      MusicLibraryState(status: MusicLibraryStatus.ready, songs: _songs),
    );
    await turnSideways(tester);
    expect(find.text('Track 1').hitTestable(), findsOneWidget);
    // Two panes: the cards stacked on the left, the tabs and songs right.
    final favourites = tester.getRect(find.text('Favourites'));
    final recent = tester.getRect(find.text('Recent'));
    final songsTab = tester.getRect(find.text('Songs'));
    expect(recent.top, greaterThan(favourites.bottom)); // stacked
    expect(favourites.right, lessThan(songsTab.left)); // beside the tabs

    await turnUpright(tester);
    expect(find.text('Track 1'), findsOneWidget);
    // One column again: the cards side by side above the tabs.
    final back = tester.getRect(find.text('Favourites'));
    expect(tester.getRect(find.text('Recent')).top, closeTo(back.top, 1));
    expect(back.bottom, lessThan(tester.getRect(find.text('Songs')).top));
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
      // Albums are built from the songs: one with very long names.
      Song song(int id, String album, String artist) => Song(
        id: id,
        title: 'Track $id',
        artist: artist,
        album: album,
        albumId: id,
        duration: const Duration(minutes: 4),
        path: '/m/$id.mp3',
        playbackUri: Uri.parse('content://media/external/audio/media/$id'),
        isFavorite: false,
        playCount: 0,
      );

      await pumpView(
        tester,
        MusicLibraryState(
          status: MusicLibraryStatus.ready,
          songs: [
            song(
              1,
              'A very long album title that keeps going and going',
              'An artist with a really long name as well',
            ),
            song(2, 'Short', 'Someone'),
          ],
        ),
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

    // Results come from the library already in memory (no database).
    expect(find.text('Songs'), findsOneWidget);
    expect(find.text('Track 1'), findsOneWidget);
    expect(find.text('Track 3'), findsOneWidget);

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

  testWidgets('pulling the lists down never starts a scan', (tester) async {
    when(() => bloc.add(any())).thenReturn(null);
    await pumpView(
      tester,
      MusicLibraryState(status: MusicLibraryStatus.ready, songs: _songs),
    );

    // A firm pull down, like the old pull-to-refresh gesture.
    await tester.fling(
      find.text(_songs.first.title),
      const Offset(0, 500),
      2000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Albums'));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(Scrollable).last,
      const Offset(0, 500),
      2000,
    );
    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsNothing);
    verifyNever(() => bloc.add(any(that: isA<MusicLibraryRefreshRequested>())));
  });

  testWidgets('the Scan card asks for a changes-only scan', (tester) async {
    when(() => bloc.add(any())).thenReturn(null);
    await pumpView(
      tester,
      MusicLibraryState(status: MusicLibraryStatus.ready, songs: _songs),
    );

    await tester.tap(find.text('Scan'));
    await tester.pump();

    final event =
        verify(
              () => bloc.add(
                captureAny(that: isA<MusicLibraryRefreshRequested>()),
              ),
            ).captured.single
            as MusicLibraryRefreshRequested;
    expect(event.full, isFalse);
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

  group('switching home tabs', () {
    final manySongs = [
      for (var i = 1; i <= 60; i++)
        Song(
          id: i,
          title: 'Track ${i.toString().padLeft(2, '0')}',
          artist: 'Artist',
          album: 'Album',
          albumId: 1,
          duration: const Duration(minutes: 3),
          path: '/m/$i.mp3',
          playbackUri: Uri.parse('content://media/external/audio/media/$i'),
          isFavorite: false,
          playCount: 0,
        ),
    ];

    /// Advances a second of time. (Waiting for every animation to finish
    /// would never end while music plays: the playing song's equalizer bars
    /// animate continuously by design.)
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// Songs → Albums → Songs, after scrolling the songs list down.
    Future<Map<String, Object>> switchAway(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpView(
        tester,
        MusicLibraryState(status: MusicLibraryStatus.ready, songs: manySongs),
      );
      await settle(tester);

      Finder songsScrollable() => find
          .descendant(
            of: find.byType(SongsTab),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(songsScrollable(), const Offset(0, -600));
      await settle(tester);
      double songsOffset() =>
          tester.state<ScrollableState>(songsScrollable()).position.pixels;
      final offsetBefore = songsOffset();

      DebugCounters.reset();
      clearInteractions(artwork);
      // Switch through the tab controller (the scrollable tab bar may have
      // scrolled a label off-screen).
      final tabs = DefaultTabController.of(tester.element(find.byType(TabBar)));
      for (final index in [2, 0, 2, 0]) {
        tabs.animateTo(index); // 0 = Songs, 2 = Albums
        await settle(tester);
      }

      return {
        'sorts': DebugCounters.of('songsSort'),
        'artworkRequests': verify(() => artwork(any())).callCount,
        'offsetBefore': offsetBefore,
        'offsetAfter': songsOffset(),
      };
    }

    // Baseline before keeping tabs alive (same steps): 2 re-sorts, 40 cover
    // requests, and the Songs scroll position reset from 580 to 0.
    testWidgets(
      'keeps pages alive: no re-sort, no cover reloads, same scroll',
      (tester) async {
        final result = await switchAway(tester);

        expect(result['sorts'], 0);
        // Only the Albums tab's first appearance loads its covers.
        expect(result['artworkRequests'] as int, lessThanOrEqualTo(6));
        expect(result['offsetAfter'], result['offsetBefore']);
        expect(result['offsetBefore'] as double, greaterThan(0));
      },
    );

    testWidgets('works the same while music is playing', (tester) async {
      final harness = PlayerHarness();
      addTearDown(harness.dispose);
      player = harness;
      harness.states.add(
        NowPlaying(queue: manySongs, currentIndex: 0, isPlaying: true),
      );

      final result = await switchAway(tester);

      expect(result['sorts'], 0);
      expect(result['offsetAfter'], result['offsetBefore']);
      // Scroll back up: the playing song is still marked.
      final tabs = DefaultTabController.of(tester.element(find.byType(TabBar)));
      expect(tabs.index, 0);
      await tester.drag(
        find
            .descendant(
              of: find.byType(SongsTab),
              matching: find.byType(Scrollable),
            )
            .first,
        const Offset(0, 2000),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(EqualizerBars), findsOneWidget);
    });

    testWidgets('library changes still reach a kept-alive tab', (tester) async {
      final updates = StreamController<MusicLibraryState>.broadcast();
      addTearDown(updates.close);
      when(() => bloc.stream).thenAnswer((_) => updates.stream);
      await switchAway(tester);

      // A new song arrives while the user is on another tab.
      final tabs = DefaultTabController.of(tester.element(find.byType(TabBar)));
      tabs.animateTo(2);
      await tester.pumpAndSettle();
      final newState = MusicLibraryState(
        status: MusicLibraryStatus.ready,
        songs: [
          Song(
            id: 999,
            title: 'Aaa brand new',
            artist: 'Artist',
            album: 'Album',
            albumId: 1,
            duration: const Duration(minutes: 3),
            path: '/m/999.mp3',
            playbackUri: Uri.parse('content://media/external/audio/media/999'),
            isFavorite: false,
            playCount: 0,
          ),
          ...manySongs,
        ],
      );
      when(() => bloc.state).thenReturn(newState);
      updates.add(newState);
      await tester.pumpAndSettle();

      tabs.animateTo(0);
      await tester.pumpAndSettle();
      expect(find.text('61 songs'), findsOneWidget);
    });

    testWidgets('selecting songs does not re-sort; changing the order does', (
      tester,
    ) async {
      await pumpView(
        tester,
        MusicLibraryState(status: MusicLibraryStatus.ready, songs: manySongs),
      );
      await tester.pumpAndSettle();
      DebugCounters.reset();

      await tester.tap(find.byTooltip('Select songs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Track 01'));
      await tester.pumpAndSettle();
      expect(DebugCounters.of('songsSort'), 0);

      await tester.tap(find.byTooltip('Cancel selection'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sort by'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A–Z').last);
      await tester.pumpAndSettle();
      expect(DebugCounters.of('songsSort'), 1);
    });
  });

  // Baseline before the optimisation (same steps): getAlbums=2,
  // getArtists=2 (each a full DB read + regroup), searchReruns=1 (full DB
  // read + regroup) and sorts=1, for a single favourite.
  testWidgets('a favourite does not regroup, re-read or re-sort the library', (
    tester,
  ) async {
    final updates = StreamController<MusicLibraryState>.broadcast();
    addTearDown(updates.close);
    when(() => bloc.stream).thenAnswer((_) => updates.stream);
    final songs = [
      for (var i = 1; i <= 50; i++)
        Song(
          id: i,
          title: 'Track $i',
          artist: 'Artist',
          album: 'Album',
          albumId: 1,
          duration: const Duration(minutes: 3),
          path: '/m/$i.mp3',
          playbackUri: Uri.parse('content://media/external/audio/media/$i'),
          isFavorite: false,
          playCount: 0,
        ),
    ];
    final start = MusicLibraryState(
      status: MusicLibraryStatus.ready,
      songs: songs,
    );
    await pumpView(tester, start);
    await tester.pumpAndSettle();
    // Open search with a query, like a user searching.
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'track');
    await tester.pump();
    await tester.pumpAndSettle();

    DebugCounters.reset();

    // One song becomes a favourite (what Isar's watch emits).
    final toggled = [songs.first.copyWithFavorite(true), ...songs.skip(1)];
    final next = MusicLibraryState(
      status: MusicLibraryStatus.ready,
      songs: toggled,
    );
    when(() => bloc.state).thenReturn(next);
    updates.add(next);
    await tester.pumpAndSettle();

    expect(DebugCounters.of('collectionsRebuild'), 0);
    expect(DebugCounters.of('songsSort'), 0);
    // The open search updated in memory, showing the new favourite state.
    expect(DebugCounters.of('searchRun'), 1);
    final searchState = tester
        .element(find.byType(TextField))
        .read<LibrarySearchCubit>()
        .state;
    expect(searchState.results.songs.first.isFavorite, isTrue);
  });

  testWidgets('adding a song does regroup and re-sort', (tester) async {
    final updates = StreamController<MusicLibraryState>.broadcast();
    addTearDown(updates.close);
    when(() => bloc.stream).thenAnswer((_) => updates.stream);
    await pumpView(
      tester,
      MusicLibraryState(status: MusicLibraryStatus.ready, songs: _songs),
    );
    await tester.pumpAndSettle();
    DebugCounters.reset();

    final grown = MusicLibraryState(
      status: MusicLibraryStatus.ready,
      songs: [..._songs, _songs.first.withId(99)],
    );
    when(() => bloc.state).thenReturn(grown);
    updates.add(grown);
    await tester.pumpAndSettle();

    expect(DebugCounters.of('collectionsRebuild'), 1);
    expect(DebugCounters.of('songsSort'), 1);
  });
}

extension on Song {
  Song withId(int newId) => Song(
    id: newId,
    title: '$title copy',
    artist: artist,
    album: album,
    albumId: albumId,
    duration: duration,
    path: '$path.copy',
    playbackUri: playbackUri,
    isFavorite: isFavorite,
    playCount: playCount,
    dateAdded: dateAdded,
  );

  Song copyWithFavorite(bool favorite) => Song(
    id: id,
    title: title,
    artist: artist,
    album: album,
    albumId: albumId,
    duration: duration,
    path: path,
    playbackUri: playbackUri,
    isFavorite: favorite,
    playCount: playCount,
    dateAdded: dateAdded,
  );
}

Widget _withPlayer(PlayerHarness? player, Widget app) =>
    player == null ? app : player.provide(app);
