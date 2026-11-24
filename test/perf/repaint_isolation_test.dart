import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/navigation/presentation/widgets/glass_nav_bar.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/widgets/equalizer_bars.dart';
import 'package:melodix/features/player/presentation/widgets/marquee_text.dart';
import 'package:melodix/features/player/presentation/widgets/mini_player.dart';
import 'package:melodix/features/player/presentation/widgets/player_progress.dart';
import 'package:mocktail/mocktail.dart';

import '../features/player/player_fixtures.dart';
import 'paint_counter.dart';

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

NowPlaying _song({bool playing = true}) => NowPlaying(
  queue: _queue,
  currentIndex: 0,
  isPlaying: playing,
  duration: const Duration(minutes: 4),
  hasNext: true,
  hasPrevious: true,
);
final _queue = [
  playerSong(1, title: 'A very long song title that will scroll for sure'),
];

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
    getIt.registerSingleton<GetSongArtworkUseCase>(artwork);
  });

  tearDown(() => getIt.reset());

  /// Pumps [widget] with a [PaintCounter] sibling (no boundary between
  /// them) and returns the counter.
  Future<PaintCount> pumpWithNeighbour(
    WidgetTester tester,
    Widget widget,
  ) async {
    harness = PlayerHarness();
    addTearDown(harness.dispose);
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final counter = PaintCount();
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: harness.provide(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget,
                  PaintCounter(counter: counter),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    harness
      ..states.add(_song())
      ..tick(const Duration(seconds: 10), duration: const Duration(minutes: 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return counter;
  }

  Future<int> neighbourPaintsDuringTicks(
    WidgetTester tester,
    PaintCount counter,
  ) async {
    counter.value = 0;
    for (var i = 1; i <= 10; i++) {
      // A position tick only: the player state stays the same.
      harness.tick(
        Duration(seconds: 10 + i),
        duration: const Duration(minutes: 4),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    }
    return counter.value;
  }

  Future<int> neighbourPaintsDuringAnimation(
    WidgetTester tester,
    PaintCount counter,
  ) async {
    counter.value = 0;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100)); // 3 s of frames
    }
    return counter.value;
  }

  // Baseline before isolating repaints (same measurements, neighbour
  // repaints): mini player 20 per 10 ticks and 30 per 3 s of scrolling title,
  // seek bar 10, time label 10, scrolling title 30, equalizer 30, and a bottom
  // bar under an animating page 30.

  testWidgets('mini player ticks and title scrolling stay in their layer', (
    tester,
  ) async {
    final c = await pumpWithNeighbour(tester, MiniPlayer(onExpand: () {}));
    expect(await neighbourPaintsDuringTicks(tester, c), 0);
    expect(await neighbourPaintsDuringAnimation(tester, c), 0);
  });

  testWidgets('a paused mini player does not repaint its neighbours', (
    tester,
  ) async {
    final c = await pumpWithNeighbour(tester, MiniPlayer(onExpand: () {}));
    harness
      ..states.add(_song(playing: false))
      ..tick(const Duration(seconds: 30), duration: const Duration(minutes: 4));
    await tester.pump();
    await tester.pump();
    expect(await neighbourPaintsDuringAnimation(tester, c), 0);
  });

  testWidgets('seek bar and time label updates stay in their layer', (
    tester,
  ) async {
    var c = await pumpWithNeighbour(tester, const PlayerSeekBar());
    expect(await neighbourPaintsDuringTicks(tester, c), 0);

    c = await pumpWithNeighbour(
      tester,
      const ElapsedRemainingLabel(style: TextStyle()),
    );
    expect(await neighbourPaintsDuringTicks(tester, c), 0);
    expect(find.text('00:20 / -03:40'), findsOneWidget); // still updates
  });

  testWidgets('scrolling title and equalizer animate in their own layer', (
    tester,
  ) async {
    var c = await pumpWithNeighbour(
      tester,
      const SizedBox(
        width: 120,
        child: MarqueeText('A very long song title that will scroll for sure'),
      ),
    );
    expect(await neighbourPaintsDuringAnimation(tester, c), 0);

    c = await pumpWithNeighbour(
      tester,
      const EqualizerBars(animate: true, color: Colors.green),
    );
    expect(await neighbourPaintsDuringAnimation(tester, c), 0);
  });

  testWidgets('page animations do not repaint the glass nav bar', (
    tester,
  ) async {
    // Control: an unprotected bottom bar is repainted on every frame.
    final bottom = PaintCount();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBody: true,
          body: const Center(child: LinearProgressIndicator()),
          bottomNavigationBar: PaintCounter(counter: bottom),
        ),
      ),
    );
    bottom.value = 0;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(bottom.value, greaterThan(20));

    // The real glass nav bar keeps its own layer.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBody: true,
          body: const Center(child: LinearProgressIndicator()),
          bottomNavigationBar: GlassNavBar(
            items: const [
              GlassNavItem(
                icon: Icons.music_note,
                activeIcon: Icons.music_note,
                label: 'Music',
              ),
              GlassNavItem(
                icon: Icons.settings,
                activeIcon: Icons.settings,
                label: 'Settings',
              ),
            ],
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final navLayer = tester.renderObject<RenderRepaintBoundary>(
      find
          .descendant(
            of: find.byType(GlassNavBar),
            matching: find.byType(RepaintBoundary),
          )
          .first,
    );
    int paints() =>
        navLayer.debugSymmetricPaintCount + navLayer.debugAsymmetricPaintCount;
    final before = paints();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(paints() - before, 0);
    expect(find.text('Music'), findsOneWidget); // still shown
  });
}
