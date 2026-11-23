import 'package:melodix/features/music_library/domain/entities/song.dart';

/// How the Songs list is ordered.
enum SongSortOrder {
  /// Newest files on the device first.
  recentlyAdded,

  /// Alphabetical by title (case-insensitive).
  title,

  /// Highest play count first.
  mostPlayed,
}

/// Returns a new list of [songs] in [order]. Ties fall back to title, then
/// id, so the result is always stable.
List<Song> sortSongs(List<Song> songs, SongSortOrder order) {
  int byTitle(Song a, Song b) {
    final cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return cmp != 0 ? cmp : a.id.compareTo(b.id);
  }

  final sorted = [...songs];
  switch (order) {
    case SongSortOrder.title:
      sorted.sort(byTitle);
    case SongSortOrder.recentlyAdded:
      sorted.sort((a, b) {
        // Unknown dates go last.
        final aDate = a.dateAdded, bDate = b.dateAdded;
        if (aDate != bDate) {
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          final cmp = bDate.compareTo(aDate);
          if (cmp != 0) return cmp;
        }
        return byTitle(a, b);
      });
    case SongSortOrder.mostPlayed:
      sorted.sort((a, b) {
        final cmp = b.playCount.compareTo(a.playCount);
        return cmp != 0 ? cmp : byTitle(a, b);
      });
  }
  return sorted;
}
