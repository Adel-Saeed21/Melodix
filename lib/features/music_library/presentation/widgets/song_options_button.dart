import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/add_to_playlist_sheet.dart';

enum _SongOption {
  playNext,
  addToQueue,
  favourite,
  addToPlaylist,
  goToAlbum,
  goToArtist,
  removeFromPlaylist,
  hide,
}

/// The ⋮ button on a song row with its compact options menu. Needs a
/// [SongActionsCubit] above it (see `SongActionsScope`).
class SongOptionsButton extends StatelessWidget {
  const SongOptionsButton({
    super.key,
    required this.song,
    this.showGoToAlbum = true,
    this.showGoToArtist = true,
    this.playlist,
  });

  final Song song;

  /// Off on the album's own page, where it would lead back to itself.
  final bool showGoToAlbum;

  /// Off on the artist's own page.
  final bool showGoToArtist;

  /// Set on a playlist's page to offer "Remove from playlist".
  final Playlist? playlist;

  Future<void> _onSelected(BuildContext context, _SongOption option) async {
    final cubit = context.read<SongActionsCubit>();
    switch (option) {
      case _SongOption.playNext:
      case _SongOption.addToQueue:
        // Enabled once the audio player is added.
        return;
      case _SongOption.favourite:
        await cubit.toggleFavorite(song);
      case _SongOption.addToPlaylist:
        await showAddToPlaylistSheet(context, songs: [song], cubit: cubit);
      case _SongOption.goToAlbum:
        final album = await cubit.albumFor(song);
        if (album != null && context.mounted) {
          await context.pushNamed(Routes.albumDetails, extra: album);
        }
      case _SongOption.goToArtist:
        final artist = await cubit.artistFor(song);
        if (artist != null && context.mounted) {
          await context.pushNamed(Routes.artistDetails, extra: artist);
        }
      case _SongOption.removeFromPlaylist:
        final playlist = this.playlist;
        if (playlist != null) await cubit.removeFromPlaylist(song, playlist);
      case _SongOption.hide:
        await cubit.hide(song);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return PopupMenuButton<_SongOption>(
      tooltip: AppStrings.songOptions,
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20.r,
        color: onSurface.withValues(alpha: 0.6),
      ),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      onSelected: (option) => _onSelected(context, option),
      itemBuilder: (context) => [
        _item(
          context,
          _SongOption.playNext,
          Icons.playlist_play_rounded,
          AppStrings.playNext,
          enabled: false,
        ),
        _item(
          context,
          _SongOption.addToQueue,
          Icons.queue_music_rounded,
          AppStrings.addToQueue,
          enabled: false,
        ),
        const PopupMenuDivider(),
        _item(
          context,
          _SongOption.favourite,
          song.isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          song.isFavorite
              ? AppStrings.removeFromFavourites
              : AppStrings.addToFavourites,
          highlight: song.isFavorite,
        ),
        _item(
          context,
          _SongOption.addToPlaylist,
          Icons.playlist_add_rounded,
          AppStrings.addToPlaylist,
        ),
        if (showGoToAlbum)
          _item(
            context,
            _SongOption.goToAlbum,
            Icons.album_rounded,
            AppStrings.goToAlbum,
          ),
        if (showGoToArtist)
          _item(
            context,
            _SongOption.goToArtist,
            Icons.person_rounded,
            AppStrings.goToArtist,
          ),
        const PopupMenuDivider(),
        if (playlist != null)
          _item(
            context,
            _SongOption.removeFromPlaylist,
            Icons.playlist_remove_rounded,
            AppStrings.removeFromPlaylist,
          ),
        _item(
          context,
          _SongOption.hide,
          Icons.visibility_off_rounded,
          AppStrings.hideFromLibrary,
        ),
      ],
    );
  }

  PopupMenuItem<_SongOption> _item(
    BuildContext context,
    _SongOption value,
    IconData icon,
    String label, {
    bool enabled = true,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.onSurface;
    final color = !enabled
        ? base.withValues(alpha: 0.35)
        : highlight
        ? theme.primaryColor
        : base;

    return PopupMenuItem<_SongOption>(
      value: value,
      enabled: enabled,
      height: 40.h,
      child: Row(
        children: [
          Icon(icon, size: 18.r, color: color),
          horizontalSpace(12),
          // Long labels shrink instead of overflowing the menu's max width
          // (e.g. with large system font sizes).
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: AppTextSizes.sm),
            ),
          ),
        ],
      ),
    );
  }
}
