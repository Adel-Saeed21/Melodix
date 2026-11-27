import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/core/usecase/open_app_settings_usecase.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:melodix/features/navigation/presentation/pages/main_nav_shell.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/entities/video_library_changes.dart';
import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/features/video/domain/usecases/sync_video_library_usecase.dart';
import 'package:melodix/features/video/domain/usecases/video_permission_usecases.dart';
import 'package:melodix/features/video/domain/usecases/video_progress_usecases.dart';
import 'package:melodix/features/video/domain/usecases/watch_videos_usecase.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';
import 'package:melodix/features/video/presentation/pages/video_page.dart';
import 'package:mocktail/mocktail.dart';
import '../../support/l10n_support.dart';

class _MockPlayer extends Mock implements PlayerCubit {}

class _MockWatchVideos extends Mock implements WatchVideosUseCase {}

class _MockSync extends Mock implements SyncVideoLibraryUseCase {}

class _MockCheck extends Mock implements CheckVideoPermissionUseCase {}

class _MockRequest extends Mock implements RequestVideoPermissionUseCase {}

class _MockOpenSettings extends Mock implements OpenAppSettingsUseCase {}

class _MockWatchProgress extends Mock implements WatchVideoProgressUseCase {}

/// Stands in for a heavy tab (the Music and Settings pages need the whole
/// app); says when it was built.
class _TabProbe extends StatelessWidget {
  const _TabProbe(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Center(child: Text('$name page'));
}

void main() {
  late _MockSync sync;
  late _MockCheck check;

  /// How many Video tab cubits the app made (one per Video tab built).
  late int cubitsCreated;

  setUpAll(() => registerFallbackValue(const VideoSyncParams()));

  setUp(() async {
    await getIt.reset();
    cubitsCreated = 0;
    final watchVideos = _MockWatchVideos();
    final watchProgress = _MockWatchProgress();
    sync = _MockSync();
    check = _MockCheck();
    when(() => watchVideos()).thenAnswer((_) => Stream.value(const <Video>[]));
    when(() => watchProgress())
        .thenAnswer((_) => Stream.value(const <String, VideoProgress>{}));
    when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
    when(() => sync(any())).thenAnswer(
      (_) async => const Right(
        VideoLibraryChanges(added: 0, updated: 0, removed: 0, total: 0),
      ),
    );
    // What the real VideoPage asks get_it for (as in the app).
    getIt.registerFactory<VideoLibraryCubit>(() {
      cubitsCreated++;
      return VideoLibraryCubit(
        watchVideos: watchVideos,
        sync: sync,
        checkPermission: check,
        requestPermission: _MockRequest(),
        openSettings: _MockOpenSettings(),
        watchProgress: watchProgress,
        appResumed: const Stream.empty(),
      );
    });
  });

  tearDown(() => getIt.reset());

  Future<void> pumpShell(WidgetTester tester) async {
    // The Music tab's mini player, with nothing playing (hidden).
    final player = _MockPlayer();
    when(() => player.state).thenReturn(const NowPlaying());
    when(() => player.stream).thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<PlayerCubit>.value(
            value: player,
            child: MainNavShell(
              pages: [
                const _TabProbe('Music'),
                // The real Video tab, exactly as the app builds it.
                MainNavShell.defaultPages[1],
                const _TabProbe('Settings'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('the app uses the real Video page in the Video tab slot', () {
    expect(MainNavShell.defaultPages[1], isA<VideoPage>());
  });

  testWidgets('launching on Music neither builds nor starts the Video tab', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.text('Music page'), findsOneWidget);
    expect(find.byType(VideoPage), findsNothing);
    expect(cubitsCreated, 0);
    // So nothing asked the phone about its videos either.
    verifyNever(() => check());
    verifyNever(() => sync(any()));
  });

  testWidgets('opening the Video tab builds and starts it, once', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text(english.video));
    await tester.pumpAndSettle();

    expect(find.byType(VideoPage), findsOneWidget);
    expect(find.text(english.videos), findsOneWidget); // its header
    expect(cubitsCreated, 1);
    verify(() => check()).called(1);
    verify(() => sync(const VideoSyncParams())).called(1); // a cheap check

    // Back to Music and again to Video: the tab (and its cubit) is kept.
    await tester.tap(find.text(english.music));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.video));
    await tester.pumpAndSettle();
    expect(cubitsCreated, 1);
    verifyNever(() => check());
  });
}
