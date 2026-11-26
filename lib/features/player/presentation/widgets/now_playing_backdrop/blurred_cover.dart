import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';

class BlurredCover extends StatelessWidget {
  const BlurredCover({super.key, required this.songId});

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
