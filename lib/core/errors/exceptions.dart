class MediaPermissionException implements Exception {
  const MediaPermissionException({required this.permanentlyDenied});

  final bool permanentlyDenied;

  @override
  String toString() =>
      'MediaPermissionException(permanentlyDenied: $permanentlyDenied)';
}
