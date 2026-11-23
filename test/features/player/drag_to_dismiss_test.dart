import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/player/presentation/widgets/drag_to_dismiss.dart';

void main() {
  late int dismissed;

  Future<void> pump(WidgetTester tester) {
    dismissed = 0;
    return tester.pumpWidget(
      MaterialApp(
        home: DragToDismiss(
          onDismiss: () => dismissed++,
          child: const ColoredBox(
            color: Colors.black,
            child: Center(child: Text('page')),
          ),
        ),
      ),
    );
  }

  double pageTop(WidgetTester tester) =>
      tester.getTopLeft(find.text('page')).dy;

  testWidgets('a long pull down dismisses', (tester) async {
    await pump(tester);

    await tester.drag(find.text('page'), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(dismissed, 1);
  });

  testWidgets('a short pull springs back without dismissing', (tester) async {
    await pump(tester);
    final rest = pageTop(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('page')),
    );
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(pageTop(tester), greaterThan(rest)); // follows the finger

    await gesture.up();
    await tester.pumpAndSettle();
    expect(dismissed, 0);
    expect(pageTop(tester), rest);
  });

  testWidgets('a fast flick down dismisses even if short', (tester) async {
    await pump(tester);

    await tester.fling(find.text('page'), const Offset(0, 80), 1500);
    await tester.pumpAndSettle();

    expect(dismissed, 1);
  });

  testWidgets('pulling up does nothing', (tester) async {
    await pump(tester);
    final rest = pageTop(tester);

    await tester.drag(find.text('page'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(dismissed, 0);
    expect(pageTop(tester), rest);
  });
}
