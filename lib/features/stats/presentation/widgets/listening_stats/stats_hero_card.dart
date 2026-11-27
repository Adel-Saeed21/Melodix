import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/widgets/melodix_mark.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';
import 'package:melodix/features/stats/domain/listening_stats.dart';

class StatsHeroCard extends StatelessWidget {
  const StatsHeroCard({super.key, required this.stats});

  final ListeningStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (accent, second) = accentPair(context);
    final on = theme.colorScheme.onPrimary;
    final hours = stats.listened.inHours;
    final minutes = stats.listened.inMinutes % 60;
    Widget tile(String value, String label) => Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: on,
                fontSize: AppTextSizes.xl,
                fontWeight: FontWeightHelper.bold,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: on.withValues(alpha: 0.8),
              fontSize: AppTextSizes.xs,
            ),
          ),
        ],
      ),
    );
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26.r),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [accent, second],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MelodixMark(size: 26.r, color: on),
              SizedBox(width: 10.w),
              Text(
                context.l10n.yourMelodix,
                style: TextStyle(
                  color: on,
                  fontSize: AppTextSizes.lg,
                  fontWeight: FontWeightHelper.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            context.l10n.statsListened,
            style: TextStyle(color: on.withValues(alpha: 0.8)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              context.l10n.statsHours(hours, minutes),
              style: TextStyle(
                color: on,
                fontSize: 40.sp,
                height: 1.1,
                fontWeight: FontWeightHelper.bold,
              ),
            ),
          ),
          if (stats.topArtists.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              '${context.l10n.statsTopArtistLabel}: '
              '${stats.topArtists.first.artist}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: on,
                fontWeight: FontWeightHelper.semiBold,
              ),
            ),
          ],
          SizedBox(height: 18.h),
          Row(
            children: [
              tile('${stats.plays}', context.l10n.statsPlays),
              tile('${stats.songCount}', context.l10n.statsSongs),
              tile('${stats.favourites}', context.l10n.statsFavourites),
            ],
          ),
        ],
      ),
    );
  }
}
