import 'package:equatable/equatable.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';

/// A subtitle downloaded (or found already kept) for a video.
class SubtitleDownload extends Equatable {
  const SubtitleDownload({
    required this.track,
    this.fromCache = false,
    this.remaining,
    this.resetsIn,
  });

  /// Kept on the device: works offline from now on.
  final SubtitleTrack track;

  /// It was already kept: nothing was downloaded (no allowance spent).
  final bool fromCache;

  /// Downloads left today, when the service said.
  final int? remaining;

  /// When the allowance resets (e.g. "5 hours").
  final String? resetsIn;

  @override
  List<Object?> get props => [track, fromCache, remaining, resetsIn];
}
