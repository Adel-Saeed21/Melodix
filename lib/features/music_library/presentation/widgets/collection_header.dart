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

  /// The cover's size: large on a tall screen; smaller on a phone on its
  /// side, beside the words, so the songs below still show.
  static double coverSize(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape
      ? 120.r
      : 200.r;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final align = landscape ? TextAlign.start : TextAlign.center;
    final cover =
        artwork ??
        SongArtwork(
          songId: artworkSongId,
          size: coverSize(context),
          circle: circle,
          placeholderIcon: placeholderIcon,
        );
    final words = [
      Text(
        title,
        textAlign: align,
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
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: AppTextSizes.base,
          fontWeight: FontWeightHelper.semiBold,
        ),
      ),
      verticalSpace(4),
      Text(
        details,
        textAlign: align,
        style: TextStyle(
          color: onSurface.withValues(alpha: 0.6),
          fontSize: AppTextSizes.sm,
        ),
      ),
    ];

    if (landscape) {
      return Padding(
        padding: EdgeInsetsDirectional.fromSTEB(24.w, 4.h, 24.w, 12.h),
        child: Row(
          children: [
            cover,
            horizontalSpace(24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: words,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 8.h, 20.w, 16.h),
      child: Column(children: [cover, verticalSpace(20), ...words]),
    );
  }
}
