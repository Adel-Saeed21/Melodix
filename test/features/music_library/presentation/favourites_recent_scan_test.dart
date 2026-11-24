import 'package:melodix/features/video/domain/usecases/video_bulk_usecases.dart';

import '../../../support/landscape.dart';

import 'package:melodix/core/widgets/app_screen_util_init.dart';

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/clear_recently_played_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_recently_played_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/pages/favourites_page.dart';
import 'package:melodix/features/music_library/presentation/pages/recently_played_page.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_shortcuts.dart';
import 'package:melodix/features/player/domain/usecases/play_queue_usecase.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/usecases/get_video_thumbnail_usecase.dart';
import 'package:melodix/features/video/domain/usecases/toggle_video_favorite_usecase.dart';
import 'package:melodix/features/video/domain/usecases/watch_favorite_videos_usecase.dart';
import 'package:melodix/features/video/presentation/logic/favorite_videos_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/video_tile.dart';
import 'package:mocktail/mocktail.dart';

import '../../player/player_fixtures.dart';

import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';
import 'package:melodix/features/player/presentation/logic/playback_progress_cubit.dart';

class MockLibrary extends Mock implements MusicLibraryBloc {}

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

class MockActions extends Mock implements SongActionsCubit {}

class MockWatchRecent extends Mock implements WatchRecentlyPlayedUseCase {}

class MockClearRecent extends Mock implements ClearRecentlyPlayedUseCase {}

class MockWatchFavoriteVideos extends Mock
    implements WatchFavoriteVideosUseCase {}

class MockToggleVideoFavorite extends Mock
    implements ToggleVideoFavoriteUseCase {}

class MockGetVideoThumbnail extends Mock implements GetVideoThumbnailUseCase {}

class MockSetVideosFavorite extends Mock implements SetVideosFavoriteUseCase {}

Video _video(String id) => Video(
  id: id,
  title: 'Video $id',
  duration: const Duration(minutes: 2),
  width: 1920,
  height: 1080,
  createdAt: DateTime(2026),
  isFavorite: true,
);

Song _song(int id, {bool favorite = false, int minutes = 3}) => Song(
  id: id,
  title: 'Song $id',
  artist: 'Artist',
  album: 'Album',
  albumId: 1,
  duration: Duration(minutes: minutes),
  path: '/m/$id.mp3',
  playbackUri: Uri.parse('content://media/external/audio/media/$id'),
  isFavorite: favorite,
  playCount: 0,
);

