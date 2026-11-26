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
///
/// Each title is lower-cased once up front, not inside the comparison:
/// sorting 10,000 songs compares ~140,000 times, and lower-casing there
/// made the sort several times slower (a visible stall on phones).
List<Song> sortSongs(List<Song> songs, SongSortOrder order) {
  final keyed = [
    for (final song in songs) (song: song, title: song.title.toLowerCase()),
  ];

  int byTitle(_Keyed a, _Keyed b) {
    final cmp = a.title.compareTo(b.title);
    return cmp != 0 ? cmp : a.song.id.compareTo(b.song.id);
  }

  switch (order) {
    case SongSortOrder.title:
      keyed.sort(byTitle);
    case SongSortOrder.recentlyAdded:
      keyed.sort((a, b) {
        // Unknown dates go last.
        final aDate = a.song.dateAdded, bDate = b.song.dateAdded;
        if (aDate != bDate) {
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          final cmp = bDate.compareTo(aDate);
          if (cmp != 0) return cmp;
        }
        return byTitle(a, b);
      });
    case SongSortOrder.mostPlayed:
      keyed.sort((a, b) {
        final cmp = b.song.playCount.compareTo(a.song.playCount);
        return cmp != 0 ? cmp : byTitle(a, b);
      });
  }
  return [for (final k in keyed) k.song];
}

typedef _Keyed = ({Song song, String title});
