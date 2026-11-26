class MediaPermissionException implements Exception {
  const MediaPermissionException({required this.permanentlyDenied});

  final bool permanentlyDenied;

  @override
  String toString() =>
      'MediaPermissionException(permanentlyDenied: $permanentlyDenied)';
}

/// The media library could not be read completely: a query failed, returned
/// no cursor, a volume was unavailable or the answer was inconsistent.
///
/// Never means "the library is empty": callers must not delete anything or
/// advance a sync checkpoint when they get it.
class MediaQueryException implements Exception {
  const MediaQueryException(this.message);

  final String message;

  @override
  String toString() => 'MediaQueryException($message)';
}
