import 'package:dartz/dartz.dart';
import 'package:melodix/features/subtitles/domain/entities/online_subtitle.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_cue.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_download.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_failure.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';

/// A video's subtitles: found on the device, imported, or downloaded once
/// and kept, so all of them work offline.
abstract interface class SubtitleRepository {
  /// The video's tracks: the ones saved in the app, then any found next to
  /// the video file.
  Future<Either<SubtitleFailure, List<SubtitleTrack>>> tracksFor(
    String videoId,
  );

  /// [track]'s captions, read from its file.
  Future<Either<SubtitleFailure, SubtitleTimeline>> load(SubtitleTrack track);

  /// The track the user last chose for the video; null: subtitles off.
  Future<String?> selectedTrackId(String videoId);

  /// Remembers the choice (null: off).
  Future<void> setSelectedTrackId(String videoId, String? trackId);

  /// Whether the device can pick a file to import.
  bool get canImport;

  /// Lets the user pick an SRT / VTT file and keeps a copy for the video.
  /// Right(null): the user cancelled.
  Future<Either<SubtitleFailure, SubtitleTrack?>> importFromDevice(
    String videoId,
  );

  /// Whether online search is set up (an API key in this build).
  bool get canSearchOnline;

  /// Subtitles found online for the video: by [imdbId] when given, else
  /// by its file's fingerprint (when it can be read) and [query].
  /// [language]: ISO 639-1, or null for any.
  Future<Either<SubtitleFailure, List<OnlineSubtitle>>> searchOnline(
    String videoId, {
    String? query,
    int? imdbId,
    String? language,
  });

  /// Downloads [subtitle] for the video and keeps it. A copy already saved
  /// is returned as is (no second download).
  Future<Either<SubtitleFailure, SubtitleDownload>> download(
    String videoId,
    OnlineSubtitle subtitle,
  );
}
