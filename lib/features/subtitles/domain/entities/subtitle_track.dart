import 'package:equatable/equatable.dart';

/// Where a subtitle file came from.
enum SubtitleSource {
  /// Next to the video on the device, with a matching name.
  nearby,

  /// Picked by the user from the device; copied into the app.
  imported,

  /// Downloaded from OpenSubtitles; saved in the app.
  downloaded,
}

/// A subtitle file the app can show for a video, available offline.
class SubtitleTrack extends Equatable {
  const SubtitleTrack({
    required this.id,
    required this.videoId,
    required this.label,
    required this.source,
    required this.path,
    this.language,
    this.remoteFileId,
  });

  /// Unique among the video's tracks.
  final String id;
  final String videoId;

  /// What the list shows (the file's name, or the release's).
  final String label;
  final SubtitleSource source;

  /// The file on the device.
  final String path;

  /// ISO 639-1 code when known (e.g. "en").
  final String? language;

  /// The OpenSubtitles file id, for downloaded tracks (so the same file is
  /// never downloaded twice).
  final int? remoteFileId;

  @override
  List<Object?> get props => [
    id,
    videoId,
    label,
    source,
    path,
    language,
    remoteFileId,
  ];
}
