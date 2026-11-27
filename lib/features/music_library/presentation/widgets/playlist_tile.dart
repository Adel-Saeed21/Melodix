import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_options_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';

class PlaylistTile extends StatelessWidget {
  const PlaylistTile({super.key, required this.playlist, this.onTap});

  final Playlist playlist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(20.w, 8.h, 4.w, 8.h),
        child: Row(
          children: [
            PlaylistCover(playlist: playlist, size: 52.r),
            horizontalSpace(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: AppTextSizes.base,
                      fontWeight: FontWeightHelper.semiBold,
                    ),
                  ),
                  verticalSpace(3),
                  Row(
                    children: [
                      if (playlist.isFavorite) ...[
                        Icon(
                          Icons.favorite_rounded,
                          size: 12.r,
                          color: theme.primaryColor,
                        ),
                        horizontalSpace(4),
                      ],
                      Flexible(
                        child: Text(
                          context.l10n.songsCount(playlist.songCount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.6),
                            fontSize: AppTextSizes.sm,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PlaylistOptionsButton(playlist: playlist),
          ],
        ),
      ),
    );
  }
}

/// The playlist's first song cover, or a playlist icon when it's empty.
class PlaylistCover extends StatelessWidget {
  const PlaylistCover({super.key, required this.playlist, required this.size});

  final Playlist playlist;
  final double size;

  @override
  Widget build(BuildContext context) {
    final artworkSongId = playlist.artworkSongId;
    if (artworkSongId != null) {
      return SongArtwork(
        songId: artworkSongId,
        size: size,
        placeholderIcon: Icons.queue_music_rounded,
      );
    }
    final primary = Theme.of(context).primaryColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.18),
      ),
      child: Icon(Icons.queue_music_rounded, color: primary, size: size * 0.45),
    );
  }
}
