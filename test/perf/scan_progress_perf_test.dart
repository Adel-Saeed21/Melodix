import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_shortcuts.dart';
import 'package:mocktail/mocktail.dart';

import 'paint_counter.dart';

class MockLibrary extends Mock implements MusicLibraryBloc {}

/// The Scan card's progress must not make the home screen lag: before
/// this was tuned, a 5 s scan rebuilt the three cards on every frame (897
/// builds) and repainted the tabs and songs under them on every frame
/// (299 repaints).
void main() {
  const frame = Duration(microseconds: 16667); // 60 fps

  late PaintCount neighbourPaints;
  late int cardBuilds;

  Future<void> pumpScanning(
    WidgetTester tester, {
    bool scanning = true,
    LibrarySyncStage? stage = LibrarySyncStage.reading,
  }) async {
    final library = MockLibrary();
    when(() => library.state).thenReturn(const MusicLibraryState());
    when(() => library.stream).thenAnswer((_) => const Stream.empty());
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppScreenUtilInit(
        child: BlocProvider<MusicLibraryBloc>.value(
          value: library,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Column(
                children: [
                  LibraryShortcuts(
                    favouriteCount: 3,
                    isScanning: scanning,
                    syncStage: stage,
                    onScan: () async {},
                  ),
                  // Stands for the tabs and songs under the cards: if the
                  // progress repaints spread, this count grows.
                  PaintCounter(counter: neighbourPaints),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    neighbourPaints = PaintCount();
    cardBuilds = 0;
    debugOnRebuildDirtyWidget = (element, _) {
      if (element.widget is ShortcutCard) cardBuilds++;
    };
  });

  tearDown(() => debugOnRebuildDirtyWidget = null);

  Future<void> runFrames(WidgetTester tester, Duration duration) async {
    for (var i = 0; i < duration.inMicroseconds ~/ frame.inMicroseconds; i++) {
      await tester.pump(frame);
    }
  }

  testWidgets('a running scan never repaints the screen below the cards', (
    tester,
  ) async {
    await pumpScanning(tester, scanning: false);
    await pumpScanning(tester); // scan starts
    await tester.pump();
    neighbourPaints.value = 0;
    cardBuilds = 0;

    await runFrames(tester, const Duration(seconds: 5));

    expect(neighbourPaints.value, 0);
    // Only the Scan card, and only when the whole percent changes (at most
    // ~100 times in a whole scan), not 60 times a second.
    expect(cardBuilds, lessThanOrEqualTo(80));
  });

  testWidgets('waiting on the device costs no frames at all', (tester) async {
    await pumpScanning(tester, scanning: false);
    await pumpScanning(tester);
    // The ring eases up to just below the end of "reading"…
    await runFrames(tester, const Duration(seconds: 8));

    // …then stops until the next stage: nothing left to draw.
    expect(tester.binding.hasScheduledFrame, isFalse);

    // The next stage starts it again.
    await pumpScanning(tester, stage: LibrarySyncStage.saving);
    expect(tester.binding.hasScheduledFrame, isTrue);
  });
}
