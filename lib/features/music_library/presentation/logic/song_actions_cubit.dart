import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/add_songs_to_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/create_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/delete_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_artist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_playlists_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_album_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/remove_song_from_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/set_song_hidden_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/set_songs_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/set_songs_hidden_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';

/// A message to show after a song action, e.g. in a SnackBar.
class SongActionFeedback extends Equatable {
  const SongActionFeedback(
    this.message,
    this.sequence, {
    this.undoHideIds = const [],
  });

  final String message;

  /// Set after hiding songs: offer "Undo" that unhides these song ids.
  final List<int> undoHideIds;

  /// Makes repeated identical messages distinct so each one is shown.
  final int sequence;

  @override
  List<Object?> get props => [message, undoHideIds, sequence];
}

/// Runs the actions from a song's ⋮ menu. The state is the latest feedback
/// message (null until the first action).
class SongActionsCubit extends Cubit<SongActionFeedback?> {
  SongActionsCubit({
    required this._toggleFavorite,
    required this._setHidden,
    required this._getPlaylists,
    required this._createPlaylist,
    required this._addToPlaylist,
    required this._getAlbum,
    required this._getArtist,
    required this._removeFromPlaylist,
    required this._setSongsHidden,
    required this._setSongsFavorite,
    required this._deleteSongs,
  }) : super(null);

  final ToggleSongFavoriteUseCase _toggleFavorite;
  final SetSongHiddenUseCase _setHidden;
  final GetPlaylistsUseCase _getPlaylists;
  final CreatePlaylistUseCase _createPlaylist;
  final AddSongsToPlaylistUseCase _addToPlaylist;
  final GetSongAlbumUseCase _getAlbum;
  final GetArtistUseCase _getArtist;
  final RemoveSongFromPlaylistUseCase _removeFromPlaylist;
  final SetSongsHiddenUseCase _setSongsHidden;
  final SetSongsFavoriteUseCase _setSongsFavorite;
  final DeleteSongsUseCase _deleteSongs;

  /// Whether song files can be deleted here (Android only).
  bool get canDeleteSongs => _deleteSongs.isSupported;

  int _sequence = 0;

  Future<void> toggleFavorite(Song song) async {
    final result = await _toggleFavorite(song.id);
    _report(
      result.fold(
        (f) => f.message,
        (isFavorite) => isFavorite
            ? AppStrings.addedToFavourites
            : AppStrings.removedFromFavourites,
      ),
    );
  }

  Future<void> hide(Song song) async {
    final result = await _setHidden(SetSongHiddenParams(song.id, hidden: true));
    result.fold(
      (f) => _report(f.message),
      (_) => _report(AppStrings.hiddenFromLibrary, undoHideIds: [song.id]),
    );
  }

  /// Brings a hidden song back. [silent] skips the message (used by Undo).
  Future<void> unhide(int songId, {bool silent = false}) async {
    final result = await _setHidden(SetSongHiddenParams(songId, hidden: false));
    result.fold((f) => _report(f.message), (_) {
      if (!silent) _report(AppStrings.restoredToLibrary);
    });
  }

  /// Playlists for the "Add to playlist" sheet (empty on error).
  Future<List<Playlist>> loadPlaylists() async =>
      (await _getPlaylists(const NoParams())).getOrElse(() => const []);

  Future<void> addToPlaylist(Song song, Playlist playlist) =>
      addManyToPlaylist([song], playlist);

  Future<void> createPlaylistWith(Song song, String name) =>
      createPlaylistWithMany([song], name);

  Future<void> removeFromPlaylist(Song song, Playlist playlist) async {
    final result = await _removeFromPlaylist(
      RemoveSongFromPlaylistParams(playlist.id, song.id),
    );
    _report(
      result.fold(
        (f) => f.message,
        (_) => AppStrings.removedFromPlaylist(playlist.name),
      ),
    );
  }

