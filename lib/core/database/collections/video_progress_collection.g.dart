// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_progress_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetVideoProgressCollectionCollection on Isar {
  IsarCollection<VideoProgressCollection> get videoProgressCollections =>
      this.collection();
}

const VideoProgressCollectionSchema = CollectionSchema(
  name: r'VideoProgressCollection',
  id: -942307477667101529,
  properties: {
    r'lastPlayedAt': PropertySchema(
      id: 0,
      name: r'lastPlayedAt',
      type: IsarType.dateTime,
    ),
    r'playCount': PropertySchema(
      id: 1,
      name: r'playCount',
      type: IsarType.long,
    ),
    r'positionMs': PropertySchema(
      id: 2,
      name: r'positionMs',
      type: IsarType.long,
    ),
    r'videoId': PropertySchema(id: 3, name: r'videoId', type: IsarType.string),
  },

  estimateSize: _videoProgressCollectionEstimateSize,
  serialize: _videoProgressCollectionSerialize,
  deserialize: _videoProgressCollectionDeserialize,
  deserializeProp: _videoProgressCollectionDeserializeProp,
  idName: r'id',
  indexes: {
    r'videoId': IndexSchema(
      id: 6273887982249211799,
      name: r'videoId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'videoId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'lastPlayedAt': IndexSchema(
      id: 1709968845012040220,
      name: r'lastPlayedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastPlayedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _videoProgressCollectionGetId,
  getLinks: _videoProgressCollectionGetLinks,
  attach: _videoProgressCollectionAttach,
  version: '3.4.1',
);

int _videoProgressCollectionEstimateSize(
  VideoProgressCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.videoId.length * 3;
  return bytesCount;
}

void _videoProgressCollectionSerialize(
  VideoProgressCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.lastPlayedAt);
  writer.writeLong(offsets[1], object.playCount);
  writer.writeLong(offsets[2], object.positionMs);
  writer.writeString(offsets[3], object.videoId);
}

VideoProgressCollection _videoProgressCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = VideoProgressCollection();
  object.lastPlayedAt = reader.readDateTimeOrNull(offsets[0]);
  object.playCount = reader.readLong(offsets[1]);
  object.positionMs = reader.readLong(offsets[2]);
  object.videoId = reader.readString(offsets[3]);
  return object;
}

P _videoProgressCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _videoProgressCollectionGetId(VideoProgressCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _videoProgressCollectionGetLinks(
  VideoProgressCollection object,
) {
  return [];
}

void _videoProgressCollectionAttach(
  IsarCollection<dynamic> col,
  Id id,
  VideoProgressCollection object,
) {}

extension VideoProgressCollectionByIndex
    on IsarCollection<VideoProgressCollection> {
  Future<VideoProgressCollection?> getByVideoId(String videoId) {
    return getByIndex(r'videoId', [videoId]);
  }

  VideoProgressCollection? getByVideoIdSync(String videoId) {
    return getByIndexSync(r'videoId', [videoId]);
  }

  Future<bool> deleteByVideoId(String videoId) {
    return deleteByIndex(r'videoId', [videoId]);
  }

  bool deleteByVideoIdSync(String videoId) {
    return deleteByIndexSync(r'videoId', [videoId]);
  }

  Future<List<VideoProgressCollection?>> getAllByVideoId(
    List<String> videoIdValues,
  ) {
    final values = videoIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'videoId', values);
  }

  List<VideoProgressCollection?> getAllByVideoIdSync(
    List<String> videoIdValues,
  ) {
    final values = videoIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'videoId', values);
  }

  Future<int> deleteAllByVideoId(List<String> videoIdValues) {
    final values = videoIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'videoId', values);
  }

  int deleteAllByVideoIdSync(List<String> videoIdValues) {
    final values = videoIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'videoId', values);
  }

  Future<Id> putByVideoId(VideoProgressCollection object) {
    return putByIndex(r'videoId', object);
  }

  Id putByVideoIdSync(VideoProgressCollection object, {bool saveLinks = true}) {
    return putByIndexSync(r'videoId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByVideoId(List<VideoProgressCollection> objects) {
    return putAllByIndex(r'videoId', objects);
  }

  List<Id> putAllByVideoIdSync(
    List<VideoProgressCollection> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'videoId', objects, saveLinks: saveLinks);
  }
}

extension VideoProgressCollectionQueryWhereSort
    on QueryBuilder<VideoProgressCollection, VideoProgressCollection, QWhere> {
  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterWhere>
  anyLastPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastPlayedAt'),
      );
    });
  }
}

