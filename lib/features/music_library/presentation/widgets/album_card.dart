import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';

class AlbumCard extends StatelessWidget {
  const AlbumCard({super.key, required this.album, this.onTap});

  final Album album;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.topCenter,
                child: SongArtwork(
                  songId: album.artworkSongId,
                  size: constraints.biggest.shortestSide,
                  placeholderIcon: Icons.album_rounded,
                ),
              ),
            ),
          ),
          verticalSpace(8),
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
          verticalSpace(2),
          Text(
            album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.6),
              fontSize: AppTextSizes.sm,
            ),
          ),
        ],
      ),
    );
  }
}
