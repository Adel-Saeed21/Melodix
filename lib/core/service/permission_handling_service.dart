import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

enum MediaPermissionStatus {
  granted,
  denied,
  permanentlyDenied;

  bool get isGranted => this == MediaPermissionStatus.granted;
}

abstract interface class PermissionHandlingService {
  Future<MediaPermissionStatus> audioStatus();
  Future<MediaPermissionStatus> requestAudio();
  Future<MediaPermissionStatus> videoStatus();
  Future<MediaPermissionStatus> requestVideo();

  Future<bool> openSettings();
}

class PermissionHandlingServiceImpl implements PermissionHandlingService {
  const PermissionHandlingServiceImpl();

  List<Permission> get _audioPermissions => Platform.isIOS
      ? [Permission.mediaLibrary]
      : [Permission.audio, Permission.storage];

  List<Permission> get _videoPermissions => Platform.isIOS
      ? [Permission.photos]
      : [Permission.videos, Permission.storage];

  @override
  Future<MediaPermissionStatus> audioStatus() => _status(_audioPermissions);

  @override
  Future<MediaPermissionStatus> requestAudio() => _request(_audioPermissions);

  @override
  Future<MediaPermissionStatus> videoStatus() => _status(_videoPermissions);

  @override
  Future<MediaPermissionStatus> requestVideo() => _request(_videoPermissions);

  @override
  Future<bool> openSettings() => openAppSettings();

  Future<MediaPermissionStatus> _status(List<Permission> permissions) async {
    final statuses = [for (final p in permissions) await p.status];
    return _combine(statuses);
  }

  Future<MediaPermissionStatus> _request(List<Permission> permissions) async {
    final statuses = <PermissionStatus>[];
    // Request one at a time: on any given Android version only one of them
    // actually shows a dialog, and we can stop as soon as one is granted.
    for (final permission in permissions) {
      final status = await permission.request();
      statuses.add(status);
      if (_isGranted(status)) break;
    }
    return _combine(statuses);
  }

  static bool _isGranted(PermissionStatus status) =>
      status.isGranted || status.isLimited;

  static MediaPermissionStatus _combine(List<PermissionStatus> statuses) {
    if (statuses.any(_isGranted)) return MediaPermissionStatus.granted;
    if (statuses.any((s) => s.isPermanentlyDenied || s.isRestricted)) {
      return MediaPermissionStatus.permanentlyDenied;
    }
    return MediaPermissionStatus.denied;
  }
}
