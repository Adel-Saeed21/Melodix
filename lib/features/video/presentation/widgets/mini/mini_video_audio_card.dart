import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';
import 'package:melodix/features/video/presentation/widgets/mini/mini_video_card/mini_video_button.dart';
import 'package:melodix/features/video/presentation/widgets/player/engine_selector.dart';
import 'package:melodix/features/video/presentation/widgets/video_thumbnail.dart';

/// What the small window shows while the video is listened to as audio
/// (in place of [MiniVideoCard]): the thumbnail, the title, play / pause,
/// back to the video, close, and how far it got. The window around it
/// moves it, and opens the full player on a tap.
class MiniVideoAudioCard extends StatelessWidget {
  const MiniVideoAudioCard({
    super.key,
    required this.state,
    required this.onClose,
  });

  final VideoPlayerState state;
  final VoidCallback onClose;

  /// Its height in the window.
  static const double height = 64;

  /// The narrowest it's laid out: while the window reshapes (from the
  /// video's size), the card keeps this width and is clipped, rather than
  /// squeezing its buttons.
  static const double minWidth = 240;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E1E),
      elevation: 10,
      shadowColor: Colors.black,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth < minWidth
              ? minWidth
              : constraints.maxWidth;
          final tall = constraints.maxHeight < height
              ? height
              : constraints.maxHeight;
          return OverflowBox(
            alignment: AlignmentDirectional.centerStart,
            minWidth: width,
            maxWidth: width,
            minHeight: tall,
            maxHeight: tall,
            child: _content(context),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context) {
    final cubit = context.read<VideoPlayerCubit>();
    final engine = state.engine;
    return Stack(
      children: [
        Row(
          children: [
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox.square(
                dimension: 46,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: VideoThumbnail(
                    video: state.video,
                    width: 82,
                    showDuration: false,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTextSizes.sm,
                      fontWeight: FontWeightHelper.semiBold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.headphones_rounded,
                        size: 12,
                        color: Colors.white60,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          context.l10n.audioOnlyMode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: AppTextSizes.xs,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (engine != null)
              EngineSelector<bool>(
                engine: engine,
                select: (v) => v.isPlaying,
                builder: (context, playing) => MiniVideoButton(
                  icon: playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: playing ? context.l10n.pause : context.l10n.play,
                  onPressed: cubit.togglePlayPause,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
              ),
            MiniVideoButton(
              icon: Icons.ondemand_video_rounded,
              label: context.l10n.watchVideo,
              onPressed: () => cubit.setAudioOnly(false),
            ),
            MiniVideoButton(
              icon: Icons.close_rounded,
              label: context.l10n.closeVideo,
              onPressed: onClose,
            ),
            const SizedBox(width: 2),
          ],
        ),
        if (engine != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 2,
            child: _Progress(engine: engine),
          ),
      ],
    );
  }
}

/// How far it got, along the bottom edge.
class _Progress extends StatelessWidget {
  const _Progress({required this.engine});

  final VideoEngine engine;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<VideoEngineValue>(
        valueListenable: engine,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value.duration > Duration.zero
              ? value.position.inMilliseconds / value.duration.inMilliseconds
              : 0,
          minHeight: 2,
          backgroundColor: Colors.white24,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
