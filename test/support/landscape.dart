import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A 6.5" phone on its side: 800 × 360 dp.
const Size landscapePhone = Size(2400, 1080);

/// Turns the test screen sideways, as the user rotating the phone, and lets
/// the screen redraw. Any overflow then fails the test (with where it is).
Future<void> turnSideways(WidgetTester tester) async {
  tester.view
    ..physicalSize = landscapePhone
    ..devicePixelRatio = 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Back to portrait (rotating back must work too).
Future<void> turnUpright(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
