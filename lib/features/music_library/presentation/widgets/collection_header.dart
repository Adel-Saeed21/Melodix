import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';

/// Large artwork, title and details at the top of an album / artist page.
class CollectionHeader extends StatelessWidget {
  const CollectionHeader({
    super.key,
    required this.artworkSongId,
    required this.title,
    required this.subtitle,
    required this.details,
    this.circle = false,
    this.placeholderIcon = Icons.album_rounded,
    this.artwork,
  });

  final int artworkSongId;
  final String title;
  final String subtitle;
  final String details;
  final bool circle;
  final IconData placeholderIcon;

  /// Replaces the song artwork (e.g. a playlist cover).
  final Widget? artwork;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
      child: Column(
        children: [
          artwork ??
              SongArtwork(
                songId: artworkSongId,
                size: 200.r,
                circle: circle,
                placeholderIcon: placeholderIcon,
              ),
          verticalSpace(20),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onSurface,
              fontSize: AppTextSizes.xl,
              fontWeight: FontWeightHelper.bold,
            ),
          ),
          verticalSpace(4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: AppTextSizes.base,
              fontWeight: FontWeightHelper.semiBold,
            ),
          ),
          verticalSpace(4),
          Text(
            details,
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
