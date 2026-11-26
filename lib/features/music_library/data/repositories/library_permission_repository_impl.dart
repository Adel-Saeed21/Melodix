import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/repositories/library_permission_repository.dart';

class LibraryPermissionRepositoryImpl implements LibraryPermissionRepository {
  const LibraryPermissionRepositoryImpl(this._permissionService);

  final PermissionHandlingService _permissionService;

  @override
  Future<LibraryPermission> checkPermission() async =>
      _toLibraryPermission(await _permissionService.audioStatus());

  @override
  Future<LibraryPermission> requestPermission() async =>
      _toLibraryPermission(await _permissionService.requestAudio());

  @override
  Future<bool> openSettings() => _permissionService.openSettings();

  static LibraryPermission _toLibraryPermission(MediaPermissionStatus s) =>
      switch (s) {
        MediaPermissionStatus.granted => LibraryPermission.granted,
        MediaPermissionStatus.denied => LibraryPermission.denied,
        MediaPermissionStatus.permanentlyDenied =>
          LibraryPermission.permanentlyDenied,
      };
}
