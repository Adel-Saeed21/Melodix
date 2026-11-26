import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/utils/duration_format.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';
import 'package:melodix/features/player/presentation/widgets/current_song_builder.dart';
import 'package:melodix/features/player/presentation/widgets/equalizer_bars.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.leading,
  });

  final Song song;

  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  final Widget? trailing;

  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    // Marks the song the player is on: green title, bars over the cover.
    return CurrentSongBuilder(
      songId: song.id,
      builder: (context, isCurrent, isPlaying) =>
          _buildRow(context, isCurrent: isCurrent, isPlaying: isPlaying),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required bool isCurrent,
    required bool isPlaying,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.primaryColor;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          leading == null ? 20.w : 4.w,
          8.h,
          trailing == null ? 20.w : 4.w,
          8.h,
        ),
        child: Row(
          children: [
            ?leading,
            _Cover(song: song, isCurrent: isCurrent, isPlaying: isPlaying),
            horizontalSpace(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    semanticsLabel: isCurrent
                        ? '${song.title}, ${AppStrings.nowPlaying}'
                        : null,
                    style: TextStyle(
                      color: isCurrent ? primary : onSurface,
                      fontSize: AppTextSizes.base,
                      fontWeight: isCurrent
                          ? FontWeightHelper.bold
                          : FontWeightHelper.semiBold,
                    ),
                  ),
                  verticalSpace(3),
                  Text(
                    subtitle ?? song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: AppTextSizes.sm,
                    ),
                  ),
                ],
              ),
            ),
            horizontalSpace(12),
            Text(
              formatDuration(song.duration),
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: AppTextSizes.sm,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// The cover, with a dark overlay and equalizer bars when it's the current
/// song (bouncing while playing, still when paused).
class _Cover extends StatelessWidget {
  const _Cover({
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
