import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/player/engine_selector.dart';
import 'package:melodix/features/video/presentation/widgets/video_thumbnail.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';

/// What the small window shows: the video (or its thumbnail while it
/// loads), play / pause, close, and how far it got.
class MiniVideoCard extends StatelessWidget {
  const MiniVideoCard({super.key, required this.state, required this.onClose});

  final VideoPlayerState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final engine = state.engine;
    return Material(
      color: Colors.black,
      elevation: 10,
      shadowColor: Colors.black,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The picture in its own layer: the buttons never repaint it.
          RepaintBoundary(
            child: switch (state.status) {
              VideoPlayerStatus.ready when engine != null => engine.buildView(),
              VideoPlayerStatus.failed => const Center(
                child: Icon(Icons.error_outline_rounded, color: Colors.white70),
              ),
              _ => Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: LayoutBuilder(
                      builder: (context, c) => VideoThumbnail(
                        video: state.video,
                        width: c.maxWidth,
                        showDuration: false,
                      ),
                    ),
                  ),
                  const Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            },
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _SmallButton(
              icon: Icons.close_rounded,
              label: AppStrings.closeVideo,
              onPressed: onClose,
            ),
          ),
          if (engine != null) ...[
            Positioned(
              left: 0,
              bottom: 4,
              child: EngineSelector<bool>(
                engine: engine,
                select: (v) => v.isPlaying,
                builder: (context, playing) => _SmallButton(
                  icon: playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: playing ? AppStrings.pause : AppStrings.play,
                  onPressed: context.read<VideoPlayerCubit>().togglePlayPause,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 3,
              child: ValueListenableBuilder<VideoEngineValue>(
                valueListenable: engine,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value.duration > Duration.zero
                      ? value.position.inMilliseconds /
                            value.duration.inMilliseconds
                      : 0,
                  minHeight: 3,
                  backgroundColor: Colors.white24,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small round button on a dark dot, readable on any picture. (No
/// tooltip: the window floats above the app's navigator, where tooltips
/// have no overlay to draw in; the label is for screen readers.)
class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
