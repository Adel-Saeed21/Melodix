import 'package:melodix/features/lyrics/presentation/logic/lyrics_cubit.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';

import '../../support/landscape.dart';

import 'package:melodix/core/widgets/app_screen_util_init.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/pages/now_playing_page.dart';
import 'package:melodix/features/player/presentation/widgets/mini_player.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/lyrics/domain/entities/lyrics.dart';
import 'package:melodix/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

import 'player_fixtures.dart';

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

class MockActions extends Mock implements SongActionsCubit {}

class MockLibraryBloc extends Mock implements MusicLibraryBloc {}

NowPlaying _playing({
  String? queueTitle = 'Road trip',
  bool isPlaying = true,
  bool hasNext = true,
  bool hasPrevious = true,
  PlaybackRepeat repeat = PlaybackRepeat.off,
}) => NowPlaying(
  queue: [
    playerSong(1, title: 'Bad Guy'),
    playerSong(2),
  ],
  queueTitle: queueTitle,
  currentIndex: 0,
  isPlaying: isPlaying,
  duration: const Duration(minutes: 4, seconds: 15),
  hasNext: hasNext,
  hasPrevious: hasPrevious,
  repeatMode: repeat,
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
      // As in the app (the lyrics tests register their LyricsRepository).
      ..registerFactory<LyricsCubit>(
        () => LyricsCubit(getIt<LyricsRepository>()),
      )
      ..registerFactory<SongActionsCubit>(() {
        final actions = MockActions();
        when(() => actions.state).thenReturn(null);
        // The full player's ♥ follows the song's live favourite flag.
        when(() => actions.watchFavorite(any()))
            .thenAnswer((_) => Stream.value(false));
        when(() => actions.stream).thenAnswer((_) => const Stream.empty());
        when(() => actions.close()).thenAnswer((_) async {});
        when(() => actions.canDeleteSongs).thenReturn(true);
        return actions;
      });
  });

  tearDown(() => getIt.reset());

  /// Widget tests run on a fake clock: the fake player must be created
  /// inside the test so its stream events are delivered by `pump()`.
  void playerTest(String description, WidgetTesterCallback body) {
    testWidgets(description, (tester) async {
      harness = PlayerHarness();
      addTearDown(harness.dispose);
      await body(tester);
    });
  }

  Future<void> pumpApp(WidgetTester tester, Widget child) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: harness.provide(
          MaterialApp(theme: AppTheme.darkTheme, home: child),
        ),
      ),
    );
    await tester.pump();
  }

  /// Lets a bottom sheet open. Not "settle": the playing song in it shows
  /// equalizer bars that never stop moving.
  Future<void> openedSheet(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('MiniPlayer', () {
    var expanded = 0;
    Widget mini() => Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: MiniPlayer(onExpand: () => expanded++),
      ),
    );

    setUp(() => expanded = 0);

    group('other designs (chosen in Settings)', () {
      Widget styled(MiniPlayerStyle style) => UiPreferencesScope(
        preferences: UiPreferences(miniPlayer: style),
        child: mini(),
      );

      for (final style in [MiniPlayerStyle.capsule, MiniPlayerStyle.minimal]) {
        playerTest('${style.name}: shows the song; play and next work; '
            'a tap opens the player', (tester) async {
          await pumpApp(tester, styled(style));
          harness
            ..states.add(_playing())
            ..tick(const Duration(minutes: 1, seconds: 35));
          await tester.pumpAndSettle();

          expect(find.text('Bad Guy'), findsOneWidget);
          expect(find.text('Artist 1'), findsOneWidget);
          // Not the classic card: no seek bar row or queue button.
          expect(find.byTooltip('Open queue'), findsNothing);

          await tester.tap(find.byTooltip('Pause'));
          await tester.tap(find.byTooltip('Next'));
          await tester.pump();
          verify(() => harness.controls.pause()).called(1);
          verify(() => harness.controls.next()).called(1);

          await tester.tap(find.text('Bad Guy'));
          expect(expanded, 1);
        });
      }

      playerTest('capsule: the ring shows how far the song is', (tester) async {
        await pumpApp(tester, styled(MiniPlayerStyle.capsule));
        harness
          ..states.add(_playing())
          ..tick(const Duration(minutes: 1, seconds: 35));
        await tester.pumpAndSettle();
        final ring = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        // 1:35 of 4:15.
        expect(ring.value, closeTo(95 / 255, 0.01));
      });

      playerTest('minimal: the line shows how far, and ⏮ is there', (
        tester,
      ) async {
        await pumpApp(tester, styled(MiniPlayerStyle.minimal));
        harness
          ..states.add(_playing())
          ..tick(const Duration(minutes: 1, seconds: 35));
        await tester.pumpAndSettle();
        final line = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(line.value, closeTo(95 / 255, 0.01));
        await tester.tap(find.byTooltip('Previous'));
        verify(() => harness.controls.previous()).called(1);
      });
    });

    playerTest('is hidden until a song is loaded', (tester) async {
      await pumpApp(tester, mini());
      expect(find.byTooltip('Play'), findsNothing);

      harness
        ..states.add(_playing())
        ..tick(const Duration(minutes: 1, seconds: 35));
      await tester.pumpAndSettle();

      expect(find.text('Bad Guy'), findsOneWidget);
      expect(find.text('Artist 1'), findsOneWidget);
      expect(find.text('01:35 / -02:40'), findsOneWidget);
    });

    playerTest('leaves the title enough room on a phone-width screen', (
      tester,
    ) async {
      await pumpApp(tester, mini());
      harness.states.add(_playing());
      await tester.pumpAndSettle();

      // A typical title fits without scrolling (one copy, not two).
      expect(find.text('Bad Guy'), findsOneWidget);
      final titleBox = tester.getSize(
        find
            .ancestor(of: find.text('Bad Guy'), matching: find.byType(Column))
            .first,
      );
      expect(titleBox.width, greaterThan(120));
    });

    playerTest('controls drive the player', (tester) async {
      await pumpApp(tester, mini());
      harness.states.add(_playing());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Pause'));
      await tester.tap(find.byTooltip('Next'));
      await tester.tap(find.byTooltip('Previous'));
      await tester.tap(find.byTooltip('Repeat off'));
      await tester.pump();

      verify(() => harness.controls.pause()).called(1);
      verify(() => harness.controls.next()).called(1);
      verify(() => harness.controls.previous()).called(1);
      verify(() => harness.controls.setRepeatMode(PlaybackRepeat.all))
          .called(1);
    });

    playerTest('stop is gone; the queue button opens the queue', (
      tester,
    ) async {
      await pumpApp(tester, mini());
      harness.states.add(_playing());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Stop'), findsNothing);
      await tester.tap(find.byTooltip('Open queue'));
      await openedSheet(tester);

      expect(find.text('Playing from'), findsOneWidget);
      expect(find.text('Road trip'), findsOneWidget);
      expect(find.text('2 songs'), findsOneWidget);
      // Current song is marked; tapping another jumps to it.
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
      await tester.tap(find.text('Song 2'));
      verify(() => harness.controls.skipToIndex(1)).called(1);
    });

    playerTest('the queue falls back to a generic title', (tester) async {
      await pumpApp(tester, mini());
      harness.states.add(_playing(queueTitle: null));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open queue'));
      await openedSheet(tester);

      expect(find.text('Queue'), findsOneWidget);
    });

    playerTest('next / previous are disabled when unavailable', (tester) async {
      await pumpApp(tester, mini());
      harness
        ..states.add(_playing(hasNext: false, hasPrevious: false))
        ..tick(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      IconButton button(String tooltip) => tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );
      expect(button('Next').onPressed, isNull);
      expect(button('Previous').onPressed, isNull);
    });

    playerTest('the ^ button and the song open the full player', (
      tester,
    ) async {
      await pumpApp(tester, mini());
      harness.states.add(_playing());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open player'));
      await tester.tap(find.text('Artist 1'));
      expect(expanded, 2);
    });

    playerTest('shows replay once the queue has finished', (tester) async {
      await pumpApp(tester, mini());
      harness.states.add(
        NowPlaying(
          queue: [playerSong(1)],
          currentIndex: 0,
          isCompleted: true,
          duration: const Duration(minutes: 3),
        ),
      );
      harness.tick(
        const Duration(minutes: 3),
        duration: const Duration(minutes: 3),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
      await tester.tap(find.byTooltip('Play'));
      verify(() => harness.controls.play()).called(1);
    });
  });

  group('NowPlayingPage', () {
    playerTest('lyrics: none on the phone, found online, follow the song', (
      tester,
    ) async {
      final lyrics = _Lyrics();
      getIt.registerSingleton<LyricsRepository>(lyrics);
      harness
        ..states.add(_playing())
        ..tick(const Duration(seconds: 6));
      await pumpApp(tester, const NowPlayingPage());
      await tester.pump();

      await tester.tap(find.byTooltip('Show lyrics'));
      await tester.pump(); // asks for the lyrics
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text('No lyrics on your phone for this song'),
        findsOneWidget,
      );

      await tester.tap(find.text('Search online'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Second line'), findsOneWidget);
      expect(find.text('Lyrics from LRCLIB'), findsOneWidget);
      // The line being sung (6 s in) is the accent's colour.
      final sung = tester.widget<AnimatedDefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Second line'),
              matching: find.byType(AnimatedDefaultTextStyle),
            )
            .first, // the line's own (not the page's)
      );
      expect(sung.style.color, AppTheme.darkTheme.primaryColor);

      // A tap on a line jumps there.
      await tester.tap(find.text('First line'));
      verify(() => harness.controls.seek(const Duration(seconds: 1))).called(1);

      // Back to the cover.
      await tester.tap(find.byTooltip('Show cover'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SongArtwork), findsOneWidget);
    });

    playerTest('sleep timer: picked from Now Playing, counts down', (
      tester,
    ) async {
      harness.states.add(_playing());
      await pumpApp(tester, const NowPlayingPage());
      await tester.pump();

      await tester.tap(find.byTooltip('Sleep timer'));
      await openedSheet(tester);
      await tester.tap(find.text('15 min'));
      await openedSheet(tester); // the sheet closes; a second goes by
      expect(
        harness.sleepTimer.state.remaining,
        const Duration(minutes: 14, seconds: 59),
      );
      expect(find.text('14:59'), findsOneWidget); // on the button
      harness.sleepTimer.cancel();
    });

    playerTest('rotating the phone: fits sideways, and back', (tester) async {
      harness
        ..states.add(_playing())
        ..tick(const Duration(minutes: 1, seconds: 35));
      await pumpApp(tester, const NowPlayingPage());
      await tester.pump();

      await turnSideways(tester);
      expect(find.text('Bad Guy'), findsOneWidget);
      expect(find.byTooltip('Next'), findsOneWidget);
      // The cover on the left, as tall as the screen allows (not squeezed
      // to nothing above the controls).
      final cover = tester.getRect(find.byType(SongArtwork));
      final controls = tester.getRect(find.byTooltip('Next'));
      expect(cover.height, greaterThan(250));
      expect(cover.right, lessThan(controls.left));

      await turnUpright(tester);
      expect(find.text('Bad Guy'), findsOneWidget);
      // Back above the controls.
      expect(
        tester.getRect(find.byType(SongArtwork)).bottom,
        lessThan(tester.getRect(find.byTooltip('Next')).top),
      );
    });

    playerTest('shows the current song and stays in sync', (tester) async {
      harness
        ..states.add(_playing())
        ..tick(const Duration(minutes: 1, seconds: 35));
      await pumpApp(tester, const NowPlayingPage());
      await tester.pump();

      expect(find.text('Now playing'), findsOneWidget);
      expect(find.text('Bad Guy'), findsOneWidget);
      expect(find.text('01:35'), findsOneWidget);
      expect(find.text('-02:40'), findsOneWidget);

      // The player moves on: the page follows.
      harness.tick(const Duration(minutes: 2, seconds: 25));
      await tester.pump(); // deliver the new state
      await tester.pump(); // rebuild
      expect(find.text('02:25'), findsOneWidget);
    });

    playerTest('controls drive the same player', (tester) async {
      harness.states.add(_playing(isPlaying: false));
      await pumpApp(tester, const NowPlayingPage());
      await tester.pump();

      await tester.tap(find.byTooltip('Play'));
      await tester.tap(find.byTooltip('Shuffle'));
      await tester.tap(find.byTooltip('Next'));
      await tester.pump();

      verify(() => harness.controls.play()).called(1);
      verify(() => harness.controls.setShuffle(true)).called(1);
      verify(() => harness.controls.next()).called(1);
    });

    playerTest('pulling the page down returns to the previous screen', (
      tester,
    ) async {
      harness.states.add(_playing());
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        AppScreenUtilInit(
          child: harness.provide(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NowPlayingPage(),
                      ),
                    ),
                    child: const Text('home'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('home'));
      await tester.pumpAndSettle();
      expect(find.text('Now playing'), findsOneWidget);

      await tester.drag(find.text('Now playing'), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.text('Now playing'), findsNothing);
      expect(find.text('home'), findsOneWidget);
      // Playback keeps going; only the page closed.
      verifyNever(() => harness.controls.pause());
    });

    playerTest('has a Queue button instead of Stop', (tester) async {
      harness.states.add(_playing());
      await pumpApp(tester, const NowPlayingPage());
      await tester.pump();

      expect(find.text('Stop'), findsNothing);
      await tester.tap(find.text('Queue'));
      await openedSheet(tester);
      expect(find.text('Playing from'), findsOneWidget);
    });

    playerTest('closes itself when nothing is loaded', (tester) async {
      harness.states.add(_playing());
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        AppScreenUtilInit(
          child: harness.provide(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NowPlayingPage(),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Now playing'), findsOneWidget);

      harness.states.add(NowPlaying.idle);
      await tester.pumpAndSettle();
      expect(find.text('Now playing'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });
}

/// No lyrics on the phone; LRCLIB has synced ones.
class _Lyrics implements LyricsRepository {
  @override
  Future<Lyrics?> local(Song song) async => null;

  @override
  Future<Either<Failure, Lyrics?>> searchOnline(Song song) async => const Right(
    Lyrics(
      lines: [
        LyricLine('First line', time: Duration(seconds: 1)),
        LyricLine('Second line', time: Duration(seconds: 5)),
        LyricLine('Third line', time: Duration(seconds: 9)),
      ],
      source: LyricsSource.online,
    ),
  );

  @override
  Future<void> forgetSaved(int songId) async {}
}
