import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';

/// Everything the user marked as favorite.
class Favorites {
  const Favorites({required this.songs, required this.playlists});

  final List<SongCollection> songs;
  final List<PlaylistCollection> playlists;

  bool get isEmpty => songs.isEmpty && playlists.isEmpty;
}

abstract interface class FavoritesLocalStorage {
  Future<Favorites> getFavorites();
  Stream<List<SongCollection>> watchFavoriteSongs();
  Stream<List<PlaylistCollection>> watchFavoritePlaylists();
}

class FavoritesLocalStorageImpl implements FavoritesLocalStorage {
  FavoritesLocalStorageImpl(this._isar);

  final Isar _isar;

  QueryBuilder<SongCollection, SongCollection, QAfterSortBy>
  get _favoriteSongs => _isar.songCollections
      .filter()
      .isFavoriteEqualTo(true)
      .not()
      .isHiddenEqualTo(true)
      .sortByTitle();

  QueryBuilder<PlaylistCollection, PlaylistCollection, QAfterSortBy>
  get _favoritePlaylists => _isar.playlistCollections
      .filter()
      .isFavoriteEqualTo(true)
      .sortByUpdatedAtDesc();

  @override
  Future<Favorites> getFavorites() async {
    final results = await Future.wait([
      _favoriteSongs.findAll(),
      _favoritePlaylists.findAll(),
    ]);
    return Favorites(
      songs: results[0] as List<SongCollection>,
      playlists: results[1] as List<PlaylistCollection>,
    );
  }

  @override
  Stream<List<SongCollection>> watchFavoriteSongs() =>
      _favoriteSongs.watch(fireImmediately: true);

  @override
  Stream<List<PlaylistCollection>> watchFavoritePlaylists() =>
      _favoritePlaylists.watch(fireImmediately: true);
}
