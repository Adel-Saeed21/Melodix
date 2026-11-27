import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';
import 'package:melodix/features/player/presentation/widgets/equalizer_bars.dart';

/// The cover, with a dark overlay and equalizer bars when it's the current
/// song (bouncing while playing, still when paused).
class SongTileCover extends StatelessWidget {
  const SongTileCover({
    super.key,
    required this.song,
    required this.isCurrent,
    required this.isPlaying,
  });

  final Song song;
  final bool isCurrent;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final size = 48.r;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SongArtwork(songId: song.id, size: size),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isCurrent ? 1 : 0,
            child: isCurrent
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(size * 0.18),
                    ),
                    child: Center(
                      child: EqualizerBars(
                        animate: isPlaying,
                        color: Theme.of(context).primaryColor,
                        size: size * 0.42,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
