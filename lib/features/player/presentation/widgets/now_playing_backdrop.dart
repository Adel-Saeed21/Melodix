import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/player/presentation/widgets/now_playing_backdrop/blurred_cover.dart';
import 'package:melodix/features/player/presentation/widgets/now_playing_backdrop/backdrop_glow.dart';

/// Behind Now Playing, as chosen in Settings: nothing (the app's
/// background), the song's cover blurred and dimmed, or the accent glow.
class NowPlayingBackdrop extends StatelessWidget {
  const NowPlayingBackdrop({super.key, required this.songId});

  final int songId;

  @override
  Widget build(BuildContext context) {
    final choice = UiPreferencesScope.of(context).nowPlayingBackground;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: switch (choice) {
        NowPlayingBackground.plain => const SizedBox.expand(
          key: ValueKey('plain'),
        ),
        NowPlayingBackground.cover => BlurredCover(
          key: ValueKey('cover-$songId'),
          songId: songId,
        ),
        NowPlayingBackground.glow => const BackdropGlow(key: ValueKey('glow')),
      },
    );
  }
}
