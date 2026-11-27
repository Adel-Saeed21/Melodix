import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/lyrics/presentation/logic/lyrics_clock.dart';
import 'package:melodix/features/lyrics/presentation/logic/lyrics_cubit.dart';
import 'package:melodix/features/lyrics/presentation/widgets/lyrics_view/lyrics_message.dart';
import 'package:melodix/features/lyrics/presentation/widgets/lyrics_view/lyrics_lines.dart';

/// The playing song's lyrics, in place of the cover on Now Playing.
/// Synced lyrics follow the song (the line being sung lit and kept in
/// view; tap a line to jump there); plain lyrics scroll freely.
///
/// Needs a [LyricsCubit] and a [LyricsClock] (the song's position) above.
class LyricsView extends StatelessWidget {
  const LyricsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LyricsCubit, LyricsState>(
      builder: (context, state) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (state.status) {
          LyricsStatus.loading || LyricsStatus.searching => LyricsMessage(
            key: ValueKey(state.status),
            icon: Icons.lyrics_rounded,
            text: state.status == LyricsStatus.searching
                ? AppStrings.lyricsSearching
                : null,
            busy: true,
          ),
          LyricsStatus.found => LyricsLines(
            key: ValueKey(state.songId),
            lyrics: state.lyrics!,
          ),
          LyricsStatus.none => LyricsMessage(
            key: const ValueKey('none'),
            icon: Icons.lyrics_outlined,
            text: AppStrings.lyricsNone,
            searchOnline: true,
          ),
          LyricsStatus.notFound => LyricsMessage(
            key: const ValueKey('notFound'),
            icon: Icons.search_off_rounded,
            text: AppStrings.lyricsNotFound,
          ),
          LyricsStatus.failed => LyricsMessage(
            key: const ValueKey('failed'),
            icon: Icons.wifi_off_rounded,
            text: AppStrings.lyricsFailed,
            searchOnline: true,
          ),
        },
      ),
    );
  }
}
