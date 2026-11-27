/// The failure messages the data layer reports (in English). They also
/// identify the failure: the UI shows them translated (see
/// `AppLocalizationsFormats.failure`).
abstract final class ErrorMessages {
  static const String librarySync = 'Could not read your music library';
  static const String libraryRead = 'Could not load your music';
  static const String write = 'Could not save your change';
  static const String songsDelete = 'Could not delete the songs';
  static const String libraryPermission =
      'Allow access to your music to see your library';
  static const String videosSync = 'Could not read your videos';
  static const String videosDelete = 'Could not delete the videos';
  static const String videosPermission =
      'Allow access to your videos to see them';
}
