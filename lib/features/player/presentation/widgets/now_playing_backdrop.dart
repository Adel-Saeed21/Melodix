import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/core/widgets/glow_background.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';

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
        NowPlayingBackground.cover => _BlurredCover(
          key: ValueKey('cover-$songId'),
          songId: songId,
        ),
        NowPlayingBackground.glow => const _Glow(key: ValueKey('glow')),
      },
    );
  }
}

class _BlurredCover extends StatelessWidget {
  const _BlurredCover({super.key, required this.songId});

  final int songId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) => ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: OverflowBox(
                maxWidth: constraints.biggest.longestSide * 1.3,
                maxHeight: constraints.biggest.longestSide * 1.3,
                child: SongArtwork(
                  songId: songId,
                  // Small is enough under this much blur.
                  size: constraints.biggest.longestSide * 1.3,
                ),
              ),
            ),
            // Dimmed so the text and controls stay readable.
            ColoredBox(
              color: theme.scaffoldBackgroundColor.withValues(
                alpha: dark ? 0.62 : 0.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatefulWidget {
  const _Glow({super.key});

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _time.stop();
    } else if (!_time.isAnimating) {
      unawaited(_time.repeat());
    }
  }

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      GlowBackground(time: _time, progress: const AlwaysStoppedAnimation(0));
}
