import 'package:melodix/core/entities/library_permission.dart';

/// Access to the device's music library.
abstract interface class LibraryPermissionRepository {
  /// Current access to the music library, without prompting the user.
  Future<LibraryPermission> checkPermission();

  /// Asks the user for access (shows the system dialog if possible).
  Future<LibraryPermission> requestPermission();

  /// Opens the app's system settings. Returns false if it can't.
  Future<bool> openSettings();
}