  /// The song's album for "Go to album"; reports a message if it's missing.
  Future<Album?> albumFor(Song song) async {
    final album = (await _getAlbum(song)).fold((f) => null, (a) => a);
    if (album == null) _report(AppStrings.songNotFound);
    return album;
  }

  /// The song's artist for "Go to artist"; reports a message if missing.
  Future<Artist?> artistFor(Song song) async {
    final artist = (await _getArtist(song.artist)).fold((f) => null, (a) => a);
    if (artist == null) _report(AppStrings.songNotFound);
    return artist;
  }

  // Bulk actions (multi-select). Each returns true on success, so the
  // selection can be cleared.

  /// Favourites all [songs], or unfavourites them if they all already are.
  Future<bool> favoriteMany(List<Song> songs) async {
    final favorite = !songs.every((s) => s.isFavorite);
    final result = await _setSongsFavorite(
      SetSongsFavoriteParams(_ids(songs), favorite: favorite),
    );
    return result.fold(
      (f) {
        _report(f.message);
        return false;
      },
      (_) {
        _report(
          favorite
              ? AppStrings.addedSongsToFavourites(songs.length)
              : AppStrings.removedSongsFromFavourites(songs.length),
        );
        return true;
      },
    );
  }

  Future<bool> hideMany(List<Song> songs) async {
    final ids = _ids(songs);
    final result = await _setSongsHidden(
      SetSongsHiddenParams(ids, hidden: true),
    );
    return result.fold(
      (f) {
        _report(f.message);
        return false;
      },
      (_) {
        _report(AppStrings.hiddenSongsCount(ids.length), undoHideIds: ids);
        return true;
      },
    );
  }

  /// Brings hidden songs back. [silent] skips the message (used by Undo).
  Future<void> unhideMany(List<int> songIds, {bool silent = false}) async {
    final result = await _setSongsHidden(
      SetSongsHiddenParams(songIds, hidden: false),
    );
    result.fold((f) => _report(f.message), (_) {
      if (!silent) _report(AppStrings.restoredToLibrary);
    });
  }

  Future<bool> addManyToPlaylist(List<Song> songs, Playlist playlist) async {
    final result = await _addToPlaylist(
      AddSongsToPlaylistParams(playlist.id, _ids(songs)),
    );
    return result.fold(
      (f) {
        _report(f.message);
        return false;
      },
      (added) {
        _report(
          added == 0
              ? AppStrings.alreadyInPlaylist(playlist.name)
              : songs.length == 1
              ? AppStrings.addedToPlaylist(playlist.name)
              : AppStrings.addedSongsToPlaylist(added, playlist.name),
        );
        return true;
      },
    );
  }

  Future<bool> createPlaylistWithMany(List<Song> songs, String name) async {
    final trimmed = name.trim();
    final result = await _createPlaylist(
      CreatePlaylistParams(trimmed, songIds: _ids(songs)),
    );
    return result.fold(
      (f) {
        _report(f.message);
        return false;
      },
      (_) {
        _report(
          songs.length == 1
              ? AppStrings.addedToPlaylist(trimmed)
              : AppStrings.addedSongsToPlaylist(songs.length, trimmed),
        );
        return true;
      },
    );
  }

  /// Deletes the files from the device (the system asks to confirm).
  /// Returns true if any were deleted.
  Future<bool> deleteMany(List<Song> songs) async {
    final result = await _deleteSongs(_ids(songs));
    return result.fold(
      (f) {
        _report(f.message);
        return false;
      },
      (deleted) {
        _report(
          deleted == 0
              ? AppStrings.nothingDeleted
              : AppStrings.deletedSongs(deleted),
        );
        return deleted > 0;
      },
    );
  }

  static List<int> _ids(List<Song> songs) => [for (final s in songs) s.id];

  void _report(String message, {List<int> undoHideIds = const []}) {
    if (isClosed) return;
    emit(SongActionFeedback(message, ++_sequence, undoHideIds: undoHideIds));
  }
}
