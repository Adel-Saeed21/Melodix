import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/features/video/presentation/widgets/library/continue_watching_row/continue_watching_card.dart';

/// Videos started but not finished, side by side, each resuming where it
/// stopped: a large thumbnail with a play button, the time left and a
/// progress bar, then the title and where it resumes.
class ContinueWatchingRow extends StatelessWidget {
  const ContinueWatchingRow({
    super.key,
    required this.videos,
    required this.progress,
    required this.onOpen,
  });

  final List<Video> videos;
  final Map<String, VideoProgress> progress;
  final void Function(List<Video> videos, int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final cardWidth = 220.r;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(20.w, 8.h, 20.w, 12.h),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 20.r,
                color: Theme.of(context).primaryColor,
              ),
              horizontalSpace(8),
              Text(
                context.l10n.continueWatching,
                style: TextStyle(
                  color: onSurface,
                  fontSize: AppTextSizes.lg,
                  fontWeight: FontWeightHelper.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          // Thumbnail + two lines of text (grows with the text size).
          height:
              cardWidth * 9 / 16 +
              56 * MediaQuery.textScalerOf(context).scale(1),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: videos.length,
            separatorBuilder: (_, _) => horizontalSpace(14),
            itemBuilder: (context, index) => ContinueWatchingCard(
              video: videos[index],
              progress: progress[videos[index].id],
              width: cardWidth,
              onTap: () => onOpen(videos, index),
            ),
          ),
        ),
      ],
    );
  }
}
