import 'package:dio/dio.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_models.dart';
import 'package:retrofit/retrofit.dart';

part 'opensubtitles_api.g.dart';

/// OpenSubtitles REST API v1 (https://api.opensubtitles.com/api/v1), the
/// endpoints the app uses:
/// * `GET /subtitles`: search (by name, file fingerprint or IMDb id);
/// * `POST /download`: a short-lived link for one file (anonymous with the
///   app's key; counts against the daily allowance).
///
/// Headers (key, app name, JSON) are added by the [Dio] it's given.
@RestApi()
abstract class OpenSubtitlesApi {
  factory OpenSubtitlesApi(Dio dio, {String? baseUrl}) = _OpenSubtitlesApi;

  @GET('subtitles')
  Future<SubtitleSearchResponse> search({
    @Query('query') String? query,
    @Query('moviehash') String? movieHash,
    @Query('imdb_id') int? imdbId,
    @Query('languages') String? languages,
  });

  @POST('download')
  Future<SubtitleDownloadResponse> requestDownload(
    @Body() SubtitleDownloadRequest request,
  );
}
