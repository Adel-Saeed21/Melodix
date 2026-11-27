import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_header.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_tile.dart';

class PlaylistDetailsHeader extends StatelessWidget {
  const PlaylistDetailsHeader({
    super.key,
    required this.playlist,
    required this.duration,
  });

  final Playlist playlist;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final details = playlist.songCount == 0
        ? context.l10n.songsCount(0)
        : '${context.l10n.songsCount(playlist.songCount)} · '
              '${formatDuration(duration)}';
    return CollectionHeader(
      artworkSongId: playlist.artworkSongId ?? 0,
      artwork: PlaylistCover(
        playlist: playlist,
        size: CollectionHeader.coverSize(context),
      ),
      title: playlist.name,
      subtitle: playlist.isFavorite
          ? '♥ ${context.l10n.playlist}'
          : context.l10n.playlist,
      details: details,
      placeholderIcon: Icons.queue_music_rounded,
    );
  }
}
