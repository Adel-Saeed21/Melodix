import 'package:melodix/core/entities/library_permission.dart';

/// Access to the device's videos.
abstract interface class VideoPermissionRepository {
  /// Current access, without asking.
  Future<LibraryPermission> checkPermission();

  /// Asks the user for access (call from a button, never in the background).
  Future<LibraryPermission> requestPermission();
}