extension VideoProgressCollectionQueryWhere
    on
        QueryBuilder<
          VideoProgressCollection,
          VideoProgressCollection,
          QWhereClause
        > {
  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  videoIdEqualTo(String videoId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'videoId', value: [videoId]),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  videoIdNotEqualTo(String videoId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'videoId',
                lower: [],
                upper: [videoId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'videoId',
                lower: [videoId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'videoId',
                lower: [videoId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'videoId',
                lower: [],
                upper: [videoId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  lastPlayedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'lastPlayedAt', value: [null]),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  lastPlayedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastPlayedAt',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  lastPlayedAtEqualTo(DateTime? lastPlayedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'lastPlayedAt',
          value: [lastPlayedAt],
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  lastPlayedAtNotEqualTo(DateTime? lastPlayedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastPlayedAt',
                lower: [],
                upper: [lastPlayedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastPlayedAt',
                lower: [lastPlayedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastPlayedAt',
                lower: [lastPlayedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastPlayedAt',
                lower: [],
                upper: [lastPlayedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  lastPlayedAtGreaterThan(DateTime? lastPlayedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastPlayedAt',
          lower: [lastPlayedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  lastPlayedAtLessThan(DateTime? lastPlayedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastPlayedAt',
          lower: [],
          upper: [lastPlayedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterWhereClause
  >
  lastPlayedAtBetween(
    DateTime? lowerLastPlayedAt,
    DateTime? upperLastPlayedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastPlayedAt',
          lower: [lowerLastPlayedAt],
          includeLower: includeLower,
          upper: [upperLastPlayedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension VideoProgressCollectionQueryFilter
    on
        QueryBuilder<
          VideoProgressCollection,
          VideoProgressCollection,
          QFilterCondition
        > {
  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  lastPlayedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastPlayedAt'),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  lastPlayedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastPlayedAt'),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  lastPlayedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastPlayedAt', value: value),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  lastPlayedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastPlayedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  lastPlayedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastPlayedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  lastPlayedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastPlayedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  playCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'playCount', value: value),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  playCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'playCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  playCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'playCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  playCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'playCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  positionMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'positionMs', value: value),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  positionMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'positionMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  positionMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'positionMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  positionMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'positionMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  videoIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'videoId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  videoIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'videoId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  videoIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'videoId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  videoIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'videoId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  videoIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'videoId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  videoIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'videoId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  videoIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'videoId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  videoIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'videoId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  videoIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'videoId', value: ''),
      );
    });
  }

  QueryBuilder<
    VideoProgressCollection,
    VideoProgressCollection,
    QAfterFilterCondition
  >
  videoIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'videoId', value: ''),
      );
    });
  }
}

extension VideoProgressCollectionQueryObject
    on
        QueryBuilder<
          VideoProgressCollection,
          VideoProgressCollection,
          QFilterCondition
        > {}

extension VideoProgressCollectionQueryLinks
    on
        QueryBuilder<
          VideoProgressCollection,
          VideoProgressCollection,
          QFilterCondition
        > {}

extension VideoProgressCollectionQuerySortBy
    on QueryBuilder<VideoProgressCollection, VideoProgressCollection, QSortBy> {
  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  sortByLastPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPlayedAt', Sort.asc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  sortByLastPlayedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPlayedAt', Sort.desc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  sortByPlayCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playCount', Sort.asc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  sortByPlayCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playCount', Sort.desc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  sortByPositionMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionMs', Sort.asc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  sortByPositionMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionMs', Sort.desc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  sortByVideoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoId', Sort.asc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  sortByVideoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoId', Sort.desc);
    });
  }
}

extension VideoProgressCollectionQuerySortThenBy
    on
        QueryBuilder<
          VideoProgressCollection,
          VideoProgressCollection,
          QSortThenBy
        > {
  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  thenByLastPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPlayedAt', Sort.asc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  thenByLastPlayedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPlayedAt', Sort.desc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  thenByPlayCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playCount', Sort.asc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  thenByPlayCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playCount', Sort.desc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  thenByPositionMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionMs', Sort.asc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  thenByPositionMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionMs', Sort.desc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  thenByVideoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoId', Sort.asc);
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QAfterSortBy>
  thenByVideoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoId', Sort.desc);
    });
  }
}

extension VideoProgressCollectionQueryWhereDistinct
    on
        QueryBuilder<
          VideoProgressCollection,
          VideoProgressCollection,
          QDistinct
        > {
  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QDistinct>
  distinctByLastPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastPlayedAt');
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QDistinct>
  distinctByPlayCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'playCount');
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QDistinct>
  distinctByPositionMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'positionMs');
    });
  }

  QueryBuilder<VideoProgressCollection, VideoProgressCollection, QDistinct>
  distinctByVideoId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'videoId', caseSensitive: caseSensitive);
    });
  }
}

extension VideoProgressCollectionQueryProperty
    on
        QueryBuilder<
          VideoProgressCollection,
          VideoProgressCollection,
          QQueryProperty
        > {
  QueryBuilder<VideoProgressCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<VideoProgressCollection, DateTime?, QQueryOperations>
  lastPlayedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastPlayedAt');
    });
  }

  QueryBuilder<VideoProgressCollection, int, QQueryOperations>
  playCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'playCount');
    });
  }

  QueryBuilder<VideoProgressCollection, int, QQueryOperations>
  positionMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'positionMs');
    });
  }

  QueryBuilder<VideoProgressCollection, String, QQueryOperations>
  videoIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'videoId');
    });
  }
}
