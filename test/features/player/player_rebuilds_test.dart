import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/player/presentation/pages/now_playing_page.dart';
import 'package:melodix/features/player/presentation/utils/player_rebuild_stats.dart';
import 'package:melodix/features/player/presentation/widgets/mini_player.dart';
import 'package:mocktail/mocktail.dart';

import 'player_fixtures.dart';

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

class MockActions extends Mock implements SongActionsCubit {}

class MockLibraryBloc extends Mock implements MusicLibraryBloc {}

final _queue = [playerSong(1, title: 'Bad Guy'), playerSong(2)];

NowPlaying _at(Duration position, {int index = 0, bool playing = true}) =>
    NowPlaying(
      queue: _queue,
      currentIndex: index,
      isPlaying: playing,
      position: position,
      duration: const Duration(minutes: 4, seconds: 15),
      hasNext: true,
      hasPrevious: true,
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
    final library = MockLibraryBloc();
    when(() => library.state).thenReturn(const MusicLibraryState());
    when(() => library.stream).thenAnswer((_) => const Stream.empty());
    getIt
      ..registerSingleton<GetSongArtworkUseCase>(artwork)
      ..registerSingleton<MusicLibraryBloc>(library)
      ..registerFactory<SongActionsCubit>(() {
        final actions = MockActions();
        when(() => actions.state).thenReturn(null);
        when(() => actions.stream).thenAnswer((_) => const Stream.empty());
        when(() => actions.close()).thenAnswer((_) async {});
        when(() => actions.canDeleteSongs).thenReturn(true);
        return actions;
      });
  });

  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester, Widget child) async {
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
          child: MaterialApp(theme: AppTheme.darkTheme, home: child),
        ),
      ),
    );
  }

  /// Sends [ticks] position-only updates (1 s apart) and returns the build
  /// counts they caused.
  Future<Map<String, int>> measureTicks(WidgetTester tester, int ticks) async {
    harness.states.add(_at(const Duration(seconds: 10)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // settle entry
    PlayerRebuildStats.reset();
    for (var i = 1; i <= ticks; i++) {
      harness.states.add(_at(Duration(seconds: 10 + i)));
      await tester.pump();
      await tester.pump();
    }
    return Map.of(PlayerRebuildStats.counts);
  }

  Widget mini() => Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: MiniPlayer(onExpand: () {}),
    ),
  );

  group('position ticks rebuild only progress widgets', () {
    // Baseline before the optimisation (same measurement): every tick
    // rebuilt the whole card / page body and re-measured the title
    // ({miniCard: 10, seekBar: 10, marqueeMeasure: 10} for 10 ticks).
    testWidgets('mini player', (tester) async {
      await pump(tester, mini());
      final counts = await measureTicks(tester, 10);

      expect(counts['miniCard'] ?? 0, 0);
      expect(counts['marqueeMeasure'] ?? 0, 0);
      expect(counts['seekBar'], 10); // the seek bar does follow every tick
      expect(find.text('00:20 / -03:55'), findsOneWidget); // label updated
    });

    testWidgets('now playing page', (tester) async {
      await pump(tester, const NowPlayingPage());
      final counts = await measureTicks(tester, 10);

      expect(counts['nowPlayingBody'] ?? 0, 0);
      expect(counts['marqueeMeasure'] ?? 0, 0);
      expect(counts['seekBar'], 10);
      expect(find.text('00:20'), findsOneWidget);
      expect(find.text('-03:55'), findsOneWidget);
    });
  });

  testWidgets('a song change still rebuilds the card and the title', (
    tester,
  ) async {
    await pump(tester, mini());
    await measureTicks(tester, 1);
    PlayerRebuildStats.reset();

    harness.states.add(_at(const Duration(seconds: 1), index: 1));
    await tester.pump();
    await tester.pump();

    expect(PlayerRebuildStats.of('miniCard'), greaterThan(0));
    expect(PlayerRebuildStats.of('marqueeMeasure'), greaterThan(0));
    expect(find.text('Song 2'), findsOneWidget);
    expect(find.text('Bad Guy'), findsNothing);
  });

  testWidgets('play/pause changes still update the card', (tester) async {
    await pump(tester, mini());
    await measureTicks(tester, 1);
    expect(find.byTooltip('Pause'), findsOneWidget);

    harness.states.add(_at(const Duration(seconds: 11), playing: false));
    await tester.pump();
    await tester.pump();

    expect(find.byTooltip('Play'), findsOneWidget);
  });

  testWidgets('previous enables exactly when the 3 s restart point passes', (
    tester,
  ) async {
    await pump(tester, mini());
    IconButton previous() => tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Previous'),
        matching: find.byType(IconButton),
      ),
    );
    NowPlaying firstSong(Duration position) => NowPlaying(
      queue: _queue,
      currentIndex: 0,
      isPlaying: true,
      position: position,
      duration: const Duration(minutes: 4),
      hasNext: true,
    );

    harness.states.add(firstSong(const Duration(seconds: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(previous().onPressed, isNull);

    harness.states.add(firstSong(const Duration(seconds: 4)));
    await tester.pump();
    await tester.pump();
    expect(previous().onPressed, isNotNull);

    await tester.tap(find.byTooltip('Previous'));
    verify(() => harness.controls.previous()).called(1);
  });

  testWidgets('dragging the seek bar still seeks', (tester) async {
    await pump(tester, const NowPlayingPage());
    await measureTicks(tester, 1);

    final slider = find.byType(Slider);
    await tester.drag(slider, const Offset(-2000, 0)); // to the very start
    await tester.pumpAndSettle();

    final seeked =
        verify(() => harness.controls.seek(captureAny())).captured.single
            as Duration;
    expect(seeked, Duration.zero);
  });
}
