import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

/// The user's playlists.
abstract interface class PlaylistRepository {
  /// All playlists, most recently changed first.
  Future<Either<Failure, List<Playlist>>> getPlaylists();

  /// All playlists, most recently changed first, now and on every change.
  Stream<List<Playlist>> watchPlaylists();

  /// Creates a playlist (optionally starting with [songIds]); returns its id.
  Future<Either<Failure, int>> createPlaylist(
    String name, {
    List<int> songIds = const [],
  });

  /// Adds songs not already in the playlist; returns how many were added.
  Future<Either<Failure, int>> addSongsToPlaylist(
    int playlistId,
    List<int> songIds,
  );

  /// The playlist's songs in order (hidden / deleted songs skipped).
  Future<Either<Failure, List<Song>>> getPlaylistSongs(int playlistId);

  Future<Either<Failure, Unit>> renamePlaylist(int playlistId, String name);

  /// Deletes the playlist only; its songs stay in the library.
  Future<Either<Failure, Unit>> deletePlaylist(int playlistId);

  /// Flips the playlist's favorite flag; returns the new value.
  Future<Either<Failure, bool>> togglePlaylistFavorite(int playlistId);

  Future<Either<Failure, Unit>> removeSongFromPlaylist(
    int playlistId,
    int songId,
  );

  /// Saves the playlist's new song order ([orderedSongIds] = the songs as
  /// shown, in their new order). Hidden songs keep their positions.
  Future<Either<Failure, Unit>> reorderPlaylistSongs(
    int playlistId,
    List<int> orderedSongIds,
  );
}
