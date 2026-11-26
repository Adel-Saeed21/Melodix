import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';

/// Maps saved playlists to domain [Playlist]s.
abstract final class PlaylistMapper {
  static Playlist toEntity(PlaylistCollection p) => Playlist(
    id: p.id,
    name: p.name,
    songCount: p.songIds.length,
    isFavorite: p.isFavorite,
    // The first song's cover stands for the playlist.
    artworkSongId: p.songIds.isEmpty ? null : p.songIds.first,
  );
}
