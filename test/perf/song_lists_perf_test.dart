import 'package:melodix/core/search/search_history.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_sort_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_tabs/songs_tab.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/widgets/player_queue_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../features/player/player_fixtures.dart';

import 'package:dartz/dartz.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_results.dart';

class MockArtwork extends Mock implements GetSongArtworkUseCase {}

class MockActions extends Mock implements SongActionsCubit {}

class MockStorage extends Mock implements Storage {}

List<Song> _songs(int count) => [
  for (var i = 0; i < count; i++)
    Song(
      id: i,
      title: 'Song $i',
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

/// Song lists of 10,000 songs stay cheap where they used to stall.
void main() {
  late MockArtwork artwork;
  late Set<int> coversAskedFor;
  late int tilesBuilt;

  setUpAll(() {
    registerPlayerFallbacks();
    registerFallbackValue(const SongArtworkParams(0));
  });

  setUp(() async {
    await getIt.reset();
    coversAskedFor = {};
    artwork = MockArtwork();
    when(() => artwork(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.single as SongArtworkParams;
      coversAskedFor.add(params.songId);
      return null;
    });
    getIt.registerSingleton<GetSongArtworkUseCase>(artwork);
    tilesBuilt = 0;
    debugOnRebuildDirtyWidget = (element, _) {
      if (element.widget is SongTile) tilesBuilt++;
    };
  });

  tearDown(() async {
    debugOnRebuildDirtyWidget = null;
    await getIt.reset();
  });

  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  List<int> visibleSongIds() => [
    for (final e in find.byType(SongTile).evaluate())
      (e.widget as SongTile).song.id,
  ];

  testWidgets(
    'opening the queue at song 5,000 of 10,000 builds only what shows',
    (tester) async {
      // Before: 5,012 rows built (every row up to the current one), 14.5 s.
      phone(tester);
      final harness = PlayerHarness(
        NowPlaying(queue: _songs(10000), currentIndex: 5000),
      );
      addTearDown(harness.dispose);
      await tester.pumpWidget(
        AppScreenUtilInit(
          child: harness.provide(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showPlayerQueue(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      tilesBuilt = 0;

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(); // the jump to the current song
      await tester.pump(const Duration(milliseconds: 500));

      expect(tilesBuilt, lessThan(40));
      // Exactly there: the song before it, then the current one.
      final visible = visibleSongIds();
      expect(visible.first, 4999);
      expect(visible, contains(5000));
    },
  );

  testWidgets('fast flings only load the covers that stay on screen', (
    tester,
  ) async {
    // Before: 662 covers asked for over these five flings (every row that
    // flashed past). Now ~356: none while the list moves faster than about
    // a screen-height a second; rows passing slower than that are on screen
    // long enough to be seen, so they load.
    phone(tester);
    final storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    final actions = MockActions();
    when(() => actions.state).thenReturn(null);
    when(() => actions.stream).thenAnswer((_) => const Stream.empty());
    when(() => actions.close()).thenAnswer((_) async {});
    when(() => actions.canDeleteSongs).thenReturn(true);

    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<SongActionsCubit>.value(value: actions),
                BlocProvider(create: (_) => SongSortCubit()),
              ],
              child: SongsTab(songs: _songs(10000)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    coversAskedFor.clear();

    for (var i = 0; i < 5; i++) {
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -3000),
        8000,
      );
      for (var frame = 0; frame < 60; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await tester.pumpAndSettle();

    expect(coversAskedFor.length, lessThan(450));
    // The rows the user stopped on do get their covers.
    for (final id in visibleSongIds()) {
      expect(coversAskedFor, contains(id), reason: 'song $id on screen');
    }
  });

  /// Phone-sized songs tab over [songs] (no player: rows aren't tapped).
  Future<void> pumpSongsTab(WidgetTester tester, List<Song> songs) async {
    phone(tester);
    final storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    final actions = MockActions();
    when(() => actions.state).thenReturn(null);
    when(() => actions.stream).thenAnswer((_) => const Stream.empty());
    when(() => actions.close()).thenAnswer((_) async {});
    when(() => actions.canDeleteSongs).thenReturn(true);
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<SongActionsCubit>.value(value: actions),
                BlocProvider(create: (_) => SongSortCubit()),
              ],
              child: SongsTab(songs: songs),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the songs tab jumps to the middle of 10,000 songs at once', (
    tester,
  ) async {
    // Before: 5,523 rows built (every row up to the middle), 64.7 s.
    await pumpSongsTab(tester, _songs(10000));
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    tilesBuilt = 0;

    position.jumpTo(position.maxScrollExtent / 2);
    await tester.pump();

    expect(tilesBuilt, lessThan(40));
    // The list knows its real length (no estimate): the end is the end.
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(visibleSongIds(), isNotEmpty);
  });

  testWidgets('album / playlist lists of 10,000 songs jump at once', (
    tester,
  ) async {
    phone(tester);
    getIt.registerFactory<SongActionsCubit>(() {
      final actions = MockActions();
      when(() => actions.state).thenReturn(null);
      when(() => actions.stream).thenAnswer((_) => const Stream.empty());
      when(() => actions.close()).thenAnswer((_) async {});
      when(() => actions.canDeleteSongs).thenReturn(true);
      return actions;
    });
    final cubit = SongListCubit(() async => Right(_songs(10000)));
    await cubit.load();
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: SongListBody(header: (_) => const SizedBox(height: 200)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    tilesBuilt = 0;

    position.jumpTo(position.maxScrollExtent / 2);
    await tester.pump();

    expect(tilesBuilt, lessThan(40));
    await cubit.close();
  });

  testWidgets('"Show all" on 5,000 matching songs builds what shows', (
    tester,
  ) async {
    // Before, all 5,000 rows were created as widget objects up front (only
    // the visible ones were ever built, so this count was low then too):
    // this checks that building rows on demand still shows them all.
    phone(tester);
    HydratedBloc.storage = MemoryStorage(); // the search history's
    final search = LibrarySearchCubit(debounce: Duration.zero)
      ..updateSources(songs: _songs(5000));
    addTearDown(search.close);
    getIt.registerFactory<SongActionsCubit>(() {
      final actions = MockActions();
      when(() => actions.state).thenReturn(null);
      when(() => actions.stream).thenAnswer((_) => const Stream.empty());
      when(() => actions.close()).thenAnswer((_) async {});
      when(() => actions.canDeleteSongs).thenReturn(true);
      return actions;
    });
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: search),
                BlocProvider(create: (_) => SearchHistoryCubit()),
              ],
              child: const LibrarySearchResultsView(),
            ),
          ),
        ),
      ),
    );
    search.queryChanged('Song');
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();

    tilesBuilt = 0;
    await tester.tap(find.text('Show all 5000'));
    await tester.pump();

    expect(tilesBuilt, lessThan(40));
    // Scrolling far down still finds the songs there.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pump();
    expect(visibleSongIds(), isNotEmpty);
  });
}
