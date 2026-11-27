import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/features/lyrics/domain/entities/lyrics.dart';
import 'package:melodix/features/lyrics/presentation/logic/lyrics_cubit.dart';

/// Where the lyrics came from; lyrics from online can be removed (the
/// wrong song's).
class LyricsSourceRow extends StatelessWidget {
  const LyricsSourceRow({super.key, required this.lyrics});

  final Lyrics lyrics;

  @override
  Widget build(BuildContext context) {
    final faint = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.45);
    final label = switch (lyrics.source) {
      LyricsSource.embedded => context.l10n.lyricsFromFile,
      LyricsSource.file => context.l10n.lyricsFromLrc,
      LyricsSource.online => context.l10n.lyricsFromOnline,
    };
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(color: faint, fontSize: AppTextSizes.xs),
        ),
        if (lyrics.source == LyricsSource.online)
          TextButton(
            onPressed: context.read<LyricsCubit>().removeSaved,
            child: Text(
              context.l10n.lyricsRemove,
              style: TextStyle(fontSize: AppTextSizes.xs),
            ),
          ),
      ],
    );
  }
}
