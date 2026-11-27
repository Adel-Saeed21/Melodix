import 'package:melodix/core/database/collections/video_collection.dart';
import 'package:melodix/features/video/data/models/local_video.dart';

/// A scanned video as a database row.
extension LocalVideoRow on LocalVideo {
  /// The row for this video, keeping the user's data from [previous].
  VideoCollection toRow({VideoCollection? previous}) => VideoCollection()
    ..videoId = id
    ..title = title
    ..durationMs = duration.inMilliseconds
    ..width = width
    ..height = height
    ..createdAt = createdAt
    ..isFavorite = previous?.isFavorite ?? false;

  /// Whether [row] (the saved copy of this video) has the same details, so
  /// it needn't be rewritten.
  bool sameScanAs(VideoCollection row) =>
      row.title == title &&
      row.durationMs == duration.inMilliseconds &&
      row.width == width &&
      row.height == height &&
      row.createdAt == createdAt;
}
