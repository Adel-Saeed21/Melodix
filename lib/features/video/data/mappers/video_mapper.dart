import 'package:melodix/core/database/collections/video_collection.dart';
import 'package:melodix/features/video/domain/entities/video.dart';

/// Maps saved videos to domain [Video]s.
abstract final class VideoMapper {
  static Video toEntity(VideoCollection row) => Video(
    id: row.videoId,
    title: row.title,
    duration: row.duration,
    width: row.width,
    height: row.height,
    createdAt: row.createdAt,
    isFavorite: row.isFavorite,
    playCount: row.playCount,
    lastPosition: row.lastPosition,
    lastPlayedAt: row.lastPlayedAt,
  );

  static List<Video> toEntities(List<VideoCollection> rows) =>
      rows.map(toEntity).toList(growable: false);
}
