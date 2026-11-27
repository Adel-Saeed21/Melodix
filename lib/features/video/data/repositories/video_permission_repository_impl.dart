import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:melodix/features/video/data/datasources/video_service.dart';
import 'package:melodix/features/video/domain/repositories/video_permission_repository.dart';

class VideoPermissionRepositoryImpl implements VideoPermissionRepository {
  const VideoPermissionRepositoryImpl(this._service);

  final VideoService _service;

  @override
  Future<LibraryPermission> checkPermission() async =>
      _toPermission(await _service.permissionStatus());

  @override
  Future<LibraryPermission> requestPermission() async =>
      _toPermission(await _service.requestPermission());

  static LibraryPermission _toPermission(MediaPermissionStatus status) =>
      switch (status) {
        MediaPermissionStatus.granted => LibraryPermission.granted,
        MediaPermissionStatus.denied => LibraryPermission.denied,
        MediaPermissionStatus.permanentlyDenied =>
          LibraryPermission.permanentlyDenied,
      };
}
