import 'package:equatable/equatable.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';
import 'package:melodix/features/music_library/domain/entities/library_update.dart';

sealed class MusicLibraryEvent extends Equatable {
  const MusicLibraryEvent();

  @override
  List<Object?> get props => [];
}

/// App startup: load saved songs, then sync if access is already granted.
/// Never shows a permission dialog.
class MusicLibraryStarted extends MusicLibraryEvent {
  const MusicLibraryStarted();
}

/// User asked to grant access (e.g. tapped "Allow access").
class MusicLibraryPermissionRequested extends MusicLibraryEvent {
  const MusicLibraryPermissionRequested();
}

/// User asked to open the system settings to grant access after denying it
/// permanently.
class MusicLibraryOpenSettingsRequested extends MusicLibraryEvent {
  const MusicLibraryOpenSettingsRequested();
}

/// User asked to scan (the Scan button, "Try again").
///
/// A normal scan asks the device what changed since the last one and reads
/// only that (or nothing, if nothing changed). [full] re-reads every song
/// instead: slower, and only needed to recover a library, so no button
/// sends it by accident.
class MusicLibraryRefreshRequested extends MusicLibraryEvent {
  const MusicLibraryRefreshRequested({this.full = false});

  final bool full;

  @override
  List<Object?> get props => [full];
}

/// The app came back to the foreground: re-check access (the user may have
/// changed it in settings) and pick up new music.
class MusicLibraryAppResumed extends MusicLibraryEvent {
  const MusicLibraryAppResumed();
}

/// Internal: a running sync reached [stage].
class MusicLibrarySyncStageReached extends MusicLibraryEvent {
  const MusicLibrarySyncStageReached(this.stage);

  final LibrarySyncStage stage;

  @override
  List<Object?> get props => [stage];
}

/// Internal: the saved library changed (the whole list, or only the songs
/// a single edit touched).
class MusicLibrarySongsChanged extends MusicLibraryEvent {
  const MusicLibrarySongsChanged(this.update);

  final LibraryUpdate update;

  @override
  List<Object?> get props => [update];
}
