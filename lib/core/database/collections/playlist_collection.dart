import 'package:isar_community/isar.dart';

part 'playlist_collection.g.dart';

/// A user-made playlist.
///
/// Songs are stored as an ordered list of [SongCollection] ids (MediaStore
/// ids), so the user's ordering is kept. Ids of songs that were deleted from
/// the device are skipped when the playlist is read.
@collection
class PlaylistCollection {
  Id id = Isar.autoIncrement;

  @Index(caseSensitive: false)
  late String name;

  /// Song ids in play order. Duplicates are not allowed.
  List<int> songIds = [];

  @Index()
  bool isFavorite = false;

  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  PlaylistCollection();

  factory PlaylistCollection.create(String name) {
    final now = DateTime.now();
    return PlaylistCollection()
      ..name = name.trim()
      ..createdAt = now
      ..updatedAt = now;
  }

  @ignore
  int get songCount => songIds.length;

  /// Appends [ids] that aren't already in the playlist. Returns how many
  /// were added.
  int addSongs(Iterable<int> ids) {
    final existing = songIds.toSet();
    final toAdd = [
      for (final id in ids)
        if (existing.add(id)) id,
    ];
    if (toAdd.isEmpty) return 0;
    songIds = [...songIds, ...toAdd];
    _touch();
    return toAdd.length;
  }

  /// Removes [songId]. Returns false if it wasn't in the playlist.
  bool removeSong(int songId) {
    if (!songIds.contains(songId)) return false;
    songIds = [...songIds]..remove(songId);
    _touch();
    return true;
  }

  /// Moves the song at [from] to [to] (indexes in the current list), e.g.
  /// from a ReorderableListView after adjusting for its index shift.
  void moveSong(int from, int to) {
    if (from == to ||
        from < 0 ||
        from >= songIds.length ||
        to < 0 ||
        to >= songIds.length) {
      return;
    }
    final updated = [...songIds];
    final id = updated.removeAt(from);
    updated.insert(to, id);
    songIds = updated;
    _touch();
  }

  /// Applies a new order for the songs the user can see.
  ///
  /// [orderedIds] is the visible songs in their new order. Songs not in it
  /// (e.g. hidden songs) keep their exact positions; the visible songs fill
  /// the remaining positions in the new order. Ids that aren't in the
  /// playlist are ignored. Returns false if nothing changed.
  bool reorderVisible(List<int> orderedIds) {
    final current = songIds.toSet();
    final newOrder = [
      for (final id in orderedIds)
        if (current.contains(id)) id,
    ];
    final moving = newOrder.toSet();
    if (moving.length != newOrder.length) return false; // duplicates

    var next = 0;
    final updated = [
      for (final id in songIds)
        if (moving.contains(id)) newOrder[next++] else id,
    ];
    if (_sameOrder(updated, songIds)) return false;
    songIds = updated;
    _touch();
    return true;
  }

  static bool _sameOrder(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void rename(String newName) {
    name = newName.trim();
    _touch();
  }

  void _touch() => updatedAt = DateTime.now();
}
