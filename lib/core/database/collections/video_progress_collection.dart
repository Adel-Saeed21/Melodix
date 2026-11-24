import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/fast_hash.dart';

part 'video_progress_collection.g.dart';

/// How much of a video was watched: one small row per video ever played.
/// Kept apart from [VideoCollection] so saving progress while a video plays
/// never wakes up the watchers of the whole library.
@collection
class VideoProgressCollection {
  Id get id => fastHash(videoId);

  @Index(unique: true, replace: true)
  late String videoId;

  /// Where playback stopped; 0 = from the start (or watched to the end).
  int positionMs = 0;

  @Index()
  DateTime? lastPlayedAt;

  int playCount = 0;

  @ignore
  Duration get position => Duration(milliseconds: positionMs);
}
