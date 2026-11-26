import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/core/widgets/whole_pixel_height.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/video_thumbnail.dart';

/// The list being played, from the player: the current video marked; tap
/// another to play it.
Future<void> showVideoUpNext(BuildContext context) {
  final cubit = context.read<VideoPlayerCubit>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xF0141414),
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.7,
    ),
    builder: (_) => BlocProvider.value(value: cubit, child: const _UpNext()),
  );
}

class _UpNext extends StatefulWidget {
  const _UpNext();

  @override
  State<_UpNext> createState() => _UpNextState();
}

class _UpNextState extends State<_UpNext> {
  static double get _rowHeight => 76.r;

  /// One for the sheet's life: opens at the current video, then keeps where
  /// the user scrolled (also when the list changes while it's open).
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset:
        context.read<VideoPlayerCubit>().state.index * _rowHeight,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
      buildWhen: (p, c) => p.queue != c.queue || p.index != c.index,
      builder: (context, state) {
        final queue = state.queue;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
              child: Text(
                '${AppStrings.upNext} · '
                '${AppStrings.videoPosition(state.index + 1, queue.length)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTextSizes.lg,
                  fontWeight: FontWeightHelper.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                controller: _scroll,
                itemCount: queue.length,
                itemExtent: _rowHeight,
                itemBuilder: (context, index) {
                  final video = queue[index];
                  final current = index == state.index;
                  return WholePixelHeight(
                    child: InkWell(
                      onTap: current
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              context.read<VideoPlayerCubit>().playAt(index);
                            },
                      child: Container(
                        color: current
                            ? Theme.of(context).primaryColor
                                  .withValues(alpha: 0.16)
                            : null,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.r,
                        ),
                        child: Row(
                          children: [
                            VideoThumbnail(video: video, width: 104.r),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    video.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: AppTextSizes.base,
                                      fontWeight: current
                                          ? FontWeightHelper.bold
                                          : FontWeightHelper.medium,
                                    ),
                                  ),
                                  Text(
                                    current
                                        ? AppStrings.nowPlayingVideo
                                        : formatDuration(video.duration),
                                    style: TextStyle(
                                      color: current
                                          ? Theme.of(context).primaryColor
                                          : Colors.white60,
                                      fontSize: AppTextSizes.sm,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 8.h),
          ],
        );
      },
    );
  }
}
