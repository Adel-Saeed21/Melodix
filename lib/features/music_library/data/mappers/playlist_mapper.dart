import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';

/// Maps saved playlists to domain [Playlist]s.
abstract final class PlaylistMapper {
  /// [hiddenSongIds] are left out of the count and the cover, matching the
  /// songs the playlist page shows (hidden songs keep their place in the
  /// playlist and come back when unhidden).
  static Playlist toEntity(
    PlaylistCollection p, {
    Set<int> hiddenSongIds = const {},
  }) {
    final visible = hiddenSongIds.isEmpty
        ? p.songIds
        : [
            for (final id in p.songIds)
              if (!hiddenSongIds.contains(id)) id,
          ];
    return Playlist(
      id: p.id,
      name: p.name,
      songCount: visible.length,
      isFavorite: p.isFavorite,
      // The first visible song's cover stands for the playlist.
      artworkSongId: visible.isEmpty ? null : visible.first,
    );
  }
}
