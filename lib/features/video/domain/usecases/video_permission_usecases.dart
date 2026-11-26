import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/video/domain/repositories/video_library_repository.dart';

/// Whether the app may read the device's videos (never shows a dialog).
class CheckVideoPermissionUseCase {
  const CheckVideoPermissionUseCase(this.repository);

  final VideoLibraryRepository repository;

  Future<LibraryPermission> call() => repository.checkPermission();
}

/// Asks the user for access to their videos. Only from a button tap.
class RequestVideoPermissionUseCase {
  const RequestVideoPermissionUseCase(this.repository);

  final VideoLibraryRepository repository;

  Future<LibraryPermission> call() => repository.requestPermission();
}
