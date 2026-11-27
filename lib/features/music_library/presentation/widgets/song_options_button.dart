import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:melodix/core/widgets/options_menu.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_selection_widgets.dart';
import 'package:melodix/features/music_library/presentation/logic/song_playback.dart';

enum _SongOption {
  playNext,
  addToQueue,
  favourite,
  addToPlaylist,
  goToAlbum,
  goToArtist,
  removeFromPlaylist,
  delete,
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
        await context.read<SongPlayback>().playNext([song]);
        if (context.mounted) {
          AppSnackBar.show(context, context.l10n.playsNext(1));
        }
      case _SongOption.addToQueue:
        await context.read<SongPlayback>().addToQueue([song]);
        if (context.mounted) {
          AppSnackBar.show(context, context.l10n.addedToQueue(1));
        }
      case _SongOption.favourite:
        await cubit.toggleFavorite(song);
      case _SongOption.addToPlaylist:
        await showAddToPlaylistSheet(context, songs: [song], cubit: cubit);
      case _SongOption.goToAlbum:
        final album = cubit.albumFor(song, _library(context));
        if (album != null) {
          await context.pushNamed(Routes.albumDetails, extra: album);
        }
      case _SongOption.goToArtist:
        final artist = cubit.artistFor(song, _library(context));
        if (artist != null) {
          await context.pushNamed(Routes.artistDetails, extra: artist);
        }
      case _SongOption.removeFromPlaylist:
        final playlist = this.playlist;
        if (playlist != null) await cubit.removeFromPlaylist(song, playlist);
      case _SongOption.delete:
        // Asks first; the result is said by the actions' feedback.
        if (await confirmDeleteSongs(context, 1)) {
          await cubit.deleteMany([song]);
        }
    }
  }

  static List<Song> _library(BuildContext context) =>
      context.read<MusicLibraryBloc>().state.songs;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return OptionsMenuButton<_SongOption>(
      tooltip: context.l10n.songOptions,
      padding: EdgeInsets.zero,
      onSelected: (option) => _onSelected(context, option),
      itemBuilder: (context) => [
        optionsMenuItem(
          context,
          value: _SongOption.playNext,
          icon: Icons.playlist_play_rounded,
          label: context.l10n.playNext,
        ),
        optionsMenuItem(
          context,
          value: _SongOption.addToQueue,
          icon: Icons.queue_music_rounded,
          label: context.l10n.addToQueue,
        ),
        const PopupMenuDivider(),
        optionsMenuItem(
          context,
          value: _SongOption.favourite,
          icon: song.isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: song.isFavorite
              ? context.l10n.removeFromFavourites
              : context.l10n.addToFavourites,
          color: song.isFavorite ? primary : null,
        ),
        optionsMenuItem(
          context,
          value: _SongOption.addToPlaylist,
          icon: Icons.playlist_add_rounded,
          label: context.l10n.addToPlaylist,
        ),
        if (showGoToAlbum)
          optionsMenuItem(
            context,
            value: _SongOption.goToAlbum,
            icon: Icons.album_rounded,
            label: context.l10n.goToAlbum,
          ),
        if (showGoToArtist)
          optionsMenuItem(
            context,
            value: _SongOption.goToArtist,
            icon: Icons.person_rounded,
            label: context.l10n.goToArtist,
          ),
        const PopupMenuDivider(),
        if (playlist != null)
          optionsMenuItem(
            context,
            value: _SongOption.removeFromPlaylist,
            icon: Icons.playlist_remove_rounded,
            label: context.l10n.removeFromPlaylist,
          ),
        if (context.read<SongActionsCubit>().canDeleteSongs)
          optionsMenuItem(
            context,
            value: _SongOption.delete,
            icon: Icons.delete_outline_rounded,
            label: context.l10n.deleteFromPhone,
            color: Theme.of(context).colorScheme.error,
          ),
      ],
    );
  }
}
