import 'dart:io';
import 'dart:typed_data';

import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/models/local_video.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:photo_manager/photo_manager.dart';

/// Reads the videos stored on the device.
abstract interface class VideoService {
  /// All videos on the device, newest first. Requests permission if needed.
  ///
  /// Throws [MediaPermissionException] if access is denied.
  Future<List<LocalVideo>> getAllVideos();

  /// The playable file for [videoId], or null if it no longer exists.
  Future<File?> getVideoFile(String videoId);

  /// A JPEG thumbnail for [videoId].
  Future<Uint8List?> getThumbnail(String videoId, {int size = 300});
}

class VideoServiceImpl implements VideoService {
  VideoServiceImpl({required this._permissionService});

  final PermissionHandlingService _permissionService;
  bool _configured = false;

  /// Permissions are handled by [PermissionHandlingService], so tell
  /// photo_manager not to run its own permission flow.
  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await PhotoManager.setIgnorePermissionCheck(true);
    _configured = true;
  }

  @override
  Future<List<LocalVideo>> getAllVideos() async {
    final permission = await _permissionService.requestVideo();
    if (!permission.isGranted) {
      throw MediaPermissionException(
        permanentlyDenied:
            permission == MediaPermissionStatus.permanentlyDenied,
      );
    }
    await _ensureConfigured();

    final filter = FilterOptionGroup(
      orders: const [OrderOption(type: OrderOptionType.createDate)],
    );
    final count = await PhotoManager.getAssetCount(
      type: RequestType.video,
      filterOption: filter,
    );
    if (count == 0) return const [];

    final assets = await PhotoManager.getAssetListRange(
      start: 0,
      end: count,
      type: RequestType.video,
      filterOption: filter,
    );

    return Future.wait(assets.map(_toLocalVideo));
  }

  @override
  Future<File?> getVideoFile(String videoId) async {
    await _ensureConfigured();
    final asset = await AssetEntity.fromId(videoId);
    return asset?.file;
  }

  @override
  Future<Uint8List?> getThumbnail(String videoId, {int size = 300}) async {
    await _ensureConfigured();
    final asset = await AssetEntity.fromId(videoId);
    return asset?.thumbnailDataWithSize(ThumbnailSize.square(size));
  }

  static Future<LocalVideo> _toLocalVideo(AssetEntity asset) async {
    final title = (asset.title?.isNotEmpty ?? false)
        ? asset.title!
        : await asset.titleAsync;

    return LocalVideo(
      id: asset.id,
      title: title,
      duration: asset.videoDuration,
      width: asset.width,
      height: asset.height,
      createdAt: asset.createDateTime,
    );
  }
}
