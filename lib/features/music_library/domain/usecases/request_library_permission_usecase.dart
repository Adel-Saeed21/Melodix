import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class RequestLibraryPermissionUseCase {
  const RequestLibraryPermissionUseCase(this.repository);

  final MusicLibraryRepository repository;

  Future<LibraryPermission> call() => repository.requestPermission();
}
