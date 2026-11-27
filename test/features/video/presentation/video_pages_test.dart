import 'package:melodix/core/service/system_delete_confirmation.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_transport_buttons.dart';
import 'package:melodix/core/utils/debug_counters.dart';
import 'package:melodix/core/widgets/selection/selection_widgets.dart';
import 'package:melodix/core/widgets/selection/selection_actions_overlay.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_player_controls.dart';
import 'package:melodix/features/video/presentation/widgets/video_tile.dart';
import 'package:flutter/services.dart';
import 'package:melodix/features/video/domain/usecases/video_bulk_usecases.dart';

import '../../../support/landscape.dart';

import 'package:melodix/core/widgets/app_screen_util_init.dart';

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_download.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitles_cubit.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';
import 'package:melodix/features/subtitles/domain/entities/online_subtitle.dart';

import '../../subtitles/subtitle_fixtures.dart';

import 'package:melodix/features/video/presentation/widgets/library/continue_watching_row.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/core/usecase/open_app_settings_usecase.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/entities/video_library_changes.dart';
import 'package:melodix/features/video/domain/usecases/get_video_thumbnail_usecase.dart';
import 'package:melodix/features/video/domain/usecases/sync_video_library_usecase.dart';
import 'package:melodix/features/video/domain/usecases/toggle_video_favorite_usecase.dart';
import 'package:melodix/features/video/domain/usecases/video_permission_usecases.dart';
import 'package:melodix/features/video/domain/usecases/watch_videos_usecase.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';
import 'package:melodix/features/video/presentation/pages/video_page.dart';
import 'package:melodix/features/video/presentation/navigation/video_player_navigation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/mini/mini_video_audio_card.dart';
import 'package:melodix/features/video/presentation/widgets/mini/mini_video_card.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_playing_view.dart';
import 'package:melodix/features/video/presentation/widgets/player/audio_mode/video_audio_view.dart';
import 'package:melodix/features/video/presentation/widgets/mini/mini_video_window.dart';
import 'package:melodix/features/video/presentation/widgets/mini/video_session_host.dart';
import 'package:melodix/features/video/presentation/widgets/mini/picture_in_picture_video.dart';
import 'package:melodix/core/service/picture_in_picture_service.dart';
import 'package:melodix/features/video/presentation/pages/video_player_page.dart';
import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/features/video/domain/usecases/video_progress_usecases.dart';
import 'package:melodix/features/video/domain/usecases/watch_favorite_videos_usecase.dart';
import 'package:melodix/features/video/presentation/logic/favorite_videos_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../video_fixtures.dart';

/// Android's window, faked: records what it's told, and goes in / out of
/// the window on demand.
class FakePip implements PictureInPictureService {
  final calls = <(bool, int, int)>[];
  final _changes = StreamController<bool>.broadcast();

  void enter() => _changes.add(true);
  void leave() => _changes.add(false);

  @override
  Future<bool> isSupported() async => true;

  @override
  Stream<bool> get modeChanges => _changes.stream;

  final _actions = StreamController<PictureInPictureAction>.broadcast();

  /// A tap on one of the window's buttons.
  void tap(PictureInPictureAction action) => _actions.add(action);

  @override
  Stream<PictureInPictureAction> get actions => _actions.stream;

  @override
  Future<void> setAutoEnter({
    required bool enabled,
    bool? playing,
    required int width,
    required int height,
  }) async => calls.add((enabled, width, height));
}

class MockThumbnails extends Mock implements GetVideoThumbnailUseCase {}

class MockWatchVideos extends Mock implements WatchVideosUseCase {}

class MockSync extends Mock implements SyncVideoLibraryUseCase {}

class MockCheck extends Mock implements CheckVideoPermissionUseCase {}

class MockRequest extends Mock implements RequestVideoPermissionUseCase {}

class MockOpenSettings extends Mock implements OpenAppSettingsUseCase {}

class MockToggle extends Mock implements ToggleVideoFavoriteUseCase {}

class MockWatchFavourites extends Mock implements WatchFavoriteVideosUseCase {}

class MockWatchProgress extends Mock implements WatchVideoProgressUseCase {}

class MockSetFavourites extends Mock implements SetVideosFavoriteUseCase {}

class MockDeleteVideos extends Mock implements DeleteVideosUseCase {}

