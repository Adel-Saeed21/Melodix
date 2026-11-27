import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/core/widgets/options_menu.dart';
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
          title: context.l10n.renamePlaylist,
          actionLabel: context.l10n.save,
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
    return OptionsMenuButton<_PlaylistOption>(
      tooltip: context.l10n.playlistOptions,
      onSelected: (option) => _onSelected(context, option),
      itemBuilder: (context) => [
        optionsMenuItem(
          context,
          value: _PlaylistOption.rename,
          icon: Icons.edit_rounded,
          label: context.l10n.rename,
        ),
        optionsMenuItem(
          context,
          value: _PlaylistOption.favourite,
          icon: playlist.isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: playlist.isFavorite
              ? context.l10n.removeFromFavourites
              : context.l10n.addToFavourites,
          color: playlist.isFavorite ? theme.primaryColor : null,
        ),
        const PopupMenuDivider(),
        optionsMenuItem(
          context,
          value: _PlaylistOption.delete,
          icon: Icons.delete_outline_rounded,
          label: context.l10n.deletePlaylist,
          color: theme.colorScheme.error,
        ),
      ],
    );
  }
}
