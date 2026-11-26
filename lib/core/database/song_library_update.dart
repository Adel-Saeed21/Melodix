import 'package:melodix/core/database/collections/song_collection.dart';

/// One change to the visible song library, as emitted by
/// `MusicLocalStorage.watchLibrary`. Updates arrive in the order their
/// writes committed.
sealed class SongLibraryUpdate {
  const SongLibraryUpdate();
}

/// The whole visible library (sorted by title). Sent first, then again only
/// after changes that add songs or change many at once (a sync, unhiding).
final class SongLibraryLoaded extends SongLibraryUpdate {
  const SongLibraryLoaded(this.songs);

  final List<SongCollection> songs;
}

/// These songs changed in place (favourite, play count): same position, no
/// songs added or removed. Rows for songs not in the visible library (e.g.
/// hidden ones) can be ignored.
final class SongLibrarySongsChanged extends SongLibraryUpdate {
  const SongLibrarySongsChanged(this.songs);

  final List<SongCollection> songs;
}

/// These songs left the visible library (hidden or deleted).
final class SongLibrarySongsRemoved extends SongLibraryUpdate {
  const SongLibrarySongsRemoved(this.ids);

  final Set<int> ids;
}
