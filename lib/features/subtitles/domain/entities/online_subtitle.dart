import 'package:equatable/equatable.dart';

/// A subtitle file found online (OpenSubtitles), not downloaded yet.
class OnlineSubtitle extends Equatable {
  const OnlineSubtitle({
    required this.fileId,
    required this.title,
    required this.language,
    this.fileName,
    this.downloadCount = 0,
    this.hearingImpaired = false,
    this.matchesFile = false,
    this.format = 'srt',
    this.imdbId,
  });

  /// What a download asks for.
  final int fileId;

  /// The release's name (or the film's).
  final String title;
  final String language;
  final String? fileName;
  final int downloadCount;
  final bool hearingImpaired;

  /// Found by the video file's fingerprint: made for this exact file, so
  /// its timing fits.
  final bool matchesFile;

  /// The file's format as listed (e.g. "srt", "vtt", "sub"). Downloads
  /// always arrive as SRT: the service converts.
  final String format;

  /// The film's / episode's IMDb id, when listed.
  final int? imdbId;

  @override
  List<Object?> get props => [
    fileId,
    title,
    language,
    fileName,
    downloadCount,
    hearingImpaired,
    matchesFile,
    format,
    imdbId,
  ];
}