void main() {
  late MockLibrary library;
  late StreamController<List<Song>> librarySongs;
  late PlayerHarness harness;
  var libraryState = const MusicLibraryState();

  setUpAll(() {
    registerPlayerFallbacks();
    registerFallbackValue(const SongArtworkParams(0));
    registerFallbackValue(const NoParams());
  });

  setUp(() async {
    await getIt.reset();
    final artwork = MockGetArtwork();
    when(() => artwork(any())).thenReturn(null);
    getIt
      ..registerSingleton<GetSongArtworkUseCase>(artwork)
      ..registerFactory<SongActionsCubit>(() {
        final actions = MockActions();
        when(() => actions.state).thenReturn(null);
        when(() => actions.stream).thenAnswer((_) => const Stream.empty());
        when(() => actions.close()).thenAnswer((_) async {});
        when(() => actions.canDeleteSongs).thenReturn(true);
        return actions;
      });

    library = MockLibrary();
    librarySongs = StreamController<List<Song>>.broadcast();
    libraryState = const MusicLibraryState();
    when(() => library.state).thenAnswer((_) => libraryState);
    when(() => library.stream).thenAnswer((_) => const Stream.empty());
    when(() => library.librarySongs()).thenAnswer((_) => librarySongs.stream);
    when(() => library.close()).thenAnswer((_) async {});
    harness = PlayerHarness();
  });

  tearDown(() async {
    await harness.dispose();
    await librarySongs.close();
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<MusicLibraryBloc>.value(value: library),
            BlocProvider.value(value: harness.cubit),
            BlocProvider<PlaybackProgressCubit>.value(
              value: harness.progressCubit,
            ),
            // App-wide favourite videos (as in MelodixApp), when the test
            // set them up.
            if (getIt.isRegistered<FavoriteVideosCubit>())
              BlocProvider<FavoriteVideosCubit>(
                create: (_) => getIt<FavoriteVideosCubit>(),
              ),
          ],
          child: MaterialApp(theme: AppTheme.darkTheme, home: child),
        ),
      ),
    );
    await tester.pump();
  }

  group('shortcut cards', () {
    Future<void> pumpCards(
      WidgetTester tester, {
      int favourites = 0,
      bool isScanning = false,
      LibrarySyncStage? stage,
      Future<void> Function()? onScan,
    }) => pump(
      tester,
      Scaffold(
        body: LibraryShortcuts(
          favouriteCount: favourites,
          isScanning: isScanning,
          syncStage: stage,
          onScan: onScan ?? () async {},
        ),
      ),
    );

    /// The percentage the Scan card shows (null when not scanning).
    int? percent(WidgetTester tester) {
      final caption = find.textContaining('Scanning… ');
      if (caption.evaluate().isEmpty) return null;
      final text = tester.widget<Text>(caption).data!;
      return int.parse(RegExp(r'(\d+)%').firstMatch(text)!.group(1)!);
    }

    testWidgets('show Favourites (with its count), Recent and Scan', (
      tester,
    ) async {
      await pumpCards(tester, favourites: 12);

      expect(find.text('Favourites'), findsOneWidget);
      expect(find.text('12 songs'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Find new music'), findsOneWidget);
    });

    testWidgets('progress never runs ahead of the real stage', (tester) async {
      // A long scan: the bloc reports its stages as the work gets there.
      await pumpCards(
        tester,
        isScanning: true,
        stage: LibrarySyncStage.checking,
      );
      await tester.pump(const Duration(seconds: 20));
      expect(percent(tester), lessThanOrEqualTo(12));

      await pumpCards(
        tester,
        isScanning: true,
        stage: LibrarySyncStage.reading,
      );
      await tester.pump(const Duration(seconds: 1));
      final early = percent(tester)!;
      await tester.pump(const Duration(seconds: 60));
      final late = percent(tester)!;
      expect(late, greaterThan(early)); // it keeps moving…
      expect(late, lessThan(80)); // …but never past reading

      await pumpCards(tester, isScanning: true, stage: LibrarySyncStage.saving);
      await tester.pump(const Duration(seconds: 60));
      expect(percent(tester), lessThan(97));
      expect(find.text('Done · 100%'), findsNothing);

      // Finished: 100%, ✓, then back to normal.
      await pumpCards(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Done · 100%'), findsOneWidget);
      // The badge (and the card's faded corner icon) turn into ✓.
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300)); // icon swap
      expect(find.text('Find new music'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('the ring fills as a progress value, not a spinner', (
      tester,
    ) async {
      await pumpCards(
        tester,
        isScanning: true,
        stage: LibrarySyncStage.reading,
      );
      await tester.pump(const Duration(seconds: 2));

      final ring = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(ring.value, isNotNull);
      expect(ring.value, inExclusiveRange(0.12, 0.80));
    });

    testWidgets('scan: progress, 100%, then what it found', (tester) async {
      final scan = Completer<void>();
      await pumpCards(tester, onScan: () => scan.future);

      await tester.tap(find.text('Scan'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(percent(tester), isNotNull);

      libraryState = MusicLibraryState(
        lastSyncResult: LibrarySyncResult(
          added: 3,
          updated: 0,
          removed: 1,
          total: 40,
          syncedAt: DateTime(2026),
        ),
      );
      scan.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Done · 100%'), findsOneWidget);
      expect(find.text('Found 3 new songs · 1 song removed'), findsOneWidget);
      // ✓ stays a moment (a timer), then the card is back to normal.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Find new music'), findsOneWidget);
    });

    testWidgets('a scan with no changes says the library is up to date', (
      tester,
    ) async {
      await pumpCards(tester);
      libraryState = MusicLibraryState(
        lastSyncResult: LibrarySyncResult(
          added: 0,
          updated: 2,
          removed: 0,
          total: 40,
          syncedAt: DateTime(2026),
        ),
      );

      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      expect(find.text('Your library is up to date'), findsOneWidget);
    });

    testWidgets('a failed scan shows its error', (tester) async {
      await pumpCards(tester);
      libraryState = const MusicLibraryState(errorMessage: 'No access');

      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      expect(find.text('No access'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('no second scan while one is running', (tester) async {
      var scans = 0;
      await pumpCards(
        tester,
        isScanning: true, // e.g. the automatic one at startup
        onScan: () async => scans++,
      );

      await tester.tap(find.text('Scan'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(scans, 0);
      expect(percent(tester), isNotNull);
    });

    testWidgets('a scan the app starts by itself shows progress, no message', (
      tester,
    ) async {
      await pumpCards(tester);
      await pumpCards(
        tester,
        isScanning: true,
        stage: LibrarySyncStage.reading,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(percent(tester), isNotNull);

      await pumpCards(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Find new music'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('favourites page', () {
    late StreamController<List<Video>> favouriteVideos;
    late MockToggleVideoFavorite toggleVideo;

    setUp(() {
      favouriteVideos = StreamController<List<Video>>.broadcast();
      final watch = MockWatchFavoriteVideos();
      when(() => watch()).thenAnswer((_) => favouriteVideos.stream);
      toggleVideo = MockToggleVideoFavorite();
      final thumbnails = MockGetVideoThumbnail();
      when(() => thumbnails(any(), size: any(named: 'size'))).thenReturn(null);
      when(() => thumbnails.cached(any(), size: any(named: 'size')))
          .thenReturn(null);
      getIt
        ..registerSingleton<GetVideoThumbnailUseCase>(thumbnails)
        ..registerFactory<FavoriteVideosCubit>(
          () => FavoriteVideosCubit(
            watchFavorites: watch,
            toggleFavorite: toggleVideo,
            setFavorite: MockSetVideosFavorite(),
          ),
        );
    });

    tearDown(() => favouriteVideos.close());

    Future<void> openVideosTab(WidgetTester tester) async {
      await tester.tap(find.text('Videos'));
      await tester.pumpAndSettle();
    }

    testWidgets('fits sideways (songs and videos), and back', (tester) async {
      await pump(tester, const FavouritesPage());
      librarySongs.add([
        for (var i = 1; i <= 12; i++) _song(i, favorite: true),
      ]);
      favouriteVideos.add([_video('a'), _video('b')]);
      await tester.pumpAndSettle();

      await turnSideways(tester);
      expect(find.text('Songs').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Videos').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Video a'), findsOneWidget);
      await turnUpright(tester);
    });

    testWidgets('two tabs; the hero counts both', (tester) async {
      await pump(tester, const FavouritesPage());
      librarySongs.add([_song(1, favorite: true), _song(2)]);
      favouriteVideos.add([_video('a'), _video('b')]);
      await tester.pumpAndSettle();

      expect(find.text('Songs'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      // (The hero is also measured off-screen: only the shown one counts.)
      expect(find.text('1 song · 2 videos').hitTestable(), findsOneWidget);
      // Songs first.
      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Video a'), findsNothing);

      await openVideosTab(tester);
      expect(find.text('Video a'), findsOneWidget);
      expect(find.text('Video b'), findsOneWidget);
      expect(find.text('Song 1'), findsNothing);
    });

    testWidgets('the hero (heart, title, counts) is centred', (tester) async {
      await pump(tester, const FavouritesPage());
      librarySongs.add([_song(1, favorite: true)]);
      favouriteVideos.add(const []);
      await tester.pumpAndSettle();

      final screenCenter =
          tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;
      for (final finder in [
        find.text('Favourites').hitTestable(),
        find.text('1 song · 0 videos').hitTestable(),
      ]) {
        expect(tester.getCenter(finder).dx, closeTo(screenCenter, 1));
      }
    });

    testWidgets('lists only favourite songs, live', (tester) async {
      await pump(tester, const FavouritesPage());
      librarySongs.add([
        _song(1, favorite: true),
        _song(2),
        _song(3, favorite: true, minutes: 45),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Song 2'), findsNothing);
      expect(find.text('Song 3'), findsOneWidget);
      expect(find.text('2 songs · 48 min'), findsOneWidget);

      // Unfavourited elsewhere: gone here too.
      librarySongs.add([_song(1, favorite: true), _song(2), _song(3)]);
      await tester.pumpAndSettle();
      expect(find.text('Song 3'), findsNothing);
      expect(find.text('1 song · 3 min'), findsOneWidget);
    });

    testWidgets('play and shuffle start the favourite songs', (tester) async {
      await pump(tester, const FavouritesPage());
      librarySongs.add([_song(1, favorite: true), _song(2, favorite: true)]);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      final play =
          verify(() => harness.playQueue(captureAny())).captured.single
              as PlayQueueParams;
      expect(play.songs.map((s) => s.id), [1, 2]);
      expect(play.startIndex, 0);
      expect(play.title, 'Favourites');

      await tester.tap(find.byIcon(Icons.shuffle_rounded));
      await tester.pump();
      final shuffled =
          verify(() => harness.playQueue(captureAny())).captured.single
              as PlayQueueParams;
      expect(shuffled.shuffle, isTrue);
      expect(shuffled.songs.map((s) => s.id), [1, 2]);
      // One step: the current queue isn't reshuffled first.
      verifyNever(() => harness.controls.setShuffle(any()));
    });

    testWidgets('without favourites: friendly empty states', (tester) async {
      await pump(tester, const FavouritesPage());
      librarySongs.add([_song(1)]);
      favouriteVideos.add(const []);
      await tester.pumpAndSettle();

      expect(find.text('No favourites yet'), findsOneWidget);
      // Nothing to play: no Play / Shuffle at all.
      expect(find.byIcon(Icons.shuffle_rounded), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

      await openVideosTab(tester);
      expect(find.text('No favourite videos yet'), findsOneWidget);
    });

    testWidgets('a video unfavourited here leaves, with Undo', (tester) async {
      when(() => toggleVideo('a')).thenAnswer((_) async => const Right(false));
      await pump(tester, const FavouritesPage());
      librarySongs.add(const []);
      favouriteVideos.add([_video('a'), _video('b')]);
      await tester.pumpAndSettle();
      await openVideosTab(tester);

      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('Video a'),
            matching: find.byType(VideoTile),
          ),
          matching: find.byIcon(Icons.favorite_rounded),
        ),
      );
      // The storage's live list drops it before the toggle answers.
      favouriteVideos.add([_video('b')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('Video a'), findsNothing);
      // The message still shows, though its row is gone.
      expect(find.text('Removed from favourites'), findsOneWidget);

      when(() => toggleVideo('a')).thenAnswer((_) async => const Right(true));
      await tester.pump(const Duration(milliseconds: 400)); // slid in
      await tester.tap(find.text('Undo'));
      await tester.pump();
      verify(() => toggleVideo('a')).called(2); // remove + undo
    });

    testWidgets('a failed unfavourite says so', (tester) async {
      when(() => toggleVideo('a'))
          .thenAnswer((_) async => const Left(LibraryFailure('nope')));
      await pump(tester, const FavouritesPage());
      librarySongs.add(const []);
      favouriteVideos.add([_video('a')]);
      await tester.pumpAndSettle();
      await openVideosTab(tester);

      await tester.tap(find.byTooltip('Remove from favourites'));
      await tester.pump();
      await tester.pump();
      expect(find.text("Couldn't save your change"), findsOneWidget);
      expect(find.text('Video a'), findsOneWidget);
    });

    testWidgets('scrolled down: the tabs stay pinned under the app bar', (
      tester,
    ) async {
      await pump(tester, const FavouritesPage());
      librarySongs.add([
        for (var i = 1; i <= 60; i++) _song(i, favorite: true),
      ]);
      await tester.pumpAndSettle();
      final tabsAtRest = tester.getTopLeft(find.byType(TabBar)).dy;

      await tester.drag(find.text('Song 3'), const Offset(0, -3000));
      await tester.pumpAndSettle();

      final tabsTop = tester.getTopLeft(find.byType(TabBar)).dy;
      expect(tabsTop, lessThan(tabsAtRest));
      expect(tabsTop, closeTo(kToolbarHeight, 1));
      expect(find.text('Song 1'), findsNothing);
      // The first row shown starts below the tabs, not under them.
      final tabsBottom = tester.getBottomLeft(find.byType(TabBar)).dy;
      final firstVisible = find
          .byType(SongTile)
          .evaluate()
          .map((e) => tester.getTopLeft(find.byWidget(e.widget)).dy);
      expect(firstVisible.where((y) => y >= tabsBottom - 1), isNotEmpty);
      // Switching tabs works from down here.
      favouriteVideos.add([_video('a')]);
      await openVideosTab(tester);
      expect(find.text('Video a'), findsOneWidget);
    });
  });

  group('recently played page', () {
    late StreamController<List<Song>> recent;
    late MockClearRecent clear;

    setUp(() {
      recent = StreamController<List<Song>>.broadcast();
      final watch = MockWatchRecent();
      when(() => watch()).thenAnswer((_) => recent.stream);
      clear = MockClearRecent();
      getIt
        ..registerSingleton<WatchRecentlyPlayedUseCase>(watch)
        ..registerSingleton<ClearRecentlyPlayedUseCase>(clear);
    });

    tearDown(() => recent.close());

    testWidgets('fits sideways', (tester) async {
      await pump(tester, const RecentlyPlayedPage());
      recent.add([_song(5), _song(2)]);
      await tester.pumpAndSettle();
      await turnSideways(tester);
      expect(find.text('Song 5'), findsOneWidget);
    });

    testWidgets('lists the history newest first, live', (tester) async {
      await pump(tester, const RecentlyPlayedPage());
      recent.add([_song(5), _song(2)]);
      await tester.pumpAndSettle();

      final first = tester.getTopLeft(find.text('Song 5')).dy;
      final second = tester.getTopLeft(find.text('Song 2')).dy;
      expect(first, lessThan(second));
      expect(find.text('2 songs'), findsOneWidget);

      recent.add([_song(7), _song(5), _song(2)]); // a song was played
      await tester.pumpAndSettle();
      expect(find.text('Song 7'), findsOneWidget);
    });

    testWidgets('clearing the history asks first', (tester) async {
      when(() => clear(any())).thenAnswer((_) async => const Right(unit));
      await pump(tester, const RecentlyPlayedPage());
      recent.add([_song(5)]);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Clear history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => clear(any()));

      await tester.tap(find.byTooltip('Clear history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      verify(() => clear(any())).called(1);
      expect(find.text('History cleared'), findsOneWidget);
    });

    testWidgets('a failed clear says so', (tester) async {
      when(
        () => clear(any()),
      ).thenAnswer((_) async => const Left(LibraryFailure('Could not save')));
      await pump(tester, const RecentlyPlayedPage());
      recent.add([_song(5)]);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Clear history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Could not save'), findsOneWidget);
    });

    testWidgets('empty history: a message, and nothing to clear', (
      tester,
    ) async {
      await pump(tester, const RecentlyPlayedPage());
      recent.add(const []);
      await tester.pumpAndSettle();

      expect(find.text('Nothing played yet'), findsOneWidget);
      final button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.delete_sweep_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNull);
    });
  });

  test('total length reads naturally', () {
    expect(formatTotalDuration(Duration.zero), '0 min');
    expect(formatTotalDuration(const Duration(seconds: 20)), '1 min');
    expect(formatTotalDuration(const Duration(minutes: 48)), '48 min');
    expect(formatTotalDuration(const Duration(hours: 2)), '2 hr');
    expect(
      formatTotalDuration(const Duration(hours: 2, minutes: 14)),
      '2 hr 14 min',
    );
  });
}
