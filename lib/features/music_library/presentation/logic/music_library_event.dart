import 'package:equatable/equatable.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

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

/// User asked to rescan (e.g. pull-to-refresh).
class MusicLibraryRefreshRequested extends MusicLibraryEvent {
  const MusicLibraryRefreshRequested();
}

/// The app came back to the foreground: re-check access (the user may have
/// changed it in settings) and pick up new music.
class MusicLibraryAppResumed extends MusicLibraryEvent {
  const MusicLibraryAppResumed();
}

/// Internal: the saved library changed.
class MusicLibrarySongsChanged extends MusicLibraryEvent {
  const MusicLibrarySongsChanged(this.songs);

  final List<Song> songs;

  @override
  List<Object?> get props => [songs];
}
