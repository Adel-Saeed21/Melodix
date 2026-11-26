/// Where a running library sync is, in order. Reported as the sync really
/// gets there (see `LibrarySyncRepository.watchSyncStage`), so a progress
/// display never runs ahead of the work.
enum LibrarySyncStage {
  /// Checking access and asking the device what changed since last time.
  checking,

  /// Reading the songs from the device (only the changed ones when it can).
  reading,

  /// Saving the result to the library.
  saving,
}
