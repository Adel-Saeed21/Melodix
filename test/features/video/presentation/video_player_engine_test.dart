import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/playback/video_player_engine.dart';
import 'package:video_player/video_player.dart';

bool isReleased(VideoPlayerController controller) {
  try {
    ChangeNotifier.debugAssertNotDisposed(controller);
    return false;
  } on FlutterError {
    return true;
  }
}

void main() {
  late VideoPlayerController controller;
  late VideoPlayerEngine engine;

  setUp(() {
    // Never initialized: no platform needed.
    controller = VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/video.mp4'),
    );
    engine = VideoPlayerEngine(controller);
  });

  testWidgets('released only once no view of it is on screen', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            SizedBox(height: 50, child: engine.buildView()),
            SizedBox(height: 50, child: engine.buildView()),
          ],
        ),
      ),
    );

    await engine.dispose();
    expect(isReleased(controller), isFalse); // still shown (twice)

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(height: 50, child: engine.buildView()),
      ),
    );
    expect(isReleased(controller), isFalse); // still shown once

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(isReleased(controller), isTrue);
  });

  test('with nothing showing it, released at once; twice is fine', () async {
    await engine.dispose();
    expect(isReleased(controller), isTrue);
    await engine.dispose();
  });

  test("reports the player's state in the app's own terms", () {
    final heard = <bool>[];
    engine.addListener(() => heard.add(engine.value.isPlaying));

    controller.value = VideoPlayerValue(
      duration: const Duration(minutes: 2),
      position: const Duration(seconds: 30),
      size: const Size(1280, 720),
      isInitialized: true,
      isPlaying: true,
      buffered: [DurationRange(Duration.zero, const Duration(seconds: 45))],
    );

    final value = engine.value;
    expect(value.isInitialized, isTrue);
    expect(value.isPlaying, isTrue);
    expect(value.position, const Duration(seconds: 30));
    expect(value.bufferedTo, const Duration(seconds: 45));
    expect(value.aspectRatio, closeTo(16 / 9, 0.001));
    expect(heard, [true]);
  });
}
