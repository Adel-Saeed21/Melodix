import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/config/theme/theme_cubit/theme_cubit.dart';
import 'package:melodix/core/service/onboarding_service.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:melodix/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements Storage {}

void main() {
  late Map<String, dynamic> stored;
  late ThemeCubit theme;
  late int finished;

  setUp(() {
    stored = {};
    final storage = MockStorage();
    when(() => storage.read(any()))
        .thenAnswer((i) => stored[i.positionalArguments.first]);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((i) async {
      stored[i.positionalArguments[0] as String] = i.positionalArguments[1];
    });
    HydratedBloc.storage = storage;
    theme = ThemeCubit();
    finished = 0;
  });

  tearDown(() => theme.close());

  final boundary = GlobalKey();

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider.value(
        value: theme,
        child: AppScreenUtilInit(
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) => MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: mode,
              home: RepaintBoundary(
                key: boundary,
                child: OnboardingPage(onFinished: () => finished++),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// The animations loop forever: settle by time, not pumpAndSettle.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Next'));
    await settle(tester);
  }

  testWidgets('describes the app, page by page', (tester) async {
    await pump(tester);
    expect(find.text('All your music,\nbeautifully organised'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await next(tester);
    expect(find.text('Videos that\nkeep up with you'), findsOneWidget);
    await next(tester);
    expect(find.text('Subtitles,\neven offline'), findsOneWidget);
    await next(tester);
    expect(find.text('Choose your look'), findsOneWidget);
    expect(find.bySemanticsLabel('Start listening'), findsOneWidget);
  });

  testWidgets('swiping works too', (tester) async {
    await pump(tester);
    await tester.drag(find.byType(PageView), const Offset(-250, 0));
    await settle(tester);
    expect(find.text('Videos that\nkeep up with you'), findsOneWidget);
  });

  testWidgets('skip goes straight to the look', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Skip'));
    await settle(tester);
    expect(find.text('Choose your look'), findsOneWidget);
    expect(finished, 0); // the look is still to choose
  });

  testWidgets('back goes to the previous page', (tester) async {
    await pump(tester);
    await next(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('All your music,\nbeautifully organised'), findsOneWidget);
  });

  testWidgets('choosing a look applies it at once; finishing saves', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Skip'));
    await settle(tester);
    expect(theme.state, ThemeMode.dark); // the app's default

    await tester.tap(find.bySemanticsLabel('Light'));
    await settle(tester);
    expect(theme.state, ThemeMode.light);
    expect(
      Theme.of(tester.element(find.text('Choose your look'))).brightness,
      Brightness.light,
    );
    await tester.tap(find.bySemanticsLabel('Auto'));
    await settle(tester);
    expect(theme.state, ThemeMode.system);

    expect(OnboardingService.isCompleted, isFalse);
    await tester.tap(find.bySemanticsLabel('Start listening'));
    await settle(tester);
    expect(OnboardingService.isCompleted, isTrue);
    expect(finished, 1);
  });

  testWidgets('with animations off it still works (still pictures)', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pump(tester);
    await next(tester);
    expect(find.text('Videos that\nkeep up with you'), findsOneWidget);
  });

  // Saves each page as a PNG (with the app's font) to look at the design:
  // ONBOARDING_PREVIEW=/some/dir flutter test test/features/onboarding
  final previewDir = Platform.environment['ONBOARDING_PREVIEW'];
  testWidgets('preview', skip: previewDir == null, (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('Satoshi');
      for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
        loader.addFont(
          File('assets/fonts/Satoshi-$w.otf')
              .readAsBytes()
              .then((b) => ByteData.sublistView(b)),
        );
      }
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(_materialIcons().then((b) => ByteData.sublistView(b)));
      await icons.load();
    });
    await pump(tester);
    Future<void> shot(String name) async {
      await settle(tester);
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 1);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$previewDir/$name.png')
            .writeAsBytes(png!.buffer.asUint8List());
      });
    }

    await shot('1_music');
    await next(tester);
    await shot('2_video');
    await next(tester);
    await shot('3_subtitles');
    await next(tester);
    await shot('4_look_dark');
    await tester.tap(find.bySemanticsLabel('Light'));
    await shot('5_look_light');
  });
}

Future<Uint8List> _materialIcons() async {
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  return File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytes();
}
