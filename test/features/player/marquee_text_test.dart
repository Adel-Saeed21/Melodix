import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/player/presentation/utils/player_rebuild_stats.dart';
import 'package:melodix/features/player/presentation/widgets/marquee_text.dart';

void main() {
  Future<void> pump(WidgetTester tester, String text, {bool reduce = false}) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: SizedBox(width: 120, child: MarqueeText(text))),
          ),
        ),
      ),
    );
  }

  double firstCopyX(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text).first).dx;

  testWidgets('short text stays still', (tester) async {
    await pump(tester, 'Short');
    expect(find.text('Short'), findsOneWidget);
    final x = firstCopyX(tester, 'Short');
    await tester.pump(const Duration(seconds: 4));
    expect(firstCopyX(tester, 'Short'), x);
  });

  testWidgets('long text scrolls continuously after a pause', (tester) async {
    const long = 'A really long song title that never fits';
    await pump(tester, long);

    // Two copies for the seamless loop.
    expect(find.text(long), findsNWidgets(2));
    final start = firstCopyX(tester, long);

    await tester.pump(const Duration(milliseconds: 1000)); // still pausing
    expect(firstCopyX(tester, long), start);

    await tester.pump(const Duration(milliseconds: 1500)); // scrolling
    expect(firstCopyX(tester, long), lessThan(start));
  });

  testWidgets('reduced motion cuts long text instead of scrolling', (
    tester,
  ) async {
    const long = 'A really long song title that never fits';
    await pump(tester, long, reduce: true);

    expect(find.text(long), findsOneWidget);
    expect(
      tester.widget<Text>(find.text(long)).overflow,
      TextOverflow.ellipsis,
    );
  });

  group('measurement cache', () {
    Widget host(String text, {double width = 120, Color? color}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: MarqueeText(text, style: TextStyle(color: color)),
          ),
        ),
      ),
    );

    testWidgets('rebuilding with the same text does not re-measure', (
      tester,
    ) async {
      PlayerRebuildStats.reset();
      await tester.pumpWidget(host('Short'));
      expect(PlayerRebuildStats.of('marqueeMeasure'), 1);

      await tester.pumpWidget(host('Short', width: 200)); // more room
      await tester.pumpWidget(host('Short'));
      expect(PlayerRebuildStats.of('marqueeMeasure'), 1);
    });

    testWidgets('a new title or style is measured again', (tester) async {
      PlayerRebuildStats.reset();
      await tester.pumpWidget(host('Short'));
      await tester.pumpWidget(host('Another title'));
      expect(PlayerRebuildStats.of('marqueeMeasure'), 2);
      expect(find.text('Another title'), findsWidgets);

      await tester.pumpWidget(host('Another title', color: Colors.red));
      expect(PlayerRebuildStats.of('marqueeMeasure'), 3);
    });

    testWidgets('less room makes a fitting title start scrolling', (
      tester,
    ) async {
      await tester.pumpWidget(host('Medium title', width: 400));
      expect(find.text('Medium title'), findsOneWidget); // fits: one copy

      await tester.pumpWidget(host('Medium title', width: 40));
      expect(find.text('Medium title'), findsNWidgets(2)); // scrolls
    });
  });
}
