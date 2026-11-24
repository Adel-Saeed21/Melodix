enum LibraryPermission {
  granted,
  denied,

  /// Can only be granted from the system settings.
  permanentlyDenied;

  bool get isGranted => this == LibraryPermission.granted;
}