void main() {
  // The app-wide favourites (♥ anywhere): live, and toggled through this.
  late StreamController<List<Video>> favouriteVideos;
  late MockToggle toggle;
  late MockSetFavourites setFavourites;
  late MockDeleteVideos deleteVideos;

  setUpAll(() {
    registerVideoFallbacks();
    registerFallbackValue(const VideoSyncParams());
  });

  setUp(() async {
    await getIt.reset();
    final thumbnails = MockThumbnails();
    when(() => thumbnails(any(), size: any(named: 'size'))).thenReturn(null);
    when(() => thumbnails.cached(any(), size: any(named: 'size')))
        .thenReturn(null);
    getIt.registerSingleton<GetVideoThumbnailUseCase>(thumbnails);
    favouriteVideos = StreamController<List<Video>>.broadcast();
    toggle = MockToggle();
    setFavourites = MockSetFavourites();
    deleteVideos = MockDeleteVideos();
  });

  tearDown(() async {
    await favouriteVideos.close();
    await getIt.reset();
  });

  /// The app's frame: the video session above every page (as in
  /// MelodixApp), with [session] as the app-wide player.
  Future<void> pumpApp(
    WidgetTester tester,
    GoRouter router,
    VideoPlayerCubit session, {
    PictureInPictureService? pip,
    EdgeInsets clearance = MiniVideoWindow.portraitClearance,
    UiPreferences preferences = UiPreferences.defaults,
    FakeSubtitleRepository? subtitles,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final watchFavourites = MockWatchFavourites();
    when(() => watchFavourites()).thenAnswer((_) => favouriteVideos.stream);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: session),
          BlocProvider(
            create: (_) => subtitlesCubitOver(
              subtitles ?? FakeSubtitleRepository(),
              currentVideo: session.stream
                  .map((s) => s.isActive ? s.video.id : null)
                  .distinct(),
              // Created on first use, maybe after the video opened.
              initialVideo: session.state.isActive
                  ? session.state.video.id
                  : null,
            ),
          ),
          RepositoryProvider<DeleteVideosUseCase>.value(value: deleteVideos),
          BlocProvider(
            create: (_) => FavoriteVideosCubit(
              watchFavorites: watchFavourites,
              toggleFavorite: toggle,
              setFavorite: setFavourites,
            ),
          ),
        ],
        child: AppScreenUtilInit(
          child: UiPreferencesScope(
            preferences: preferences,
            child: MaterialApp.router(
              theme: AppTheme.darkTheme,
              routerConfig: router,
              builder: (context, child) => VideoSessionHost(
                pictureInPicture: pip,
                clearance: clearance,
                onExpand: () => router.push<void>(Routes.videoPlayer),
                child: child!,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Takes the app down and ends the (app-wide) session, as on app exit.
  Future<void> finish(WidgetTester tester, VideoPlayerCubit session) async {
    await tester.pumpWidget(const SizedBox());
    // Closing a bloc completes on the real event loop.
    await tester.runAsync(session.close);
    await tester.pump(const Duration(milliseconds: 10));
  }

  group('videos tab', () {
    late VideoPlayerHarness h;
    late VideoPlayerCubit session;
    late StreamController<List<Video>> videos;
    late MockCheck check;
    late MockRequest request;
    late MockSync sync;
    late StreamController<Map<String, VideoProgress>> progress;

    setUp(() {
      h = VideoPlayerHarness();
      session = h.cubit();
      videos = StreamController<List<Video>>.broadcast();
      check = MockCheck();
      request = MockRequest();
      sync = MockSync();
      progress = StreamController<Map<String, VideoProgress>>.broadcast();
      when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
      when(() => sync(any())).thenAnswer(
        (_) async => const Right(
          VideoLibraryChanges(added: 2, updated: 0, removed: 0, total: 2),
        ),
      );
    });

    tearDown(() async {
      await videos.close();
      await progress.close();
      await session.close();
    });

    GoRouter router() {
      final watch = MockWatchVideos();
      when(() => watch()).thenAnswer((_) => videos.stream);
      final watchProgress = MockWatchProgress();
      when(() => watchProgress()).thenAnswer((_) => progress.stream);
      return GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => VideoPage(
              createCubit: () => VideoLibraryCubit(
                watchVideos: watch,
                sync: sync,
                checkPermission: check,
                requestPermission: request,
                openSettings: MockOpenSettings(),
                watchProgress: watchProgress,
                appResumed: const Stream.empty(),
              ),
            ),
          ),
          GoRoute(
            path: Routes.videoPlayer,
            builder: (_, _) => const Text('full player'),
          ),
        ],
      );
    }

    testWidgets('lists the videos; started ones on top', (tester) async {
      await pumpApp(tester, router(), session);
      videos.add([testVideo('a'), testVideo('b')]);
      progress.add({
        'b': watched('b', const Duration(minutes: 3, seconds: 12)),
      });
      await tester.pumpAndSettle();

      expect(find.text('2 videos'), findsOneWidget);
      expect(find.text('Continue watching'), findsOneWidget);
      expect(find.text('All videos'), findsOneWidget);
      expect(find.text('Video a'), findsOneWidget);
      // In "continue watching" and in the list.
      expect(find.text('Video b'), findsNWidgets(2));
      expect(find.text('Resume at 3:12'), findsNWidgets(2));
      expect(find.text('1080p'), findsOneWidget);
    });

    testWidgets('continue watching: time left, progress, resume', (
      tester,
    ) async {
      await pumpApp(tester, router(), session);
      videos.add([testVideo('a'), testVideo('b')]);
      progress.add({
        'b': watched('b', const Duration(minutes: 2, seconds: 30)),
      });
      await tester.pumpAndSettle();

      final row = find.byType(ContinueWatchingRow);
      expect(
        find.descendant(of: row, matching: find.text('7:30 left')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('Resume at 2:30')),
        findsOneWidget,
      );
      final bar = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: row,
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(bar.value, closeTo(0.25, 0.001));

      await tester.tap(
        find.descendant(of: row, matching: find.text('Video b')),
      );
      await tester.pumpAndSettle();
      expect(session.state.video.id, 'b');
      await session.stop();
      await tester.pumpAndSettle();
    });

    testWidgets('the Video tab fits sideways', (tester) async {
      await pumpApp(tester, router(), session);
      videos.add([
        for (final id in ['a', 'b', 'c', 'd']) testVideo(id),
      ]);
      progress.add({'b': watched('b', const Duration(minutes: 3))});
      await tester.pumpAndSettle();
      await turnSideways(tester);
      expect(find.text('Video a'), findsOneWidget);
      await turnUpright(tester);
    });

    testWidgets('progress saved while one plays never redraws the list', (
      tester,
    ) async {
      await pumpApp(tester, router(), session);
      videos.add([testVideo('a'), testVideo('b')]);
      progress.add(const {});
      await tester.pumpAndSettle();
      DebugCounters.reset();

      // Two saves (every 15 s while a video plays).
      progress.add({
        'b': watched('b', const Duration(minutes: 3, seconds: 12)),
      });
      await tester.pumpAndSettle();
      progress.add({
        'b': watched('b', const Duration(minutes: 3, seconds: 27)),
      });
      await tester.pumpAndSettle();

      expect(DebugCounters.of('videoListBuild'), 0);
      // …yet the row (and "Continue watching") show the new place.
      expect(find.text('Resume at 3:27'), findsNWidgets(2));
      expect(find.text('Continue watching'), findsOneWidget);
    });

    testWidgets('a tap plays that video, with the list to move in', (
      tester,
    ) async {
      await pumpApp(tester, router(), session);
      videos.add([testVideo('a'), testVideo('b'), testVideo('c')]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Video b'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('full player'), findsOneWidget);
      expect(session.state.video.id, 'b');
      expect(session.state.queue.map((v) => v.id), ['a', 'b', 'c']);
      await finish(tester, session);
    });

    testWidgets('no access: one button asks; nothing asked before', (
      tester,
    ) async {
      when(() => check()).thenAnswer((_) async => LibraryPermission.denied);
      when(() => request()).thenAnswer((_) async => LibraryPermission.granted);
      await pumpApp(tester, router(), session);
      await tester.pumpAndSettle();

      expect(find.text('Allow access to your videos'), findsOneWidget);
      verifyNever(() => request());

      await tester.tap(find.text('Allow access'));
      videos.add([testVideo('a')]);
      await tester.pumpAndSettle();
      verify(() => request()).called(1);
      expect(find.text('Video a'), findsOneWidget);
    });

    testWidgets('the scan button says what it found', (tester) async {
      await pumpApp(tester, router(), session);
      videos.add([testVideo('a')]);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Scan for videos'));
      await tester.pump();
      await tester.pump();
      expect(find.text('2 new videos'), findsOneWidget);
    });

    testWidgets('♥ on a row favourites it', (tester) async {
      when(() => toggle('a')).thenAnswer((_) async => const Right(true));
      await pumpApp(tester, router(), session);
      videos.add([testVideo('a')]);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add to favourites'));
      favouriteVideos.add([testVideo('a', favorite: true)]);
      await tester.pump();
      await tester.pump();
      verify(() => toggle('a')).called(1);
      // Same feedback as everywhere: what happened, with Undo.
      expect(find.text('Added to favourites'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.byTooltip('Remove from favourites'), findsOneWidget);
    });

    group('⋮ on a video', () {
      Future<void> openMenu(WidgetTester tester, String title) async {
        await tester.tap(
          find.descendant(
            of: find.ancestor(
              of: find.text(title),
              matching: find.byType(VideoTile),
            ),
            matching: find.byTooltip('Video options'),
          ),
        );
        await tester.pumpAndSettle();
      }

      testWidgets('play as audio: just that video, listened to', (
        tester,
      ) async {
        await pumpApp(tester, router(), session);
        videos.add([testVideo('a'), testVideo('b')]);
        await tester.pumpAndSettle();

        await openMenu(tester, 'Video b');
        await tester.tap(find.text('Play as audio'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('full player'), findsOneWidget);
        expect(session.state.video.id, 'b');
        expect(session.state.queue, hasLength(1));
        expect(session.state.audioOnly, isTrue);
        await finish(tester, session);
      });

      testWidgets('play next with nothing playing: plays it now', (
        tester,
      ) async {
        await pumpApp(tester, router(), session);
        videos.add([testVideo('a'), testVideo('b')]);
        await tester.pumpAndSettle();

        await openMenu(tester, 'Video b');
        await tester.tap(find.text('Play next'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('full player'), findsOneWidget);
        expect(session.state.video.id, 'b');
        await finish(tester, session);
      });

      testWidgets('add to queue while one plays: added, and says so', (
        tester,
      ) async {
        await pumpApp(tester, router(), session);
        videos.add([testVideo('a'), testVideo('b')]);
        await tester.pumpAndSettle();
        await tester.runAsync(() => session.open([testVideo('a')], 0));
        await tester.pump();

        await openMenu(tester, 'Video b');
        await tester.tap(find.text('Add to queue'));
        await tester.pump();
        expect(find.text('Added to queue'), findsOneWidget);
        expect(session.state.queue.map((v) => v.id), ['a', 'b']);
        expect(session.state.video.id, 'a'); // still playing a
        await finish(tester, session);
      });

      testWidgets('delete from phone: asks, then deletes', (tester) async {
        when(() => deleteVideos(any()))
            .thenAnswer((_) async => const Right(['b']));
        await pumpApp(tester, router(), session);
        videos.add([testVideo('a'), testVideo('b')]);
        await tester.pumpAndSettle();

        await openMenu(tester, 'Video b');
        await tester.tap(find.text('Delete from phone'));
        await tester.pumpAndSettle();
        expect(find.text('Delete this video?'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Delete'));
        await tester.pump();
        await tester.pump();
        verify(() => deleteVideos(['b'])).called(1);
        expect(find.text('Deleted 1 video'), findsOneWidget);
      });

      testWidgets('delete from phone on Android 11+: only the system asks', (
        tester,
      ) async {
        SystemDeleteConfirmation.debugOverride(true);
        addTearDown(() => SystemDeleteConfirmation.debugOverride(null));
        when(() => deleteVideos(any()))
            .thenAnswer((_) async => const Right(['b']));
        await pumpApp(tester, router(), session);
        videos.add([testVideo('a'), testVideo('b')]);
        await tester.pumpAndSettle();

        await openMenu(tester, 'Video b');
        await tester.tap(find.text('Delete from phone'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Delete this video?'), findsNothing);
        verify(() => deleteVideos(['b'])).called(1);
        expect(find.text('Deleted 1 video'), findsOneWidget);
      });
    });

    group('multi-select', () {
      Future<void> showVideos(WidgetTester tester) async {
        await pumpApp(tester, router(), session);
        videos.add([testVideo('a'), testVideo('b'), testVideo('c')]);
        await tester.pumpAndSettle();
      }

      testWidgets('long-press selects; select all; back leaves selection', (
        tester,
      ) async {
        await showVideos(tester);
        await tester.longPress(find.text('Video b'));
        await tester.pumpAndSettle();
        expect(find.text('1 selected'), findsOneWidget);

        await tester.tap(find.text('Video c')); // a tap now adds
        await tester.pumpAndSettle();
        expect(find.text('2 selected'), findsOneWidget);

        await tester.tap(find.text('Select all'));
        await tester.pumpAndSettle();
        expect(find.text('3 selected'), findsOneWidget);

        // Back leaves selection mode (the page stays).
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('3 selected'), findsNothing);
        expect(find.text('All videos'), findsOneWidget);
        expect(find.text('Video a'), findsOneWidget);
      });

      testWidgets('the right-side design (Settings): a vertical bar', (
        tester,
      ) async {
        await pumpApp(
          tester,
          router(),
          session,
          preferences: const UiPreferences(
            selectionBar: SelectionBarStyle.side,
          ),
        );
        videos.add([testVideo('a'), testVideo('b'), testVideo('c')]);
        await tester.pumpAndSettle();
        await tester.longPress(find.text('Video a'));
        await tester.pumpAndSettle();

        expect(find.byType(SideActionBar), findsOneWidget);
        expect(find.byType(BulkActionBar), findsNothing);
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        final bar = tester.getRect(find.byType(SideActionBar));
        expect(bar.right, greaterThan(screen.width - 40)); // on the right
        expect(bar.height, greaterThan(bar.width)); // standing up
        // The same actions, one above the other.
        final play = tester.getCenter(find.text('Play'));
        final delete = tester.getCenter(find.text('Delete'));
        expect(delete.dy, greaterThan(play.dy));
        expect(delete.dx, closeTo(play.dx, 1));
        await tester.tap(find.text('Play'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(session.state.video.id, 'a');
        await finish(tester, session);
      });

      testWidgets('the select icon starts selection; a tap no longer plays', (
        tester,
      ) async {
        await showVideos(tester);
        await tester.tap(find.byTooltip('Select videos'));
        await tester.pumpAndSettle();
        expect(find.text('0 selected'), findsOneWidget);

        await tester.tap(find.text('Video a'));
        await tester.pumpAndSettle();
        expect(find.text('1 selected'), findsOneWidget);
        expect(find.text('full player'), findsNothing);
      });

      testWidgets('play: the selected videos, as a list', (tester) async {
        await showVideos(tester);
        await tester.longPress(find.text('Video c'));
        await tester.tap(find.text('Video a'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Play'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('full player'), findsOneWidget);
        // In list order, starting from the first.
        expect(session.state.queue.map((v) => v.id), ['a', 'c']);
        expect(session.state.video.id, 'a');
        await finish(tester, session);
      });

      testWidgets('favourite them all at once', (tester) async {
        when(() => setFavourites(any(), favorite: any(named: 'favorite')))
            .thenAnswer((_) async => const Right(unit));
        await showVideos(tester);
        await tester.longPress(find.text('Video a'));
        await tester.tap(find.text('Video b'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Favourite'));
        await tester.pump();
        await tester.pump();
        verify(() => setFavourites(['a', 'b'], favorite: true)).called(1);
        expect(find.text('Added to favourites'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 300)); // header fades
        expect(find.text('2 selected'), findsNothing); // done: selection ends
      });

      testWidgets('delete: asks, deletes, says how many', (tester) async {
        when(() => deleteVideos(any()))
            .thenAnswer((_) async => const Right(['a', 'b']));
        await showVideos(tester);
        await tester.longPress(find.text('Video a'));
        await tester.tap(find.text('Video b'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(find.text('Delete 2 videos?'), findsOneWidget);
        verifyNever(() => deleteVideos(any())); // not before it's confirmed

        await tester.tap(find.widgetWithText(TextButton, 'Delete'));
        await tester.pump();
        await tester.pump();
        verify(() => deleteVideos(['a', 'b'])).called(1);
        expect(find.text('Deleted 2 videos'), findsOneWidget);
      });

      testWidgets('delete on Android 11+: straight to the system dialog', (
        tester,
      ) async {
        SystemDeleteConfirmation.debugOverride(true);
        addTearDown(() => SystemDeleteConfirmation.debugOverride(null));
        when(() => deleteVideos(any()))
            .thenAnswer((_) async => const Right(['a', 'b']));
        await showVideos(tester);
        await tester.longPress(find.text('Video a'));
        await tester.tap(find.text('Video b'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Delete 2 videos?'), findsNothing);
        verify(() => deleteVideos(['a', 'b'])).called(1);
        expect(find.text('Deleted 2 videos'), findsOneWidget);
      });

      testWidgets('delete, then "no" in the system dialog: nothing gone', (
        tester,
      ) async {
        when(() => deleteVideos(any()))
            .thenAnswer((_) async => const Right(<String>[]));
        await showVideos(tester);
        await tester.longPress(find.text('Video a'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Delete'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Nothing was deleted'), findsOneWidget);
        expect(find.text('1 selected'), findsOneWidget); // still selected
      });
    });

    testWidgets('♥ changed elsewhere shows here at once', (tester) async {
      await pumpApp(tester, router(), session);
      videos.add([testVideo('a')]);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Add to favourites'), findsOneWidget);

      favouriteVideos.add([testVideo('a', favorite: true)]);
      await tester.pump();
      await tester.pump();
      expect(find.byTooltip('Remove from favourites'), findsOneWidget);
    });
  });

  group('player', () {
    late VideoPlayerHarness h;
    late VideoPlayerCubit session;
    late FakePip pip;

    GoRouter router(List<Video> queue, int index) => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => openVideoPlayer(context, queue, index),
                  child: const Text('open'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: Routes.videoPlayer,
          builder: (_, _) => const VideoPlayerPage(),
        ),
      ],
    );

    Future<void> open(
      WidgetTester tester,
      List<Video> queue, [
      int index = 0,
      UiPreferences preferences = UiPreferences.defaults,
      FakeSubtitleRepository? subtitles,
    ]) async {
      await pumpApp(
        tester,
        router(queue, index),
        session,
        pip: pip,
        preferences: preferences,
        subtitles: subtitles,
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    setUp(() {
      h = VideoPlayerHarness();
      session = h.cubit();
      pip = FakePip();
    });

    testWidgets('plays, with the controls up; they hide while playing', (
      tester,
    ) async {
      await open(tester, [testVideo('a'), testVideo('b')]);

      expect(find.text('Video a'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(h.engines['a']!.value.isPlaying, isTrue);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 300));
      final hidden = tester.widget<IgnorePointer>(
        find
            .ancestor(
              of: find.byTooltip('Pause'),
              matching: find.byType(IgnorePointer),
            )
            .first,
      );
      expect(hidden.ignoring, isTrue);

      // A tap brings them back.
      await tester.tapAt(const Offset(180, 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<IgnorePointer>(
              find
                  .ancestor(
                    of: find.byTooltip('Pause'),
                    matching: find.byType(IgnorePointer),
                  )
                  .first,
            )
            .ignoring,
        isFalse,
      );
      await finish(tester, session);
    });

    testWidgets('the player and the small window fit sideways', (tester) async {
      await open(tester, [testVideo('a'), testVideo('b')]);
      await turnSideways(tester);
      expect(find.byTooltip('Pause'), findsOneWidget);
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();
      expect(find.byType(MiniVideoWindow), findsOneWidget);
      await turnUpright(tester);
      await finish(tester, session);
    });

    testWidgets('top bar: where it is in the list, and its quality', (
      tester,
    ) async {
      await open(tester, [testVideo('a'), testVideo('b')]);
      expect(find.text('1 of 2 · 1080p'), findsOneWidget);
      await finish(tester, session);
    });

    testWidgets('back / forward 10 s buttons', (tester) async {
      await open(tester, [testVideo('a')]);
      h.engines['a']!.advanceTo(const Duration(minutes: 1));
      await tester.tap(find.byTooltip('Forward 10 seconds'));
      await tester.pump();
      expect(h.engines['a']!.value.position, const Duration(seconds: 70));
      await tester.tap(find.byTooltip('Back 10 seconds'));
      await tester.pump();
      expect(h.engines['a']!.value.position, const Duration(seconds: 60));
      await finish(tester, session);
    });

    testWidgets('fill / fit the screen', (tester) async {
      await open(tester, [testVideo('a')]);
      expect(find.byType(FittedBox), findsNothing); // fits at first
      await tester.tap(find.byTooltip('Fill screen'));
      await tester.pump();
      expect(find.byType(FittedBox), findsOneWidget);
      await tester.tap(find.byTooltip('Fit to screen'));
      await tester.pump();
      expect(find.byType(FittedBox), findsNothing);
      await finish(tester, session);
    });

    testWidgets('lock: touches do nothing until Unlock', (tester) async {
      await open(tester, [testVideo('a')]);
      await tester.tap(find.byTooltip('Lock'));
      await tester.pump();
      expect(find.byTooltip('Pause'), findsNothing); // controls gone

      // A double-tap doesn't seek while locked.
      final size = tester.getSize(find.byType(VideoPlayerPage));
      final at = Offset(size.width * 0.8, size.height / 2);
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.engines['a']!.seeks, isEmpty);
      expect(h.engines['a']!.value.isPlaying, isTrue);

      // A tap shows Unlock; it brings the controls back.
      expect(find.text('Unlock'), findsOneWidget);
      await tester.tap(find.text('Unlock'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byTooltip('Pause'), findsOneWidget);
      await finish(tester, session);
    });

    testWidgets('up next: the list, the current one marked; tap to play', (
      tester,
    ) async {
      await open(tester, [testVideo('a'), testVideo('b'), testVideo('c')]);
      await tester.tap(find.byTooltip('Up next'));
      await tester.pumpAndSettle();
      expect(find.text('Up next · 1 of 3'), findsOneWidget);
      expect(find.text('Now playing'), findsOneWidget);

      await tester.tap(find.text('Video c').last);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(session.state.video.id, 'c');
      expect(find.text('3 of 3 · 1080p'), findsOneWidget);
      await finish(tester, session);
    });

    testWidgets('the play button is frosted only on a still picture', (
      tester,
    ) async {
      await open(tester, [testVideo('a')]);
      Finder blur() => find.descendant(
        of: find.byType(VideoTransportButtons),
        matching: find.byType(BackdropFilter),
      );
      // Playing: no blur to redo for every frame.
      expect(blur(), findsNothing);
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(blur(), findsOneWidget);
      await finish(tester, session);
    });

    testWidgets('up next keeps its place when the list changes', (
      tester,
    ) async {
      await open(tester, [for (var i = 0; i < 20; i++) testVideo('v$i')]);
      await tester.tap(find.byTooltip('Up next'));
      await tester.pumpAndSettle();
      final list = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      );
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      final before = tester.state<ScrollableState>(list).position.pixels;
      expect(before, greaterThan(0));

      session.addToQueue([testVideo('extra')]);
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(list).position.pixels,
        closeTo(before, 1),
      );
      await finish(tester, session);
    });

    testWidgets('play / pause, and the next video', (tester) async {
      await open(tester, [testVideo('a'), testVideo('b')]);

      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(h.engines['a']!.value.isPlaying, isFalse);
      expect(find.byTooltip('Play'), findsOneWidget);

      await tester.tap(find.byTooltip('Next video'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Video b'), findsOneWidget);
      expect(h.engines['b']!.value.isPlaying, isTrue);
      await finish(tester, session);
    });

    testWidgets('double-tap the right side: +10 s', (tester) async {
      await open(tester, [testVideo('a')]);
      final size = tester.getSize(find.byType(VideoPlayerPage));

      final at = Offset(size.width * 0.8, size.height / 2);
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 50));

      expect(h.engines['a']!.seeks.last, const Duration(seconds: 10));
      expect(find.text('+10s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('+10s'), findsNothing);
      await finish(tester, session);
    });

    testWidgets("a video that can't play: why, and the next one", (
      tester,
    ) async {
      h = VideoPlayerHarness(unplayable: ['a']);
      session = h.cubit();
      await open(tester, [testVideo('a'), testVideo('b')]);

      expect(find.text("This video can't be played"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Next video'));
      await tester.pump();
      await tester.pump();
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(find.text('Video b'), findsOneWidget);
      await finish(tester, session);
    });

    testWidgets('opens upright; only the rotate button turns the screen', (
      tester,
    ) async {
      final turns = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            turns.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await open(tester, [testVideo('a')]);
      // Upright on opening, even for a wide video.
      expect(turns, [
        ['DeviceOrientation.portraitUp'],
      ]);

      session
        ..playNext([testVideo('b')])
        ..addToQueue([testVideo('c')]);
      await tester.pump();
      // Moving to the next video doesn't turn it either.
      await tester.tap(find.byTooltip('Next video'));
      await tester.pump();
      await tester.pump();
      expect(turns, hasLength(1));

      await tester.tap(find.byTooltip('Rotate'));
      await tester.pump();
      expect(turns.last, [
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]);
      await finish(tester, session);
    });

    testWidgets('leaving keeps it playing in a small window', (tester) async {
      await open(tester, [testVideo('a')]);
      expect(find.byType(MiniVideoWindow), findsNothing); // full screen

      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();
      expect(find.byType(VideoPlayerPage), findsNothing);
      expect(find.byType(MiniVideoWindow), findsOneWidget);
      expect(h.engines['a']!.value.isPlaying, isTrue);
      // Same video, not reloaded.
      expect(h.engines, hasLength(1));

      // Tap: back to full screen, still the same video.
      await tester.tap(find.byType(MiniVideoCard));
      await tester.pumpAndSettle();
      expect(find.byType(VideoPlayerPage), findsOneWidget);
      expect(find.byType(MiniVideoWindow), findsNothing);
      expect(h.engines, hasLength(1));
      await finish(tester, session);
    });

    testWidgets('the window: pause, and close ends the video', (tester) async {
      await open(tester, [testVideo('a')]);
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();
      h.engines['a']!.advanceTo(const Duration(minutes: 2));

      await tester.tap(find.bySemanticsLabel('Pause'));
      await tester.pump();
      expect(h.engines['a']!.value.isPlaying, isFalse);

      await tester.tap(find.bySemanticsLabel('Close video'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byType(MiniVideoWindow), findsNothing);
      expect(session.state.isActive, isFalse);
      expect(h.engines['a']!.disposed, isTrue);
      verify(
        () => h.savePosition(
          'a',
          const Duration(minutes: 2),
          length: any(named: 'length'),
        ),
      ).called(greaterThanOrEqualTo(1));
      await finish(tester, session);
    });

    testWidgets('with a song loaded, the window stays above the music bar', (
      tester,
    ) async {
      await pumpApp(
        tester,
        router([testVideo('a')], 0),
        session,
        clearance: MiniVideoWindow.clearanceFor(
          landscape: false,
          musicBar: true,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();

      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      final bottom = tester.getBottomLeft(find.byType(MiniVideoCard)).dy;
      expect(
        bottom,
        lessThanOrEqualTo(
          screen.height -
              MiniVideoWindow.clearanceFor(
                landscape: false,
                musicBar: true,
              ).bottom,
        ),
      );
      await finish(tester, session);
    });

    testWidgets('sideways, the window keeps clear of the nav rail', (
      tester,
    ) async {
      final clearance = MiniVideoWindow.clearanceFor(
        landscape: true,
        musicBar: true,
      );
      await pumpApp(
        tester,
        router([testVideo('a')], 0),
        session,
        clearance: clearance,
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await turnSideways(tester);
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();

      // Dragged to the left: it stops beside the rail, not over it.
      await tester.timedDrag(
        find.byType(MiniVideoCard),
        const Offset(-600, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byType(MiniVideoCard)).dx,
        greaterThanOrEqualTo(clearance.left),
      );
      await finish(tester, session);
    });

    testWidgets('dragged to the left, it snaps to the left corner', (
      tester,
    ) async {
      await open(tester, [testVideo('a')]);
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(find.byType(MiniVideoCard));
      expect(before.dx, greaterThan(180)); // starts on the right

      await tester.timedDrag(
        find.byType(MiniVideoCard),
        const Offset(-150, -300),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      final after = tester.getTopLeft(find.byType(MiniVideoCard));
      expect(after.dx, closeTo(MiniVideoWindow.margin, 1));
      expect(after.dy, lessThan(before.dy));
      expect(session.state.isActive, isTrue);
      await finish(tester, session);
    });

    testWidgets('thrown off the side, it closes', (tester) async {
      await open(tester, [testVideo('a')]);
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(MiniVideoCard),
        const Offset(300, 0),
        3000,
      );
      await tester.pumpAndSettle();
      expect(session.state.isActive, isFalse);
      expect(find.byType(MiniVideoWindow), findsNothing);
      await finish(tester, session);
    });

    testWidgets('listen as audio: same video, no picture; and back', (
      tester,
    ) async {
      await open(tester, [testVideo('a')]);
      final player = h.engines['a']!..advanceTo(const Duration(minutes: 1));
      expect(pip.calls.last.$1, isTrue);

      await tester.tap(find.byTooltip('Listen as audio'));
      await tester.pump();
      expect(find.byType(VideoAudioView), findsOneWidget);
      expect(find.byType(VideoPlayingView), findsNothing);
      expect(find.byKey(const ValueKey('fake-video')), findsNothing);
      // Still playing, from where it was: the same player.
      expect(player.value.isPlaying, isTrue);
      expect(player.value.position, const Duration(minutes: 1));
      expect(h.engines, hasLength(1));
      // Leaving the app doesn't make a picture-in-picture window.
      expect(pip.calls.last.$1, isFalse);

      await tester.tap(find.text('Watch video'));
      await tester.pump();
      expect(find.byType(VideoPlayingView), findsOneWidget);
      expect(find.byType(VideoAudioView), findsNothing);
      expect(player.value.isPlaying, isTrue);
      expect(h.engines, hasLength(1));
      expect(pip.calls.last.$1, isTrue);
      await finish(tester, session);
    });

    testWidgets('as audio, the small window holds the audio controls', (
      tester,
    ) async {
      await open(tester, [testVideo('a')]);
      await tester.tap(find.byTooltip('Listen as audio'));
      await tester.pump();
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();
      expect(find.byType(MiniVideoAudioCard), findsOneWidget);
      expect(find.byType(MiniVideoCard), findsNothing);
      expect(find.byKey(const ValueKey('fake-video')), findsNothing);

      // Back to the video: the same window, with the picture.
      await tester.tap(find.bySemanticsLabel('Watch video'));
      await tester.pumpAndSettle();
      expect(find.byType(MiniVideoAudioCard), findsNothing);
      expect(find.byType(MiniVideoCard), findsOneWidget);
      expect(find.byKey(const ValueKey('fake-video')), findsOneWidget);

      // And from the window to audio again.
      await tester.tap(find.bySemanticsLabel('Listen as audio'));
      await tester.pumpAndSettle();
      expect(find.byType(MiniVideoAudioCard), findsOneWidget);
      expect(h.engines['a']!.value.isPlaying, isTrue);

      await tester.tap(find.bySemanticsLabel('Pause'));
      await tester.pump();
      expect(h.engines['a']!.value.isPlaying, isFalse);

      // A tap opens the full player, as audio.
      await tester.tap(find.text('Audio only'));
      await tester.pumpAndSettle();
      expect(find.byType(VideoAudioView), findsOneWidget);
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Close video'));
      await tester.pump();
      await tester.pump();
      expect(session.state.isActive, isFalse);
      expect(find.byType(MiniVideoAudioCard), findsNothing);
      await finish(tester, session);
    });

    testWidgets('as audio, the window moves too: corners, and off the side', (
      tester,
    ) async {
      await open(tester, [testVideo('a')]);
      await tester.tap(find.byTooltip('Listen as audio'));
      await tester.pump();
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();
      final card = find.byType(MiniVideoAudioCard);
      final before = tester.getTopLeft(card);
      expect(before.dx, greaterThan(60)); // starts on the right

      await tester.timedDrag(
        card,
        const Offset(-150, -300),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      final after = tester.getTopLeft(card);
      expect(after.dx, closeTo(MiniVideoWindow.margin, 1));
      expect(after.dy, lessThan(before.dy));
      expect(session.state.isActive, isTrue);

      // Back to the video: it stays in its corner.
      await tester.tap(find.bySemanticsLabel('Watch video'));
      await tester.pumpAndSettle();
      final video = tester.getTopLeft(find.byType(MiniVideoCard));
      expect(video.dx, closeTo(MiniVideoWindow.margin, 1));
      expect(video.dy, closeTo(after.dy, 1));

      // Thrown off the side: closed.
      await tester.tap(find.bySemanticsLabel('Listen as audio'));
      await tester.pumpAndSettle();
      await tester.fling(card, const Offset(-300, 0), 2500);
      await tester.pumpAndSettle();
      expect(session.state.isActive, isFalse);
      await finish(tester, session);
    });

    testWidgets('pulled down, the player minimizes (watched or as audio)', (
      tester,
    ) async {
      await open(tester, [testVideo('a')]);
      await tester.fling(
        find.byType(VideoPlayerPage),
        const Offset(0, 400),
        1500,
      );
      await tester.pumpAndSettle();
      expect(find.byType(VideoPlayerPage), findsNothing);
      expect(find.byType(MiniVideoCard), findsOneWidget);
      expect(h.engines['a']!.value.isPlaying, isTrue);

      await tester.tap(find.byType(MiniVideoCard));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Listen as audio'));
      await tester.pump();
      await tester.fling(
        find.byType(VideoAudioView),
        const Offset(0, 400),
        1500,
      );
      await tester.pumpAndSettle();
      expect(find.byType(VideoPlayerPage), findsNothing);
      expect(find.byType(MiniVideoAudioCard), findsOneWidget);
      await finish(tester, session);
    });

    testWidgets('a short pull springs back; locked, pulling does nothing', (
      tester,
    ) async {
      await open(tester, [testVideo('a')]);
      await tester.timedDrag(
        find.byType(VideoPlayerPage),
        const Offset(0, 80),
        const Duration(milliseconds: 800),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VideoPlayerPage), findsOneWidget);

      await tester.tap(find.byTooltip('Lock'));
      await tester.pump();
      await tester.fling(
        find.byType(VideoPlayerPage),
        const Offset(0, 400),
        1500,
      );
      await tester.pumpAndSettle();
      expect(find.byType(VideoPlayerPage), findsOneWidget);
      expect(find.byType(MiniVideoWindow), findsNothing);
      await finish(tester, session);
    });

    testWidgets('app hidden: watched pauses (and plays on); audio goes on', (
      tester,
    ) async {
      Future<void> lifecycle(List<AppLifecycleState> states) async {
        for (final state in states) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await tester.pump();
      }

      const hide = [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ];
      const show = [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ];
      await open(tester, [testVideo('a')]);
      final player = h.engines['a']!;

      await lifecycle(hide);
      expect(player.value.isPlaying, isFalse);
      await lifecycle(show);
      expect(player.value.isPlaying, isTrue);

      await tester.tap(find.byTooltip('Listen as audio'));
      await tester.pump();
      await lifecycle(hide);
      expect(player.value.isPlaying, isTrue);
      await lifecycle(show);
      expect(player.value.isPlaying, isTrue);
      await finish(tester, session);
    });

    testWidgets('leaving the app shrinks it to a window only while playing', (
      tester,
    ) async {
      await open(tester, [testVideo('a')]);
      expect(pip.calls.last, (true, 1920, 1080)); // the video's shape

      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(pip.calls.last.$1, isFalse);

      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      expect(pip.calls.last.$1, isTrue);

      // Closed: leaving the app just leaves it.
      await session.stop();
      await tester.pump();
      expect(pip.calls.last.$1, isFalse);
      // Told about changes only, not on every tick.
      h.engines['a']!.advanceTo(const Duration(seconds: 5));
      final told = pip.calls.length;
      await tester.pump();
      expect(pip.calls, hasLength(told));
      await finish(tester, session);
    });

    testWidgets('the skip length from Settings: buttons, double-tap, window', (
      tester,
    ) async {
      await open(
        tester,
        [testVideo('a')],
        0,
        const UiPreferences(videoSeekSeconds: 5),
      );
      final player = h.engines['a']!..advanceTo(const Duration(seconds: 30));

      await tester.tap(find.byTooltip('Forward 5 seconds'));
      await tester.pump();
      expect(player.value.position, const Duration(seconds: 35));
      await tester.tap(find.byTooltip('Back 5 seconds'));
      await tester.pump();
      expect(player.value.position, const Duration(seconds: 30));

      // Double-tap the right half.
      final center = tester.getCenter(find.byType(VideoPlayerControls));
      final right = center + const Offset(100, 0);
      await tester.tapAt(right);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(right);
      await tester.pump(const Duration(milliseconds: 400));
      expect(player.value.position, const Duration(seconds: 35));
      expect(find.text('+5s'), findsOneWidget);

      pip.enter();
      await tester.pump();
      pip.tap(PictureInPictureAction.forward);
      await tester.pump();
      expect(player.value.position, const Duration(seconds: 40));
      pip.leave();
      await tester.pump(const Duration(seconds: 1));
      await finish(tester, session);
    });

    testWidgets('subtitles: the chosen track shows at the right time', (
      tester,
    ) async {
      final subtitles = FakeSubtitleRepository()
        ..tracks['a'] = [testTrack('english')]
        ..selected['a'] = 'english'
        ..timelines['english'] = timelineOf('Hello there');
      await open(
        tester,
        [testVideo('a')],
        0,
        UiPreferences.defaults,
        subtitles,
      );
      await tester.pump();
      final player = h.engines['a']!;

      expect(find.text('Hello there'), findsNothing); // before its time
      player.advanceTo(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text('Hello there'), findsOneWidget);
      player.advanceTo(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text('Hello there'), findsNothing); // after it

      // The sheet: off, and the track (chosen).
      await tester.tap(find.byTooltip('Subtitles'));
      await tester.pumpAndSettle();
      expect(find.text('english.srt'), findsOneWidget);
      await tester.tap(find.text('Off'));
      await tester.pumpAndSettle();
      expect(subtitles.selected['a'], isNull);

      Navigator.of(tester.element(find.text('Off'))).pop();
      await tester.pumpAndSettle();
      await finish(tester, session);
    });

    testWidgets('subtitles: search online, download, and it shows', (
      tester,
    ) async {
      const found = OnlineSubtitle(
        fileId: 7,
        title: 'Video.a.Release',
        language: 'en',
        downloadCount: 12,
      );
      final subtitles = FakeSubtitleRepository()
        ..searchResult = const Right([found])
        ..downloadResult = Right(
          SubtitleDownload(
            track: testTrack('downloaded:7', source: SubtitleSource.downloaded),
            remaining: 4,
            resetsIn: '20 hours',
          ),
        );
      await open(
        tester,
        [testVideo('a')],
        0,
        UiPreferences.defaults,
        subtitles,
      );
      await tester.tap(find.byTooltip('Subtitles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search online'));
      await tester.pumpAndSettle();

      // Searched at once, for the video's name.
      expect(subtitles.searches.single.$1, 'Video a');
      expect(find.text('Video.a.Release'), findsOneWidget);
      expect(find.text('EN · SRT · 12 downloads'), findsOneWidget);

      await tester.tap(find.byTooltip('Download'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Saved'), findsOneWidget);
      expect(
        find.text('4 downloads left today. Resets in 20 hours.'),
        findsOneWidget,
      );
      // Remembered for the video, and shown in the player now.
      expect(subtitles.selected['a'], 'downloaded:7');
      final cubit = BlocProvider.of<SubtitlesCubit>(
        tester.element(find.byType(VideoPlayerControls)),
      );
      expect(cubit.state.selectedId, 'downloaded:7');

      Navigator.of(tester.element(find.text('Video.a.Release'))).pop();
      await tester.pumpAndSettle();
      await finish(tester, session);
    });

    testWidgets("the window's buttons control the video, not the music", (
      tester,
    ) async {
      await open(tester, [testVideo('a')]);
      final player = h.engines['a']!;
      player.advanceTo(const Duration(seconds: 30));
      pip.enter();
      await tester.pump();

      pip.tap(PictureInPictureAction.forward);
      await tester.pump();
      expect(player.value.position, const Duration(seconds: 40));
      pip.tap(PictureInPictureAction.rewind);
      await tester.pump();
      expect(player.value.position, const Duration(seconds: 30));

      pip.tap(PictureInPictureAction.pause);
      await tester.pump();
      expect(player.value.isPlaying, isFalse);
      pip.tap(PictureInPictureAction.play);
      await tester.pump();
      expect(player.value.isPlaying, isTrue);

      pip.leave();
      await finish(tester, session);
    });

    testWidgets('in the window: only the video; the app as it was after', (
      tester,
    ) async {
      await open(tester, [testVideo('a')]);
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();
      expect(find.byType(MiniVideoWindow), findsOneWidget);

      pip.enter();
      await tester.pump();
      await tester.pump();
      expect(find.byType(PictureInPictureVideo), findsOneWidget);
      expect(find.byType(MiniVideoWindow), findsNothing);
      expect(find.text('open'), findsNothing); // pages not drawn…
      expect(find.text('open', skipOffstage: false), findsOneWidget); // …kept
      expect(h.engines['a']!.value.isPlaying, isTrue);

      pip.leave();
      await tester.pump();
      await tester.pump();
      expect(find.byType(PictureInPictureVideo), findsNothing);
      expect(find.byType(MiniVideoWindow), findsOneWidget);
      expect(find.text('open'), findsOneWidget);
      expect(h.engines, hasLength(1)); // never reloaded
      await finish(tester, session);
    });
  });
}
