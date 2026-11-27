import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/navigation/presentation/widgets/fade_through_tabs.dart';

void main() {
  /// A page that counts taps (to see its state survive).
  Widget page(String name) => _Counter(key: ValueKey(name), name: name);

  Future<void> pumpTabs(
    WidgetTester tester,
    int index, {
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    Directionality(
      textDirection: direction,
      child: FadeThroughTabs(
        index: index,
        children: [page('A'), page('B'), page('C')],
      ),
    ),
  );

  double opacityOf(WidgetTester tester, String name) => tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.text(name, skipOffstage: false),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  double slideOf(WidgetTester tester, String name) => tester
      .widget<SlideTransition>(
        find
            .ancestor(
              of: find.text(name, skipOffstage: false),
              matching: find.byType(SlideTransition),
            )
            .first,
      )
      .position
      .value
      .dx;

  testWidgets('one page at a time; each keeps its state', (tester) async {
    await pumpTabs(tester, 0);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing); // offstage
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(find.text('A taps: 1'), findsOneWidget);

    await pumpTabs(tester, 1);
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    expect(find.text('A'), findsNothing);

    await pumpTabs(tester, 0);
    await tester.pumpAndSettle();
    expect(find.text('A taps: 1'), findsOneWidget); // not rebuilt from scratch
  });

  testWidgets('fades through: out first, then in, sliding from its side', (
    tester,
  ) async {
    await pumpTabs(tester, 0);
    await pumpTabs(tester, 2);

    await tester.pump(const Duration(milliseconds: 60));
    // The old page is on its way out; the new one not in yet.
    expect(opacityOf(tester, 'A'), inExclusiveRange(0, 1));
    expect(opacityOf(tester, 'C'), 0);
    // Coming from the right (a tab further along).
    expect(slideOf(tester, 'C'), greaterThan(0));
    // The leaving page takes no taps.
    await tester.tap(find.text('A'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('A taps: 1', skipOffstage: false), findsNothing);

    await tester.pumpAndSettle();
    expect(opacityOf(tester, 'C'), 1);
    expect(slideOf(tester, 'C'), 0);
    expect(find.text('A'), findsNothing);

    // Back to an earlier tab: from the left.
    await pumpTabs(tester, 1);
    await tester.pump(const Duration(milliseconds: 60));
    expect(slideOf(tester, 'B'), lessThan(0));
    await tester.pumpAndSettle();
  });

  testWidgets('right to left: the slide is mirrored', (tester) async {
    await pumpTabs(tester, 0, direction: TextDirection.rtl);
    await pumpTabs(tester, 1, direction: TextDirection.rtl);
    await tester.pump(const Duration(milliseconds: 60));
    expect(slideOf(tester, 'B'), lessThan(0));
    await tester.pumpAndSettle();
  });

  testWidgets('a quick second switch lands on the last tab', (tester) async {
    await pumpTabs(tester, 0);
    await pumpTabs(tester, 1);
    await tester.pump(const Duration(milliseconds: 80));
    await pumpTabs(tester, 2);
    await tester.pumpAndSettle();
    expect(find.text('C'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);
    expect(opacityOf(tester, 'C'), 1);
  });
}

class _Counter extends StatefulWidget {
  const _Counter({super.key, required this.name});

  final String name;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _taps++),
    child: Column(
      children: [Text(widget.name), Text('${widget.name} taps: $_taps')],
    ),
  );
}
