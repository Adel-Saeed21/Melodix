import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/features/navigation/presentation/widgets/glass_nav_bar.dart';

const _items = [
  GlassNavItem(
    icon: Icons.library_music_outlined,
    activeIcon: Icons.library_music_rounded,
    label: 'Music',
  ),
  GlassNavItem(
    icon: Icons.video_library_outlined,
    activeIcon: Icons.video_library_rounded,
    label: 'Video',
  ),
  GlassNavItem(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Settings',
  ),
];

Widget _host({
  required ThemeData theme,
  double keyboardInset = 0,
  ValueChanged<int>? onTap,
  Axis axis = Axis.horizontal,
}) {
  return AppScreenUtilInit(
    child: MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(viewInsets: EdgeInsets.only(bottom: keyboardInset)),
          child: Scaffold(
            extendBody: true,
            body: axis == Axis.vertical
                ? Row(
                    children: [
                      Center(
                        child: GlassNavBar(
                          items: _items,
                          currentIndex: 0,
                          onTap: onTap ?? (_) {},
                          axis: Axis.vertical,
                        ),
                      ),
                      const Expanded(child: SizedBox.expand()),
                    ],
                  )
                : const SizedBox.expand(),
            bottomNavigationBar: axis == Axis.vertical
                ? null
                : GlassNavBar(
                    items: _items,
                    currentIndex: 0,
                    onTap: onTap ?? (_) {},
                  ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final entry in {
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
  }.entries) {
    testWidgets('shows all destinations in ${entry.key} mode', (tester) async {
      await tester.pumpWidget(_host(theme: entry.value));
      await tester.pumpAndSettle();

      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      // Music is selected, so it shows the filled icon.
      expect(find.byIcon(Icons.library_music_rounded), findsOneWidget);
    });
  }

  testWidgets('reports the tapped destination', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      _host(theme: AppTheme.lightTheme, onTap: (i) => tapped = i),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    expect(tapped, 2);
  });

  testWidgets('hides while the keyboard is open', (tester) async {
    await tester.pumpWidget(
      _host(theme: AppTheme.lightTheme, keyboardInset: 300),
    );
    await tester.pumpAndSettle();

    expect(find.text('Music'), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);

    await tester.pumpWidget(_host(theme: AppTheme.lightTheme));
    await tester.pumpAndSettle();

    expect(find.text('Music'), findsOneWidget);
  });

  testWidgets('sideways: a rail down the left, fitting the short screen', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(2400, 1080)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    var tapped = -1;
    await tester.pumpWidget(
      _host(
        theme: AppTheme.darkTheme,
        axis: Axis.vertical,
        onTap: (i) => tapped = i,
      ),
    );
    await tester.pumpAndSettle();

    final music = tester.getRect(find.text('Music'));
    final video = tester.getRect(find.text('Video'));
    final settings = tester.getRect(find.text('Settings'));
    expect(video.top, greaterThan(music.bottom)); // one above the other
    expect(settings.top, greaterThan(video.bottom));
    expect(music.left, lessThan(120)); // on the left edge
    expect(settings.bottom, lessThan(360));

    await tester.tap(find.text('Settings'));
    expect(tapped, 2);
  });
}
