import 'dart:typed_data';

import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/features/video/data/models/local_video.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:photo_manager/photo_manager.dart';

/// Reads the videos stored on the device.
///
/// Learned from the music library:
/// * a scan never shows a permission dialog (it may run in the
///   background); it fails with [MediaPermissionException] instead, and the
///   app asks only when the user taps "Allow access";
/// * a failed read throws ([MediaQueryException]); it's never turned into
///   an empty list, which would look like "all videos were deleted";
/// * one query per page of videos, titles included (never one call per
///   video);
/// * playback uses the media library's URI (a `content://` URI on
///   Android), never a copy of the file.
abstract interface class VideoService {
  /// Whether the app may read videos, without asking.
  Future<MediaPermissionStatus> permissionStatus();

  /// Asks the user for access (the system dialog, if it can still show).
  Future<MediaPermissionStatus> requestPermission();

  /// A small fingerprint of the device's videos: how many there are, and
  /// the most recently added or changed one (its id and when). Two calls
  /// give the same answer only if nothing was added, deleted or changed in
  /// between, so a sync can skip [scan] when it matches. Two tiny queries,
  /// whatever the library's size.
  ///
  /// Throws like [scan] (no access, or the device can't be read).
  Future<String> checkpoint();

  /// Every video on the device, newest first.
  ///
  /// Throws [MediaPermissionException] without access (no dialog) and
  /// [MediaQueryException] if the device can't be read completely.
  Future<VideoScan> scan();

  /// A JPEG thumbnail for [videoId], [size] pixels square; null if none.
  Future<Uint8List?> thumbnail(String videoId, {int size = 300});

  /// Deletes the videos from the device. On Android 11+ the system asks the
  /// user to confirm. Returns the ids actually deleted (none if the user
  /// said no).
  Future<List<String>> delete(List<String> videoIds);

  /// What the video player should open for [videoId]: a `content://` URI
  /// on Android (works under scoped storage), a file URL on iOS. Null if
  /// the video is gone.
  Future<Uri?> playbackUri(String videoId);
}

/// The result of a full scan, with the device's own count, so an empty
/// list can be told apart from a failed read.
class VideoScan {
  const VideoScan(
    this.videos, {
    required this.deviceCount,
    this.partial = false,
  });

  final List<LocalVideo> videos;

  /// How many videos the device says it has.
  final int deviceCount;

  /// The user let the app see only some videos (Android 14+ "Select photos
  /// and videos"): the rest still exist, so they mustn't be taken out of
  /// the library (with their favourites and progress).
  final bool partial;
}

class VideoServiceImpl implements VideoService {
  VideoServiceImpl({required this._permissionService, this.pageSize = 500});

  final PermissionHandlingService _permissionService;

  /// Videos read per query: a whole library in one message could be huge.
  final int pageSize;

  bool _configured = false;

  /// photo_manager's asset type for videos.
  static const int _videoType = 2;

  /// Permissions are handled by [PermissionHandlingService], so tell
  /// photo_manager not to run its own permission flow.
  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await PhotoManager.setIgnorePermissionCheck(true);
    _configured = true;
  }

  @override
  Future<MediaPermissionStatus> permissionStatus() =>
      _permissionService.videoStatus();

  @override
  Future<MediaPermissionStatus> requestPermission() =>
      _permissionService.requestVideo();

  Future<void> _requireAccess() async {
    final permission = await _permissionService.videoStatus();
    if (!permission.isGranted) {
      throw MediaPermissionException(
        permanentlyDenied:
            permission == MediaPermissionStatus.permanentlyDenied,
      );
    }
    await _ensureConfigured();
  }

  @override
  Future<String> checkpoint() async {
    await _requireAccess();
    try {
      final count = await PhotoManager.getAssetCount(type: RequestType.video);
      if (count == 0) return '0';
      // The most recently changed video: a new one, an edit or a rename
      // moves it; a deletion changes the count.
      final latest = await PhotoManager.getAssetListRange(
        start: 0,
        end: 1,
        type: RequestType.video,
        filterOption: FilterOptionGroup(
          orders: const [
            OrderOption(type: OrderOptionType.updateDate, asc: false),
          ],
        ),
      );
      if (latest.isEmpty) {
        throw const MediaQueryException('Videos counted but none read');
      }
      final asset = latest.first;
      return '$count:${asset.id}:'
          '${asset.modifiedDateTime.millisecondsSinceEpoch}';
    } on MediaQueryException {
      rethrow;
    } catch (e) {
      throw MediaQueryException('Video check failed: $e');
    }
  }

  @override
  Future<VideoScan> scan() async {
    await _requireAccess();

    try {
      final filter = FilterOptionGroup(
        orders: const [OrderOption(type: OrderOptionType.createDate)],
        // Titles come with the query (on iOS they're otherwise fetched one
        // video at a time).
        videoOption: const FilterOption(needTitle: true),
      );
      final count = await PhotoManager.getAssetCount(
        type: RequestType.video,
        filterOption: filter,
      );
      final videos = <LocalVideo>[];
      for (var start = 0; start < count; start += pageSize) {
        final page = await PhotoManager.getAssetListRange(
          start: start,
          end: start + pageSize < count ? start + pageSize : count,
          type: RequestType.video,
          filterOption: filter,
        );
        videos.addAll(page.map(_toLocalVideo));
      }
      if (videos.length < count) {
        throw MediaQueryException(
          'Read ${videos.length} of $count videos; library kept',
        );
      }
      return VideoScan(
        videos,
        deviceCount: count,
        partial: await _permissionService.isVideoAccessPartial(),
      );
    } on MediaQueryException {
      rethrow;
    } catch (e) {
      throw MediaQueryException('Video scan failed: $e');
    }
  }

  @override
  Future<Uint8List?> thumbnail(String videoId, {int size = 300}) async {
    await _ensureConfigured();
    // Built from the id: no extra lookup per thumbnail.
    return AssetEntity(
      id: videoId,
      typeInt: _videoType,
      width: size,
      height: size,
    ).thumbnailDataWithSize(ThumbnailSize.square(size));
  }

  @override
  Future<List<String>> delete(List<String> videoIds) async {
    if (videoIds.isEmpty) return const [];
    await _ensureConfigured();
    return PhotoManager.editor.deleteWithIds(videoIds);
  }

  @override
  Future<Uri?> playbackUri(String videoId) async {
    await _ensureConfigured();
    final asset = await AssetEntity.fromId(videoId);
    final url = await asset?.getMediaUrl();
    return url == null ? null : Uri.parse(url);
  }

  static LocalVideo _toLocalVideo(AssetEntity asset) => LocalVideo(
    id: asset.id,
    title: (asset.title?.isNotEmpty ?? false) ? asset.title! : 'Video',
    duration: asset.videoDuration,
    // As shown (a phone video recorded upright is stored sideways).
    width: asset.orientatedWidth,
    height: asset.orientatedHeight,
    createdAt: asset.createDateTime,
  );
}
