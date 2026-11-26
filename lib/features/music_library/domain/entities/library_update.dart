import 'package:melodix/features/music_library/domain/entities/song.dart';

/// One change to the visible library (see `SongRepository.watchLibrary`).
sealed class LibraryUpdate {
  const LibraryUpdate();

  /// [current] with this update applied, or null if nothing changed (so
  /// callers can skip emitting). Unchanged songs keep their instances.
  List<Song>? applyTo(List<Song> current);
}

/// The whole visible library, sorted by title (first load, sync, unhide).
final class LibraryReloaded extends LibraryUpdate {
  const LibraryReloaded(this.songs);

  final List<Song> songs;

  @override
  List<Song>? applyTo(List<Song> current) =>
      identical(songs, current) ? null : songs;
}

/// These songs changed in place (favourite, play count). Songs not in the
/// list (e.g. hidden ones) are ignored: this never adds songs.
final class LibrarySongsUpdated extends LibraryUpdate {
  const LibrarySongsUpdated(this.songs);

  final List<Song> songs;

  @override
  List<Song>? applyTo(List<Song> current) {
    final byId = {for (final s in songs) s.id: s};
    List<Song>? next;
    for (var i = 0; i < current.length; i++) {
      final updated = byId[current[i].id];
      if (updated == null || updated == current[i]) continue;
      (next ??= List.of(current, growable: false))[i] = updated;
    }
    return next;
  }
}

/// These songs left the visible library (hidden or deleted).
final class LibrarySongsRemoved extends LibraryUpdate {
  const LibrarySongsRemoved(this.ids);

  final Set<int> ids;

  @override
  List<Song>? applyTo(List<Song> current) {
    if (!current.any((s) => ids.contains(s.id))) return null;
    return [
      for (final s in current)
        if (!ids.contains(s.id)) s,
    ].toList(growable: false);
  }
}
