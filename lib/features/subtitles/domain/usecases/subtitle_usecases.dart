import 'package:dartz/dartz.dart';
import 'package:melodix/features/subtitles/domain/entities/online_subtitle.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_cue.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_download.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_failure.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';
import 'package:melodix/features/subtitles/domain/repositories/subtitle_repository.dart';

class GetSubtitleTracksUseCase {
  const GetSubtitleTracksUseCase(this._repository);
  final SubtitleRepository _repository;

  Future<Either<SubtitleFailure, List<SubtitleTrack>>> call(String videoId) =>
      _repository.tracksFor(videoId);
}

class LoadSubtitleUseCase {
  const LoadSubtitleUseCase(this._repository);
  final SubtitleRepository _repository;

  Future<Either<SubtitleFailure, SubtitleTimeline>> call(SubtitleTrack track) =>
      _repository.load(track);
}

/// The remembered choice per video (null: off).
class SubtitleSelectionUseCase {
  const SubtitleSelectionUseCase(this._repository);
  final SubtitleRepository _repository;

  Future<String?> get(String videoId) => _repository.selectedTrackId(videoId);

  Future<void> set(String videoId, String? trackId) =>
      _repository.setSelectedTrackId(videoId, trackId);
}

class ImportSubtitleUseCase {
  const ImportSubtitleUseCase(this._repository);
  final SubtitleRepository _repository;

  bool get isAvailable => _repository.canImport;

  Future<Either<SubtitleFailure, SubtitleTrack?>> call(String videoId) =>
      _repository.importFromDevice(videoId);
}

class SearchOnlineSubtitlesUseCase {
  const SearchOnlineSubtitlesUseCase(this._repository);
  final SubtitleRepository _repository;

  bool get isAvailable => _repository.canSearchOnline;

  /// [query]: a name ("The Matrix", a file name) or an IMDb id
  /// ("tt0133093", or an IMDb link).
  Future<Either<SubtitleFailure, List<OnlineSubtitle>>> call(
    String videoId, {
    required String query,
    String? language,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value(const Right([]));
    final imdbId = parseImdbId(trimmed);
    return imdbId != null
        ? _repository.searchOnline(videoId, imdbId: imdbId, language: language)
        : _repository.searchOnline(videoId, query: trimmed, language: language);
  }
}

class DownloadSubtitleUseCase {
  const DownloadSubtitleUseCase(this._repository);
  final SubtitleRepository _repository;

  Future<Either<SubtitleFailure, SubtitleDownload>> call(
    String videoId,
    OnlineSubtitle subtitle,
  ) => _repository.download(videoId, subtitle);
}

/// A search for a video's title: the file name without its extension and
/// with dots / underscores as spaces ("The.Movie.2020.mkv" → "The Movie
/// 2020").
String subtitleQueryFor(String title) {
  final dot = title.lastIndexOf('.');
  final base = dot > 0 && title.length - dot <= 5
      ? title.substring(0, dot)
      : title;
  return base.replaceAll(RegExp(r'[._\s]+'), ' ').trim();
}

/// The IMDb id in [text] ("tt0133093", "https://www.imdb.com/title/
/// tt0133093/"), as the number the service wants (no "tt", no leading
/// zeros); null if it isn't one.
int? parseImdbId(String text) {
  final match = RegExp(
    r'^(?:https?://(?:www\.|m\.)?imdb\.com/title/)?tt(\d{5,10})/?$',
    caseSensitive: false,
  ).firstMatch(text.trim());
  return match == null ? null : int.parse(match.group(1)!);
}
