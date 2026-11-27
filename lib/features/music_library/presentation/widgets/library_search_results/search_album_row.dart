import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';

class SearchAlbumRow extends StatelessWidget {
  const SearchAlbumRow({super.key, required this.album, required this.onTap});

  final Album album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Row(
          children: [
            SongArtwork(
              songId: album.artworkSongId,
              size: 52.r,
              placeholderIcon: Icons.album_rounded,
            ),
            horizontalSpace(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: AppTextSizes.base,
                      fontWeight: FontWeightHelper.semiBold,
                    ),
                  ),
                  verticalSpace(3),
                  Text(
                    '${album.artist} · ${AppStrings.songsCount(album.songCount)}',
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
            Icon(
              Icons.chevron_right_rounded,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
