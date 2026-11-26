import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:melodix/features/player/presentation/widgets/player_controls.dart';

void main() {
  for (final accent in [AppAccent.green, AppAccent.purple, AppAccent.yellow]) {
    testWidgets('the play button wears the ${accent.name} accent, readably', (
      tester,
    ) async {
      await tester.pumpWidget(
        AppScreenUtilInit(
          child: MaterialApp(
            theme: AppTheme.dark(accent),
            home: Scaffold(
              body: Center(
                child: PlayPauseButton(
                  isPlaying: false,
                  isLoading: false,
                  isCompleted: false,
                  size: 56,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      final disc = tester.widget<Material>(
        find.descendant(
          of: find.byType(PlayPauseButton),
          matching: find.byType(Material),
        ),
      );
      expect(disc.color, accent.color);
      final icon = tester.widget<Icon>(find.byIcon(Icons.play_arrow_rounded));
      expect(icon.color, accent.onColor);
    });
  }
}
