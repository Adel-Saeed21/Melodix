import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_cue.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitles_cubit.dart';
import 'package:melodix/features/subtitles/presentation/widgets/subtitle_text.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';
import 'package:melodix/features/video/presentation/widgets/player/engine_selector.dart';

/// The caption showing now, over the bottom of the video. Rebuilds only
/// when the caption changes (not on every position tick); touches pass
/// through to the controls.
class SubtitleOverlay extends StatelessWidget {
  const SubtitleOverlay({super.key, required this.engine});

  final VideoEngine engine;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: BlocSelector<SubtitlesCubit, SubtitlesState, SubtitleTimeline>(
        selector: (state) => state.timeline,
        builder: (context, timeline) {
          if (timeline.isEmpty) return const SizedBox.shrink();
          return EngineSelector<String?>(
            engine: engine,
            select: (v) => timeline.textAt(v.position),
            builder: (context, text) => text == null
                ? const SizedBox.shrink()
                : SubtitleText(text: text),
          );
        },
      ),
    );
  }
}
