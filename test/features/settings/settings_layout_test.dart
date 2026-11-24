import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/config/theme/theme_cubit/theme_cubit.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:melodix/features/settings/presentation/pages/settings_page.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements Storage {}

void main() {
  late UiPreferencesCubit preferences;

  setUp(() {
    final storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    preferences = UiPreferencesCubit();
  });

  tearDown(() => preferences.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider.value(value: preferences),
        ],
        child: AppScreenUtilInit(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SettingsPage(),
          ),
        ),
      ),
    );
  }

  bool isSelected(WidgetTester tester, Finder finder) => tester
      .widgetList<Semantics>(
        find.ancestor(of: finder, matching: find.byType(Semantics)),
      )
      .any((s) => s.properties.selected ?? false);

  testWidgets('theme: a compact light / dark / phone toggle', (tester) async {
    await pump(tester);
    expect(find.text('Theme'), findsOneWidget);
    final theme = tester.element(find.text('Theme')).read<ThemeCubit>();
    expect(theme.state, ThemeMode.dark);

    await tester.tap(find.byTooltip('Light'));
    await tester.pump();
    expect(theme.state, ThemeMode.light);
    await tester.tap(find.byTooltip('Same as the phone'));
    await tester.pump();
    expect(theme.state, ThemeMode.system);
  });

  testWidgets('accent colour: green at first; a tap picks another', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Green'), findsOneWidget); // the current one, named
    for (final accent in AppAccent.values) {
      expect(
        find.byTooltip(accent.label),
        findsOneWidget,
        reason: accent.label,
      );
    }

    await tester.tap(find.byTooltip('Purple'));
    await tester.pump();
    expect(preferences.state.accent, AppAccent.purple);
    expect(find.text('Purple'), findsOneWidget);
  });

  testWidgets('music bar: the 3 designs; Classic at first; a tap picks', (
    tester,
  ) async {
    await pump(tester);
    for (final name in ['Classic', 'Capsule', 'Minimal']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(isSelected(tester, find.text('Classic')), isTrue);
    expect(find.text('Title, controls and a seek bar'), findsOneWidget);

    await tester.tap(find.text('Capsule'));
    await tester.pump();
    expect(preferences.state.miniPlayer, MiniPlayerStyle.capsule);
    expect(find.text('A floating pill with a progress ring'), findsOneWidget);

    await tester.tap(find.text('Minimal'));
    await tester.pump();
    expect(preferences.state.miniPlayer, MiniPlayerStyle.minimal);
  });

  testWidgets('selection actions: bottom or right side', (tester) async {
    await pump(tester);
    await tester.scrollUntilVisible(find.byTooltip('Right side'), 100);
    await tester.tap(find.byTooltip('Right side'));
    await tester.pump();
    expect(preferences.state.selectionBar, SelectionBarStyle.side);

    await tester.tap(find.byTooltip('Bottom'));
    await tester.pump();
    expect(preferences.state.selectionBar, SelectionBarStyle.bottom);
  });

  testWidgets('fits a phone on its side', (tester) async {
    await pump(tester);
    tester.view.physicalSize = const Size(2400, 1080);
    await tester.pumpAndSettle();
    expect(find.text('Theme'), findsOneWidget);
  });
}
