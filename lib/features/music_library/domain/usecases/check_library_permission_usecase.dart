import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/repositories/library_permission_repository.dart';

class CheckLibraryPermissionUseCase {
  const CheckLibraryPermissionUseCase(this.repository);

  final LibraryPermissionRepository repository;

  Future<LibraryPermission> call() => repository.checkPermission();
}
