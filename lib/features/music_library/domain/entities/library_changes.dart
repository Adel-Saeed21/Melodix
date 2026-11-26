import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/entities/song_sort_order.dart';

/// True when songs were added, removed or reordered, or a field used for
/// albums, artists or search changed (title, artist, album, album id,
/// duration).
///
/// Favourite and play-count changes return false: they don't affect
/// grouping or search, so they shouldn't trigger a regroup or reindex.
/// One pass, no allocations.
bool catalogChanged(List<Song> previous, List<Song> next) {
  if (identical(previous, next)) return false;
  if (previous.length != next.length) return true;
  for (var i = 0; i < next.length; i++) {
    final a = previous[i];
    final b = next[i];
    if (a.id != b.id ||
        a.title != b.title ||
        a.artist != b.artist ||
        a.album != b.album ||
        a.albumId != b.albumId ||
        a.duration != b.duration) {
      return true;
    }
  }
  return false;
}

/// True when anything [order] sorts by changed (or the songs themselves), so
/// the sorted list must be rebuilt. E.g. a play count only matters for
/// [SongSortOrder.mostPlayed]; a favourite never does.
bool sortKeysChanged(
  List<Song> previous,
  List<Song> next,
  SongSortOrder order,
) {
  if (identical(previous, next)) return false;
  if (previous.length != next.length) return true;
  for (var i = 0; i < next.length; i++) {
    final a = previous[i];
    final b = next[i];
    if (a.id != b.id || a.title != b.title) return true;
    switch (order) {
      case SongSortOrder.title:
        break;
      case SongSortOrder.recentlyAdded:
        if (a.dateAdded != b.dateAdded) return true;
      case SongSortOrder.mostPlayed:
        if (a.playCount != b.playCount) return true;
    }
  }
  return false;
}
