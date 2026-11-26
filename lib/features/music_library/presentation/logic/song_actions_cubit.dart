import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/catalog_grouping.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/add_songs_to_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/create_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/delete_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_playlists_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/remove_song_from_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/set_songs_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/action_feedback.dart';

/// Runs the actions from a song's ⋮ menu and the multi-select bar. The
/// state is the latest feedback message (null until the first action).
class SongActionsCubit extends Cubit<ActionFeedback?>
    with ActionFeedbackReporter<ActionFeedback?> {
  SongActionsCubit({
    required this._toggleFavorite,
    required this._watchFavorite,
    required this._getPlaylists,
    required this._createPlaylist,
    required this._addToPlaylist,
    required this._removeFromPlaylist,
    required this._setSongsFavorite,
    required this._deleteSongs,
  }) : super(null);

  final ToggleSongFavoriteUseCase _toggleFavorite;
  final WatchSongFavoriteUseCase _watchFavorite;
  final GetPlaylistsUseCase _getPlaylists;
  final CreatePlaylistUseCase _createPlaylist;
  final AddSongsToPlaylistUseCase _addToPlaylist;
  final RemoveSongFromPlaylistUseCase _removeFromPlaylist;
  final SetSongsFavoriteUseCase _setSongsFavorite;
  final DeleteSongsUseCase _deleteSongs;

  @override
  ActionFeedback withFeedback(ActionFeedback feedback) => feedback;

  /// Whether song files can be deleted here (Android only).
  bool get canDeleteSongs => _deleteSongs.isSupported;

  /// Whether [song] is a favourite, live (a change made anywhere shows).
  Stream<bool> watchFavorite(Song song) => _watchFavorite(song.id);

  Future<void> toggleFavorite(Song song) async {
    reportResult(
      await _toggleFavorite(song.id),
      (isFavorite) => isFavorite
          ? AppStrings.addedToFavourites
          : AppStrings.removedFromFavourites,
    );
  }

  /// Playlists for the "Add to playlist" sheet (empty on error).
  Future<List<Playlist>> loadPlaylists() async =>
      (await _getPlaylists(const NoParams())).getOrElse(() => const []);

  Future<void> addToPlaylist(Song song, Playlist playlist) =>
      addManyToPlaylist([song], playlist);

  Future<void> createPlaylistWith(Song song, String name) =>
      createPlaylistWithMany([song], name);

  Future<void> removeFromPlaylist(Song song, Playlist playlist) async {
    reportResult(
      await _removeFromPlaylist(
        RemoveSongFromPlaylistParams(playlist.id, song.id),
      ),
      (_) => AppStrings.removedFromPlaylist(playlist.name),
    );
  }

  /// The song's album in [library] for "Go to album"; reports a message
  /// if it's no longer there.
  Album? albumFor(Song song, List<Song> library) {
    final album = CatalogGrouping.albumOf(library, song);
    if (album == null) report(AppStrings.albumNotFound, isError: true);
    return album;
  }

  /// The song's artist in [library] for "Go to artist"; reports a message
  /// if they're no longer there.
  Artist? artistFor(Song song, List<Song> library) {
    final artist = CatalogGrouping.artistNamed(library, song.artist);
    if (artist == null) report(AppStrings.artistNotFound, isError: true);
    return artist;
  }

  // Bulk actions (multi-select). Each returns true on success, so the
  // selection can be cleared.

  /// Favourites all [songs], or unfavourites them if they all already are.
  Future<bool> favoriteMany(List<Song> songs) async {
    final favorite = !songs.every((s) => s.isFavorite);
    return reportResult(
      await _setSongsFavorite(
        SetSongsFavoriteParams(_ids(songs), favorite: favorite),
      ),
      (_) => favorite
          ? AppStrings.addedSongsToFavourites(songs.length)
          : AppStrings.removedSongsFromFavourites(songs.length),
    );
  }

  Future<bool> addManyToPlaylist(List<Song> songs, Playlist playlist) async =>
      reportResult(
        await _addToPlaylist(
          AddSongsToPlaylistParams(playlist.id, _ids(songs)),
        ),
        (added) => added == 0
            ? AppStrings.alreadyInPlaylist(playlist.name)
            : songs.length == 1
            ? AppStrings.addedToPlaylist(playlist.name)
            : AppStrings.addedSongsToPlaylist(added, playlist.name),
      );

  Future<bool> createPlaylistWithMany(List<Song> songs, String name) async {
    final trimmed = name.trim();
    return reportResult(
      await _createPlaylist(
        CreatePlaylistParams(trimmed, songIds: _ids(songs)),
      ),
      (_) => songs.length == 1
          ? AppStrings.addedToPlaylist(trimmed)
          : AppStrings.addedSongsToPlaylist(songs.length, trimmed),
    );
  }

  /// Deletes the files from the device (the system asks to confirm).
  /// Returns true if any were deleted.
  Future<bool> deleteMany(List<Song> songs) async {
    var deletedAny = false;
    reportResult(await _deleteSongs(_ids(songs)), (deleted) {
      deletedAny = deleted > 0;
      return deletedAny
          ? AppStrings.deletedSongs(deleted)
          : AppStrings.nothingDeleted;
    });
    return deletedAny;
  }

  static List<int> _ids(List<Song> songs) => [for (final s in songs) s.id];
}
