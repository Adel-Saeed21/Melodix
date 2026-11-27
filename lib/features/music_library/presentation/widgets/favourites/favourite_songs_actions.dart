import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/music_library/presentation/logic/song_playback.dart';

/// "12 songs · 48 min" with Shuffle and Play, above the favourite songs.
class FavouriteSongsActions extends StatelessWidget {
  const FavouriteSongsActions({super.key, required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    final player = context.read<SongPlayback>();
    final theme = Theme.of(context);
    final total = songs.fold(Duration.zero, (sum, s) => sum + s.duration);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 12.h, 16.w, 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${context.l10n.songsCount(songs.length)} · '
              '${formatTotalDuration(total)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: AppTextSizes.sm,
                fontWeight: FontWeightHelper.medium,
              ),
            ),
          ),
          IconButton.filledTonal(
            tooltip: context.l10n.shufflePlay,
            onPressed: () =>
                player.shufflePlay(songs, title: context.l10n.favourites),
            icon: const Icon(Icons.shuffle_rounded),
          ),
          horizontalSpace(8),
          IconButton.filled(
            tooltip: context.l10n.playAll,
            style: IconButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            onPressed: () =>
                player.playSongs(songs, 0, title: context.l10n.favourites),
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}
