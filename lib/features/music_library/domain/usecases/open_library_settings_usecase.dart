import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

/// Opens the system settings page where the user can grant access after
/// denying it permanently. Returns false if the page couldn't be opened.
class OpenLibrarySettingsUseCase {
  const OpenLibrarySettingsUseCase(this.repository);

  final MusicLibraryRepository repository;

  Future<bool> call() => repository.openSettings();
}
