import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_dialogs.dart';

enum _PlaylistOption { rename, favourite, delete }

/// The ⋮ menu for a playlist: rename, favourite and delete. Needs a
/// [PlaylistsCubit] above it.
class PlaylistOptionsButton extends StatelessWidget {
  const PlaylistOptionsButton({
    super.key,
    required this.playlist,
    this.onDeleted,
  });

  final Playlist playlist;

  /// Called after the playlist was deleted, e.g. to leave its page.
  final VoidCallback? onDeleted;

  Future<void> _onSelected(BuildContext context, _PlaylistOption option) async {
    final cubit = context.read<PlaylistsCubit>();
    switch (option) {
      case _PlaylistOption.rename:
        final name = await showPlaylistNameDialog(
          context,
          title: AppStrings.renamePlaylist,
          actionLabel: AppStrings.save,
          initialName: playlist.name,
        );
        if (name != null && name != playlist.name) {
          await cubit.rename(playlist, name);
        }
      case _PlaylistOption.favourite:
        await cubit.toggleFavorite(playlist);
      case _PlaylistOption.delete:
        if (await confirmDeletePlaylist(context, playlist.name)) {
          await cubit.delete(playlist);
          onDeleted?.call();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    PopupMenuItem<_PlaylistOption> item(
      _PlaylistOption value,
      IconData icon,
      String label, {
      Color? color,
    }) {
      final c = color ?? onSurface;
      return PopupMenuItem(
        value: value,
        height: 40.h,
        child: Row(
          children: [
            Icon(icon, size: 18.r, color: c),
            horizontalSpace(12),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c, fontSize: AppTextSizes.sm),
              ),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<_PlaylistOption>(
      tooltip: AppStrings.playlistOptions,
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20.r,
        color: onSurface.withValues(alpha: 0.6),
      ),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      onSelected: (option) => _onSelected(context, option),
      itemBuilder: (_) => [
        item(_PlaylistOption.rename, Icons.edit_rounded, AppStrings.rename),
        item(
          _PlaylistOption.favourite,
          playlist.isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          playlist.isFavorite
              ? AppStrings.removeFromFavourites
              : AppStrings.addToFavourites,
          color: playlist.isFavorite ? theme.primaryColor : null,
        ),
        const PopupMenuDivider(),
        item(
          _PlaylistOption.delete,
          Icons.delete_outline_rounded,
          AppStrings.deletePlaylist,
          color: theme.colorScheme.error,
        ),
      ],
    );
  }
}
