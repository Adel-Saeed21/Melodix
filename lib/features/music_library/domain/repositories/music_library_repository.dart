import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/entities/library_search_results.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

abstract interface class MusicLibraryRepository {
  /// Current access to the music library, without prompting the user.
  Future<LibraryPermission> checkPermission();

  /// Asks the user for access (shows the system dialog if possible).
  Future<LibraryPermission> requestPermission();

  /// Opens the app's system settings. Returns false if it can't.
  Future<bool> openSettings();

  /// Scans the device and saves the result. Concurrent calls share one scan.
  ///
  /// Fails with [PermissionFailure] without access, [LibraryFailure] on
  /// other errors.
  Future<Either<Failure, LibrarySyncResult>> syncLibrary();

  /// When the library was last synced; null before the first scan.
  Future<DateTime?> lastSyncedAt();

  /// All saved songs sorted by title, now and on every change.
  Stream<List<Song>> watchSongs();

  Future<Either<Failure, List<Album>>> getAlbums();

  Future<Either<Failure, List<Artist>>> getArtists();

  Future<Either<Failure, List<Song>>> getAlbumSongs(Album album);

  Future<Either<Failure, List<Song>>> getArtistSongs(String artistName);

  /// Embedded artwork for [songId] at roughly [size] px, or null if none.
  /// Results are cached in memory.
  Future<Uint8List?> getArtwork(int songId, {int size = 200});

  // Song actions

  /// Flips the song's favorite flag; returns the new value.
  Future<Either<Failure, bool>> toggleFavorite(int songId);

  /// Hides a song from the library or shows it again. The file is untouched.
  Future<Either<Failure, Unit>> setSongHidden(
    int songId, {
    required bool hidden,
  });

  /// Songs the user hid, sorted by title, now and on every change.
  Stream<List<Song>> watchHiddenSongs();

  /// The album [song] belongs to, or null if it can't be found.
  Future<Either<Failure, Album?>> getAlbumForSong(Song song);

  /// The artist called [name], or null if no visible songs remain.
  Future<Either<Failure, Artist?>> getArtist(String name);

  // Playlists

  /// All playlists, most recently changed first.
  Future<Either<Failure, List<Playlist>>> getPlaylists();

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

  /// All playlists, most recently changed first, now and on every change.
  Stream<List<Playlist>> watchPlaylists();

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

  /// Songs, artists, albums and playlists matching [query] (hidden songs
  /// excluded). An empty query returns empty results.
  Future<Either<Failure, LibrarySearchResults>> searchLibrary(String query);

  /// Counts one play of the song (for "Most played") and moves it to the
  /// top of the recently played list. Call when playback of a song starts.
  Future<Either<Failure, Unit>> recordPlay(int songId);

  // Bulk actions (multi-select)

  Future<Either<Failure, Unit>> setSongsHidden(
    List<int> songIds, {
    required bool hidden,
  });

  Future<Either<Failure, Unit>> setSongsFavorite(
    List<int> songIds, {
    required bool favorite,
  });

  /// Whether song files can be deleted on this platform (Android only).
  bool get canDeleteSongs;

  /// Deletes the song files from the device (the system asks the user to
  /// confirm) and removes them from the library. Returns how many were
  /// deleted; 0 if the user declined.
  Future<Either<Failure, int>> deleteSongs(List<int> songIds);
}
