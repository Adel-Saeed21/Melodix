import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// The user hasn't granted access to their media library.
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {required this.permanentlyDenied});

  /// True when access can only be granted from the system settings.
  final bool permanentlyDenied;

  @override
  List<Object?> get props => [message, permanentlyDenied];
}

/// Reading or saving the local media library failed.
class LibraryFailure extends Failure {
  const LibraryFailure(super.message);
}
