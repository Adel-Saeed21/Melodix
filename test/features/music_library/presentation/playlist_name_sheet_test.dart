import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_dialogs.dart';

void main() {
  late String? result;

  Future<void> openSheet(
    WidgetTester tester, {
    String initialName = '',
    String title = 'New playlist',
    String actionLabel = 'Create',
    double textScale = 1,
  }) async {
    result = 'not closed';
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async => result = await showPlaylistNameDialog(
                    context,
                    initialName: initialName,
                    title: title,
                    actionLabel: actionLabel,
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
  }

  ElevatedButton action(WidgetTester tester, String label) =>
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, label));

  testWidgets('create returns the trimmed name', (tester) async {
    await openSheet(tester);

    await tester.enterText(find.byType(TextField), '  Gym mix  ');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(result, 'Gym mix');
  });

  testWidgets('cancel returns null', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('rename starts with the name and needs a change', (tester) async {
    await openSheet(
      tester,
      initialName: 'Gym',
      title: 'Rename playlist',
      actionLabel: 'Save',
    );

    expect(find.text('Choose a new name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Gym'), findsOneWidget);
    expect(find.text('Road trip'), findsNothing); // no suggestions
    expect(action(tester, 'Save').onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Gym 2');
    await tester.pump();
    expect(action(tester, 'Save').onPressed, isNotNull);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, 'Gym 2');
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('lays out without overflow at text scale $scale', (
      tester,
    ) async {
      await openSheet(tester, textScale: scale);

      expect(find.text('Give your playlist a name'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
