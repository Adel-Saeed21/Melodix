import 'package:melodix/core/database/collections/video_collection.dart';
import 'package:melodix/core/database/collections/video_progress_collection.dart';
import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/features/video/domain/entities/video.dart';

/// Maps saved videos (and their progress) to domain entities.
abstract final class VideoMapper {
  static Video toEntity(VideoCollection row) => Video(
    id: row.videoId,
    title: row.title,
    duration: row.duration,
    width: row.width,
    height: row.height,
    createdAt: row.createdAt,
    isFavorite: row.isFavorite,
  );

  static VideoProgress toProgress(VideoProgressCollection row) => VideoProgress(
    videoId: row.videoId,
    position: row.position,
    lastPlayedAt: row.lastPlayedAt,
    playCount: row.playCount,
  );

  static Map<String, VideoProgress> toProgressMap(
    List<VideoProgressCollection> rows,
  ) => {for (final row in rows) row.videoId: toProgress(row)};

  static List<Video> toEntities(List<VideoCollection> rows) =>
      rows.map(toEntity).toList(growable: false);
}
