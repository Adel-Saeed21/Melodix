// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opensubtitles_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubtitleSearchResponse _$SubtitleSearchResponseFromJson(
  Map<String, dynamic> json,
) => _SubtitleSearchResponse(
  totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
  totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
  page: (json['page'] as num?)?.toInt() ?? 1,
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => SubtitleSearchItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SubtitleSearchItem>[],
);

Map<String, dynamic> _$SubtitleSearchResponseToJson(
  _SubtitleSearchResponse instance,
) => <String, dynamic>{
  'total_count': instance.totalCount,
  'total_pages': instance.totalPages,
  'page': instance.page,
  'data': instance.data,
};

_SubtitleSearchItem _$SubtitleSearchItemFromJson(Map<String, dynamic> json) =>
    _SubtitleSearchItem(
      id: json['id'] as String,
      attributes: SubtitleAttributes.fromJson(
        json['attributes'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SubtitleSearchItemToJson(_SubtitleSearchItem instance) =>
    <String, dynamic>{'id': instance.id, 'attributes': instance.attributes};

_SubtitleAttributes _$SubtitleAttributesFromJson(Map<String, dynamic> json) =>
    _SubtitleAttributes(
      language: json['language'] as String?,
      release: json['release'] as String?,
      downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
      hearingImpaired: json['hearing_impaired'] as bool? ?? false,
      movieHashMatch: json['moviehash_match'] as bool? ?? false,
      featureDetails: json['feature_details'] == null
          ? null
          : SubtitleFeatureDetails.fromJson(
              json['feature_details'] as Map<String, dynamic>,
            ),
      files:
          (json['files'] as List<dynamic>?)
              ?.map(
                (e) => SubtitleFileModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <SubtitleFileModel>[],
    );

Map<String, dynamic> _$SubtitleAttributesToJson(_SubtitleAttributes instance) =>
    <String, dynamic>{
      'language': instance.language,
      'release': instance.release,
      'download_count': instance.downloadCount,
      'hearing_impaired': instance.hearingImpaired,
      'moviehash_match': instance.movieHashMatch,
      'feature_details': instance.featureDetails,
      'files': instance.files,
    };

_SubtitleFeatureDetails _$SubtitleFeatureDetailsFromJson(
  Map<String, dynamic> json,
) => _SubtitleFeatureDetails(
  title: json['title'] as String?,
  movieName: json['movie_name'] as String?,
  year: (json['year'] as num?)?.toInt(),
  imdbId: (json['imdb_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$SubtitleFeatureDetailsToJson(
  _SubtitleFeatureDetails instance,
) => <String, dynamic>{
  'title': instance.title,
  'movie_name': instance.movieName,
  'year': instance.year,
  'imdb_id': instance.imdbId,
};

_SubtitleFileModel _$SubtitleFileModelFromJson(Map<String, dynamic> json) =>
    _SubtitleFileModel(
      fileId: (json['file_id'] as num).toInt(),
      fileName: json['file_name'] as String?,
      cdNumber: (json['cd_number'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SubtitleFileModelToJson(_SubtitleFileModel instance) =>
    <String, dynamic>{
      'file_id': instance.fileId,
      'file_name': instance.fileName,
      'cd_number': instance.cdNumber,
    };

_SubtitleDownloadRequest _$SubtitleDownloadRequestFromJson(
  Map<String, dynamic> json,
) => _SubtitleDownloadRequest(
  fileId: (json['file_id'] as num).toInt(),
  subFormat: json['sub_format'] as String?,
);

Map<String, dynamic> _$SubtitleDownloadRequestToJson(
  _SubtitleDownloadRequest instance,
) => <String, dynamic>{
  'file_id': instance.fileId,
  'sub_format': ?instance.subFormat,
};

_SubtitleDownloadResponse _$SubtitleDownloadResponseFromJson(
  Map<String, dynamic> json,
) => _SubtitleDownloadResponse(
  link: json['link'] as String,
  fileName: json['file_name'] as String?,
  requests: (json['requests'] as num?)?.toInt(),
  remaining: (json['remaining'] as num?)?.toInt(),
  resetTime: json['reset_time'] as String?,
  resetTimeUtc: json['reset_time_utc'] as String?,
);

Map<String, dynamic> _$SubtitleDownloadResponseToJson(
  _SubtitleDownloadResponse instance,
) => <String, dynamic>{
  'link': instance.link,
  'file_name': instance.fileName,
  'requests': instance.requests,
  'remaining': instance.remaining,
  'reset_time': instance.resetTime,
  'reset_time_utc': instance.resetTimeUtc,
};
