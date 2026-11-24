import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:melodix/core/widgets/library_status_view.dart';

void main() {
  testWidgets('the button stays above the bars the page runs behind', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    const bars = 160.0; // nav bar + music mini player
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            // As the home screen: pages extend behind the bottom bars.
            extendBody: true,
            body: LibraryStatusView(
              icon: Icons.queue_music_rounded,
              title: 'No playlists yet',
              message: 'Create one to group your favourite songs.',
              actionLabel: 'New playlist',
              onAction: () {},
            ),
            bottomNavigationBar: const SizedBox(height: bars),
          ),
        ),
      ),
    );

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final visibleBottom = screen.height - bars;
    final button = tester.getRect(find.text('New playlist'));
    expect(button.bottom, lessThan(visibleBottom));
    // Centred in what shows, not in the whole page.
    final icon = tester.getRect(find.byIcon(Icons.queue_music_rounded));
    final middle = (icon.top + button.bottom) / 2;
    expect(middle, closeTo(visibleBottom / 2, 30));
  });
}
