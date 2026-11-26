import 'package:freezed_annotation/freezed_annotation.dart';

part 'opensubtitles_models.freezed.dart';
part 'opensubtitles_models.g.dart';

/// `GET /subtitles`: one page of results.
@freezed
abstract class SubtitleSearchResponse with _$SubtitleSearchResponse {
  const factory SubtitleSearchResponse({
    @JsonKey(name: 'total_count') @Default(0) int totalCount,
    @JsonKey(name: 'total_pages') @Default(0) int totalPages,
    @Default(1) int page,
    @Default(<SubtitleSearchItem>[]) List<SubtitleSearchItem> data,
  }) = _SubtitleSearchResponse;

  factory SubtitleSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SubtitleSearchResponseFromJson(json);
}

@freezed
abstract class SubtitleSearchItem with _$SubtitleSearchItem {
  const factory SubtitleSearchItem({
    required String id,
    required SubtitleAttributes attributes,
  }) = _SubtitleSearchItem;

  factory SubtitleSearchItem.fromJson(Map<String, dynamic> json) =>
      _$SubtitleSearchItemFromJson(json);
}

@freezed
abstract class SubtitleAttributes with _$SubtitleAttributes {
  const factory SubtitleAttributes({
    String? language,
    String? release,
    @JsonKey(name: 'download_count') @Default(0) int downloadCount,
    @JsonKey(name: 'hearing_impaired') @Default(false) bool hearingImpaired,
    @JsonKey(name: 'moviehash_match') @Default(false) bool movieHashMatch,
    @JsonKey(name: 'feature_details') SubtitleFeatureDetails? featureDetails,
    @Default(<SubtitleFileModel>[]) List<SubtitleFileModel> files,
  }) = _SubtitleAttributes;

  factory SubtitleAttributes.fromJson(Map<String, dynamic> json) =>
      _$SubtitleAttributesFromJson(json);
}

@freezed
abstract class SubtitleFeatureDetails with _$SubtitleFeatureDetails {
  const factory SubtitleFeatureDetails({
    String? title,
    @JsonKey(name: 'movie_name') String? movieName,
    int? year,
    @JsonKey(name: 'imdb_id') int? imdbId,
  }) = _SubtitleFeatureDetails;

  factory SubtitleFeatureDetails.fromJson(Map<String, dynamic> json) =>
      _$SubtitleFeatureDetailsFromJson(json);
}

@freezed
abstract class SubtitleFileModel with _$SubtitleFileModel {
  const factory SubtitleFileModel({
    @JsonKey(name: 'file_id') required int fileId,
    @JsonKey(name: 'file_name') String? fileName,
    @JsonKey(name: 'cd_number') int? cdNumber,
  }) = _SubtitleFileModel;

  factory SubtitleFileModel.fromJson(Map<String, dynamic> json) =>
      _$SubtitleFileModelFromJson(json);
}

/// `POST /download`'s body.
@freezed
abstract class SubtitleDownloadRequest with _$SubtitleDownloadRequest {
  const factory SubtitleDownloadRequest({
    @JsonKey(name: 'file_id') required int fileId,

    /// The format to receive (the service converts): always one the app
    /// reads.
    @JsonKey(name: 'sub_format', includeIfNull: false) String? subFormat,
  }) = _SubtitleDownloadRequest;

  factory SubtitleDownloadRequest.fromJson(Map<String, dynamic> json) =>
      _$SubtitleDownloadRequestFromJson(json);
}

/// `POST /download`: a short-lived link to the file, and the allowance
/// left.
@freezed
abstract class SubtitleDownloadResponse with _$SubtitleDownloadResponse {
  const factory SubtitleDownloadResponse({
    required String link,
    @JsonKey(name: 'file_name') String? fileName,
    int? requests,
    int? remaining,
    @JsonKey(name: 'reset_time') String? resetTime,
    @JsonKey(name: 'reset_time_utc') String? resetTimeUtc,
  }) = _SubtitleDownloadResponse;

  factory SubtitleDownloadResponse.fromJson(Map<String, dynamic> json) =>
      _$SubtitleDownloadResponseFromJson(json);
}
