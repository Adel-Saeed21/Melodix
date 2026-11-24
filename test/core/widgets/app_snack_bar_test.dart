import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';

void main() {
  /// Pumps a page and shows a message from it via [show].
  Future<void> showFrom(
    WidgetTester tester,
    void Function(BuildContext context) show, {
    bool accessibleNavigation = false,
  }) async {
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(accessibleNavigation: accessibleNavigation),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => show(context),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump(); // start the entrance
    await tester.pump(const Duration(milliseconds: 750)); // fully shown
  }

  SnackBar shown(WidgetTester tester) =>
      tester.widget<SnackBar>(find.byType(SnackBar));

  testWidgets('a plain message is short and marked as done', (tester) async {
    await showFrom(tester, (c) => AppSnackBar.show(c, 'Playlist renamed'));

    expect(find.text('Playlist renamed'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(shown(tester).duration, const Duration(seconds: 2));
    expect(shown(tester).action, isNull);
  });

  testWidgets('an error shows the error icon', (tester) async {
    await showFrom(
      tester,
      (c) => AppSnackBar.show(c, 'Nope', kind: AppSnackBarKind.error),
    );

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('an action stays a bit longer, runs once and closes it', (
    tester,
  ) async {
    var undone = 0;
    await showFrom(
      tester,
      (c) => AppSnackBar.show(
        c,
        'Hidden from library',
        actionLabel: 'Undo',
        onAction: () => undone++,
      ),
    );
    expect(shown(tester).duration, const Duration(seconds: 3));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(undone, 1);
    expect(find.text('Hidden from library'), findsNothing);
  });

  testWidgets('with a screen reader, an action gets time to be found', (
    tester,
  ) async {
    await showFrom(
      tester,
      (c) => AppSnackBar.show(
        c,
        'Hidden from library',
        actionLabel: 'Undo',
        onAction: () {},
      ),
      accessibleNavigation: true,
    );

    expect(shown(tester).duration, greaterThan(const Duration(seconds: 3)));
  });

  testWidgets('a new message replaces the current one', (tester) async {
    late BuildContext page;
    await showFrom(tester, (c) {
      page = c;
      AppSnackBar.show(c, 'First');
    });

    AppSnackBar.show(page, 'Second');
    await tester.pumpAndSettle();

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
  });
}
