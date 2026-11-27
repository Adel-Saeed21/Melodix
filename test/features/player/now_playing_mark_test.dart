import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/core/widgets/equalizer_bars.dart';
import 'package:mocktail/mocktail.dart';

import 'player_fixtures.dart';

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

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

  /// Set by [usePlayer]: the tiles get a player above them, like in the app.
  PlayerHarness? player;
  setUp(() => player = null);

  Future<void> pumpList(WidgetTester tester, {bool reduceMotion = false}) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(tester.view)
            .copyWith(disableAnimations: reduceMotion),
        child: AppScreenUtilInit(
          child: _withPlayer(
            player,
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: Column(
                  children: [
                    SongTile(song: playerSong(1, title: 'First')),
                    SongTile(song: playerSong(2, title: 'Second')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Creates the fake player inside the test (fake clock); the next
  /// [pumpList] provides it above the tiles.
  void usePlayer() {
    harness = PlayerHarness();
    addTearDown(harness.dispose);
    player = harness;
  }

  NowPlaying playingSecond({bool isPlaying = true}) => NowPlaying(
    queue: [playerSong(1), playerSong(2)],
    currentIndex: 1,
    isPlaying: isPlaying,
  );

  Color? titleColor(WidgetTester tester, String title) =>
      tester.widget<Text>(find.text(title)).style?.color;

  List<double> barHeights(WidgetTester tester) {
    final bars = find.descendant(
      of: find.byType(EqualizerBars),
      matching: find.byType(Container),
    );
    return [
      for (var i = 0; i < bars.evaluate().length; i++)
        tester.getSize(bars.at(i)).height,
    ];
  }

  testWidgets('without a player no song is marked', (tester) async {
    await pumpList(tester);

    expect(find.byType(EqualizerBars), findsNothing);
  });

  testWidgets('only the current song is marked, and the mark moves', (
    tester,
  ) async {
    usePlayer();
    await pumpList(tester);
    final primary = AppTheme.darkTheme.primaryColor;

    harness.states.add(playingSecond());
    await tester.pump();
    await tester.pump();

    expect(find.byType(EqualizerBars), findsOneWidget);
    expect(titleColor(tester, 'Second'), primary);
    expect(titleColor(tester, 'First'), isNot(primary));

    // Player moves to the first song.
    harness.states.add(
      NowPlaying(
        queue: [playerSong(1), playerSong(2)],
        currentIndex: 0,
        isPlaying: true,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(titleColor(tester, 'First'), primary);
    expect(titleColor(tester, 'Second'), isNot(primary));
  });

  testWidgets('bars move while playing and hold still when paused', (
    tester,
  ) async {
    usePlayer();
    await pumpList(tester);

    harness.states.add(playingSecond());
    await tester.pump();
    await tester.pump();
    final before = barHeights(tester);
    await tester.pump(const Duration(milliseconds: 200));
    expect(barHeights(tester), isNot(before));

    harness.states.add(playingSecond(isPlaying: false));
    await tester.pump();
    await tester.pump();
    final paused = barHeights(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(barHeights(tester), paused);
    expect(find.byType(EqualizerBars), findsOneWidget); // still marked
  });

  testWidgets('reduced motion keeps the bars still', (tester) async {
    usePlayer();
    await pumpList(tester, reduceMotion: true);

    harness.states.add(playingSecond());
    await tester.pump();
    await tester.pump();
    final before = barHeights(tester);
    expect(before.every((h) => h > 0), isTrue);
    await tester.pump(const Duration(milliseconds: 300));

    expect(barHeights(tester), before);
  });
}

Widget _withPlayer(PlayerHarness? player, Widget app) =>
    player == null ? app : player.provide(app);
