import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/config/theme/theme_cubit/theme_cubit.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/core/service/app_icon_service.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';
import 'package:melodix/features/player/presentation/logic/sleep_timer_cubit.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:melodix/features/settings/presentation/pages/settings_page.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements Storage {}

class MockPlayer extends Mock implements PlayerRepository {}

void main() {
  late UiPreferencesCubit preferences;
  late AudioSettingsCubit audio;
  late SleepTimerCubit sleep;
  late AppIconCubit icons;

  setUp(() {
    final storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    preferences = UiPreferencesCubit();
    audio = AudioSettingsCubit();
    final player = MockPlayer();
    when(() => player.current).thenReturn(NowPlaying.idle);
    sleep = SleepTimerCubit(player);
    // A phone that can switch icons; it answers "classic".
    icons = AppIconCubit(_FakeIcons());
  });

  tearDown(() async {
    await preferences.close();
    await audio.close();
    await sleep.close();
    await icons.close();
  });

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
          BlocProvider.value(value: audio),
          BlocProvider.value(value: sleep),
          BlocProvider.value(value: icons),
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

  /// Lets animations (the swatches, the previews) finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Scrolls [finder] fully into view (not just peeking in at an edge).
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      // The page itself (not the sideways list of app icons).
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await settle(tester);
  }

  testWidgets('theme: the little phones pick dark / light / the phone', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Theme'), findsOneWidget);
    final theme = tester.element(find.text('Theme')).read<ThemeCubit>();
    expect(theme.state, ThemeMode.dark);

    await tester.tap(find.text('Light'));
    await tester.pump();
    expect(theme.state, ThemeMode.light);
    await tester.tap(find.text('Auto'));
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
    await settle(tester);
    expect(preferences.state.accent, AppAccent.purple);
    expect(find.text('Purple'), findsOneWidget);
  });

  testWidgets('music bar: the 3 designs drawn; Classic at first; a tap picks', (
    tester,
  ) async {
    await pump(tester);
    await reveal(tester, find.text('Minimal'));
    for (final name in ['Classic', 'Capsule', 'Minimal']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(isSelected(tester, find.text('Classic')), isTrue);
    expect(find.text('Title, controls and a seek bar'), findsOneWidget);

    await tester.tap(find.text('Capsule'));
    await settle(tester);
    expect(preferences.state.miniPlayer, MiniPlayerStyle.capsule);
    expect(isSelected(tester, find.text('Capsule')), isTrue);
    expect(find.text('A floating pill with a progress ring'), findsOneWidget);

    await tester.tap(find.text('Minimal'));
    await tester.pump();
    expect(preferences.state.miniPlayer, MiniPlayerStyle.minimal);
  });

  testWidgets('selection actions: bottom or right side', (tester) async {
    await pump(tester);
    await reveal(tester, find.text('Right side'));
    expect(isSelected(tester, find.text('Bottom')), isTrue);
    await tester.tap(find.text('Right side'));
    await tester.pump();
    expect(preferences.state.selectionBar, SelectionBarStyle.side);

    await tester.tap(find.text('Bottom'));
    await tester.pump();
    expect(preferences.state.selectionBar, SelectionBarStyle.bottom);
  });

  testWidgets('video skip length: a tap on a pill picks it', (tester) async {
    await pump(tester);
    await reveal(tester, find.text('30s'));
    expect(isSelected(tester, find.text('10s')), isTrue);
    await tester.tap(find.text('30s'));
    await tester.pump();
    expect(preferences.state.videoSeekSeconds, 30);
  });

  testWidgets('accent: "From the cover" follows the playing song', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byTooltip('From the cover'));
    await tester.pump();
    expect(preferences.state.dynamicAccent, isTrue);
    expect(
      find.text("The playing song's cover colours the app"),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Teal'));
    await tester.pump();
    expect(preferences.state.dynamicAccent, isFalse);
  });

  testWidgets('app icon: a tap switches it on the phone', (tester) async {
    await pump(tester);
    await reveal(tester, find.byTooltip('Purple icon'));
    await tester.tap(find.byTooltip('Purple icon'));
    await settle(tester);
    expect(icons.state, LauncherIcon.purple);
  });

  testWidgets('playback: speed and skip silence', (tester) async {
    await pump(tester);
    await reveal(tester, find.text('1.5×'));
    await tester.tap(find.text('1.5×'));
    await tester.pump();
    expect(audio.state.speed, 1.5);
    await reveal(tester, find.text('Skip silence'));
    await tester.tap(find.text('Skip silence'));
    await tester.pump();
    expect(audio.state.skipSilence, isTrue);
  });

  testWidgets('subtitles: size, style and colour show in the preview', (
    tester,
  ) async {
    await pump(tester);
    await reveal(tester, find.text('Huge'));
    await tester.tap(find.text('Huge'));
    await tester.tap(find.text('Outline'));
    await tester.tap(find.text('Yellow').last);
    await tester.pump();
    expect(preferences.state.subtitleSize, SubtitleSize.huge);
    expect(preferences.state.subtitleLook, SubtitleLook.outline);
    expect(preferences.state.subtitleColor, SubtitleColor.yellow);
    final caption = tester.widget<Text>(find.text('This is how captions look'));
    expect(caption.style!.color, const Color(0xffFFE14D));
  });

  testWidgets('removed rows are gone', (tester) async {
    await pump(tester);
    await reveal(tester, find.text('Music filters'));
    for (final gone in [
      'Start on',
      'Search language',
      'Hidden songs',
      'General',
      'Replay the intro',
      'Reset look',
    ]) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
  });

  testWidgets('fits a phone on its side', (tester) async {
    await pump(tester);
    tester.view.physicalSize = const Size(2400, 1080);
    await settle(tester);
    expect(find.text('Theme'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeIcons extends AppIconService {
  _FakeIcons() : super(supported: true);

  LauncherIcon icon = LauncherIcon.classic;

  @override
  Future<LauncherIcon> current() async => icon;

  @override
  Future<bool> set(LauncherIcon icon) async {
    this.icon = icon;
    return true;
  }
}
