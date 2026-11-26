import 'package:isar_community/isar.dart';

part 'recent_music_collection.g.dart';

/// One entry in the "recently played" music list.
///
/// There is at most one entry per song: playing a song again moves it to the
/// top by updating [playedAt]. The list is capped by
/// `RecentMusicLocalStorage.maxEntries`.
@collection
class RecentMusicCollection {
  /// The song's id, so replaying a song updates its existing entry.
  Id get id => songId;

  /// [SongCollection] id (MediaStore id).
  late int songId;

  @Index()
  late DateTime playedAt;

  RecentMusicCollection();

  factory RecentMusicCollection.played(int songId, {DateTime? at}) {
    return RecentMusicCollection()
      ..songId = songId
      ..playedAt = at ?? DateTime.now();
  }
}
