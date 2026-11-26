import 'package:melodix/features/music_library/domain/repositories/library_permission_repository.dart';

/// Opens the system settings page where the user can grant access after
/// denying it permanently. Returns false if the page couldn't be opened.
class OpenLibrarySettingsUseCase {
  const OpenLibrarySettingsUseCase(this.repository);

  final LibraryPermissionRepository repository;

  Future<bool> call() => repository.openSettings();
}
