import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/fast_hash.dart';

part 'video_collection.g.dart';

/// A video on the device, as last scanned, and whether it's a favourite.
///
/// Watch progress lives in [VideoProgressCollection]: it changes every few
/// seconds while a video plays, and keeping it here would make everything
/// watching the library reload it each time.
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

  VideoCollection();

  @ignore
  Duration get duration => Duration(milliseconds: durationMs);
}
