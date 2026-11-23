import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/fast_hash.dart';
import 'package:melodix/core/models/local_video.dart';

part 'video_collection.g.dart';

@collection
class VideoCollection {
  /// [fastHash] of [videoId], so re-scans update the same row.
  Id get id => fastHash(videoId);

  /// photo_manager asset id.
  @Index(unique: true, replace: true)
  late String videoId;

  // Scanned from the device
  @Index(caseSensitive: false)
  late String title;

  late int durationMs;
  late int width;
  late int height;

  @Index()
  late DateTime createdAt;

  // User data
  @Index()
  bool isFavorite = false;

  int playCount = 0;

  @Index()
  DateTime? lastPlayedAt;

  /// Where playback stopped, for "continue watching". 0 = from the start.
  int lastPositionMs = 0;

  VideoCollection();

  /// Builds a row from a scanned video, keeping user data from [previous].
  factory VideoCollection.fromLocalVideo(
    LocalVideo video, {
    VideoCollection? previous,
  }) {
    return VideoCollection()
      ..videoId = video.id
      ..title = video.title
      ..durationMs = video.duration.inMilliseconds
      ..width = video.width
      ..height = video.height
      ..createdAt = video.createdAt
      ..isFavorite = previous?.isFavorite ?? false
      ..playCount = previous?.playCount ?? 0
      ..lastPlayedAt = previous?.lastPlayedAt
      ..lastPositionMs = previous?.lastPositionMs ?? 0;
  }

  @ignore
  Duration get duration => Duration(milliseconds: durationMs);

  @ignore
  Duration get lastPosition => Duration(milliseconds: lastPositionMs);

  LocalVideo toLocalVideo() => LocalVideo(
    id: videoId,
    title: title,
    duration: duration,
    width: width,
    height: height,
    createdAt: createdAt,
  );
}
