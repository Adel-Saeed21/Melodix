// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_state_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetPlaybackStateCollectionCollection on Isar {
  IsarCollection<PlaybackStateCollection> get playbackStateCollections =>
      this.collection();
}

const PlaybackStateCollectionSchema = CollectionSchema(
  name: r'PlaybackStateCollection',
  id: -7398961185416919004,
  properties: {
    r'currentIndex': PropertySchema(
      id: 0,
      name: r'currentIndex',
      type: IsarType.long,
    ),
    r'originalQueueSongIds': PropertySchema(
      id: 1,
      name: r'originalQueueSongIds',
      type: IsarType.longList,
    ),
    r'positionMs': PropertySchema(
      id: 2,
      name: r'positionMs',
      type: IsarType.long,
    ),
    r'queueSongIds': PropertySchema(
      id: 3,
      name: r'queueSongIds',
      type: IsarType.longList,
    ),
    r'repeatMode': PropertySchema(
      id: 4,
      name: r'repeatMode',
      type: IsarType.byte,
      enumMap: _PlaybackStateCollectionrepeatModeEnumValueMap,
    ),
    r'shuffle': PropertySchema(id: 5, name: r'shuffle', type: IsarType.bool),
    r'source': PropertySchema(
      id: 6,
      name: r'source',
      type: IsarType.byte,
      enumMap: _PlaybackStateCollectionsourceEnumValueMap,
    ),
    r'sourceId': PropertySchema(id: 7, name: r'sourceId', type: IsarType.long),
    r'speed': PropertySchema(id: 8, name: r'speed', type: IsarType.double),
    r'updatedAt': PropertySchema(
      id: 9,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _playbackStateCollectionEstimateSize,
  serialize: _playbackStateCollectionSerialize,
  deserialize: _playbackStateCollectionDeserialize,
  deserializeProp: _playbackStateCollectionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _playbackStateCollectionGetId,
  getLinks: _playbackStateCollectionGetLinks,
  attach: _playbackStateCollectionAttach,
  version: '3.4.1',
);

int _playbackStateCollectionEstimateSize(
  PlaybackStateCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.originalQueueSongIds.length * 8;
  bytesCount += 3 + object.queueSongIds.length * 8;
  return bytesCount;
}

void _playbackStateCollectionSerialize(
  PlaybackStateCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.currentIndex);
  writer.writeLongList(offsets[1], object.originalQueueSongIds);
  writer.writeLong(offsets[2], object.positionMs);
  writer.writeLongList(offsets[3], object.queueSongIds);
  writer.writeByte(offsets[4], object.repeatMode.index);
  writer.writeBool(offsets[5], object.shuffle);
  writer.writeByte(offsets[6], object.source.index);
  writer.writeLong(offsets[7], object.sourceId);
  writer.writeDouble(offsets[8], object.speed);
  writer.writeDateTime(offsets[9], object.updatedAt);
}

PlaybackStateCollection _playbackStateCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PlaybackStateCollection();
  object.currentIndex = reader.readLong(offsets[0]);
  object.id = id;
  object.originalQueueSongIds = reader.readLongList(offsets[1]) ?? [];
  object.positionMs = reader.readLong(offsets[2]);
  object.queueSongIds = reader.readLongList(offsets[3]) ?? [];
  object.repeatMode =
      _PlaybackStateCollectionrepeatModeValueEnumMap[reader.readByteOrNull(
        offsets[4],
      )] ??
      PlayerRepeatMode.off;
  object.shuffle = reader.readBool(offsets[5]);
  object.source =
      _PlaybackStateCollectionsourceValueEnumMap[reader.readByteOrNull(
        offsets[6],
      )] ??
      PlaybackSource.allSongs;
  object.sourceId = reader.readLongOrNull(offsets[7]);
  object.speed = reader.readDouble(offsets[8]);
  object.updatedAt = reader.readDateTime(offsets[9]);
  return object;
}

P _playbackStateCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLongList(offset) ?? []) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLongList(offset) ?? []) as P;
    case 4:
      return (_PlaybackStateCollectionrepeatModeValueEnumMap[reader
                  .readByteOrNull(offset)] ??
              PlayerRepeatMode.off)
          as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (_PlaybackStateCollectionsourceValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              PlaybackSource.allSongs)
          as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PlaybackStateCollectionrepeatModeEnumValueMap = {
  'off': 0,
  'all': 1,
  'one': 2,
};
const _PlaybackStateCollectionrepeatModeValueEnumMap = {
  0: PlayerRepeatMode.off,
  1: PlayerRepeatMode.all,
  2: PlayerRepeatMode.one,
};
const _PlaybackStateCollectionsourceEnumValueMap = {
  'allSongs': 0,
  'playlist': 1,
  'favorites': 2,
  'recent': 3,
  'search': 4,
};
const _PlaybackStateCollectionsourceValueEnumMap = {
  0: PlaybackSource.allSongs,
  1: PlaybackSource.playlist,
  2: PlaybackSource.favorites,
  3: PlaybackSource.recent,
  4: PlaybackSource.search,
};

Id _playbackStateCollectionGetId(PlaybackStateCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _playbackStateCollectionGetLinks(
  PlaybackStateCollection object,
) {
  return [];
}

void _playbackStateCollectionAttach(
  IsarCollection<dynamic> col,
  Id id,
  PlaybackStateCollection object,
) {
  object.id = id;
}

extension PlaybackStateCollectionQueryWhereSort
    on QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QWhere> {
  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PlaybackStateCollectionQueryWhere
    on
        QueryBuilder<
          PlaybackStateCollection,
          PlaybackStateCollection,
          QWhereClause
        > {
  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
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
    PlaybackStateCollection,
    PlaybackStateCollection,
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
    PlaybackStateCollection,
    PlaybackStateCollection,
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
    PlaybackStateCollection,
    PlaybackStateCollection,
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
}

extension PlaybackStateCollectionQueryFilter
    on
        QueryBuilder<
          PlaybackStateCollection,
          PlaybackStateCollection,
          QFilterCondition
        > {
  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  currentIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'currentIndex', value: value),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  currentIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'currentIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  currentIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'currentIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  currentIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'currentIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
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
    PlaybackStateCollection,
    PlaybackStateCollection,
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
    PlaybackStateCollection,
    PlaybackStateCollection,
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
    PlaybackStateCollection,
    PlaybackStateCollection,
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
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  originalQueueSongIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'originalQueueSongIds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  originalQueueSongIdsElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'originalQueueSongIds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  originalQueueSongIdsElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'originalQueueSongIds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  originalQueueSongIdsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'originalQueueSongIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  originalQueueSongIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalQueueSongIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  originalQueueSongIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'originalQueueSongIds', 0, true, 0, true);
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  originalQueueSongIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'originalQueueSongIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  originalQueueSongIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalQueueSongIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  originalQueueSongIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalQueueSongIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  originalQueueSongIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalQueueSongIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
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
    PlaybackStateCollection,
    PlaybackStateCollection,
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
    PlaybackStateCollection,
    PlaybackStateCollection,
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
    PlaybackStateCollection,
    PlaybackStateCollection,
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
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  queueSongIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'queueSongIds', value: value),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  queueSongIdsElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'queueSongIds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  queueSongIdsElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'queueSongIds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  queueSongIdsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'queueSongIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  queueSongIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'queueSongIds', length, true, length, true);
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  queueSongIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'queueSongIds', 0, true, 0, true);
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  queueSongIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'queueSongIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  queueSongIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'queueSongIds', 0, true, length, include);
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  queueSongIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'queueSongIds', length, include, 999999, true);
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  queueSongIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'queueSongIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  repeatModeEqualTo(PlayerRepeatMode value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'repeatMode', value: value),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  repeatModeGreaterThan(PlayerRepeatMode value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'repeatMode',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  repeatModeLessThan(PlayerRepeatMode value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'repeatMode',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  repeatModeBetween(
    PlayerRepeatMode lower,
    PlayerRepeatMode upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'repeatMode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  shuffleEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'shuffle', value: value),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  sourceEqualTo(PlaybackSource value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: value),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  sourceGreaterThan(PlaybackSource value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'source',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  sourceLessThan(PlaybackSource value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'source',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  sourceBetween(
    PlaybackSource lower,
    PlaybackSource upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'source',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  sourceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  sourceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  sourceIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceId', value: value),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  sourceIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  sourceIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  sourceIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  speedEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'speed',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  speedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'speed',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  speedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'speed',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  speedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'speed',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PlaybackStateCollection,
    PlaybackStateCollection,
    QAfterFilterCondition
  >
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PlaybackStateCollectionQueryObject
    on
        QueryBuilder<
          PlaybackStateCollection,
          PlaybackStateCollection,
          QFilterCondition
        > {}

extension PlaybackStateCollectionQueryLinks
    on
        QueryBuilder<
          PlaybackStateCollection,
          PlaybackStateCollection,
          QFilterCondition
        > {}

extension PlaybackStateCollectionQuerySortBy
    on QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QSortBy> {
  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortByCurrentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortByCurrentIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortByPositionMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionMs', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortByPositionMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionMs', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortByRepeatMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatMode', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortByRepeatModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatMode', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortByShuffle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffle', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortByShuffleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffle', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortBySpeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speed', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortBySpeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speed', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension PlaybackStateCollectionQuerySortThenBy
    on
        QueryBuilder<
          PlaybackStateCollection,
          PlaybackStateCollection,
          QSortThenBy
        > {
  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenByCurrentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenByCurrentIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenByPositionMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionMs', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenByPositionMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionMs', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenByRepeatMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatMode', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenByRepeatModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatMode', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenByShuffle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffle', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenByShuffleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffle', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenBySpeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speed', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenBySpeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speed', Sort.desc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension PlaybackStateCollectionQueryWhereDistinct
    on
        QueryBuilder<
          PlaybackStateCollection,
          PlaybackStateCollection,
          QDistinct
        > {
  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QDistinct>
  distinctByCurrentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentIndex');
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QDistinct>
  distinctByOriginalQueueSongIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalQueueSongIds');
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QDistinct>
  distinctByPositionMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'positionMs');
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QDistinct>
  distinctByQueueSongIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'queueSongIds');
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QDistinct>
  distinctByRepeatMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatMode');
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QDistinct>
  distinctByShuffle() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shuffle');
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QDistinct>
  distinctBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source');
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QDistinct>
  distinctBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceId');
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QDistinct>
  distinctBySpeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'speed');
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackStateCollection, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension PlaybackStateCollectionQueryProperty
    on
        QueryBuilder<
          PlaybackStateCollection,
          PlaybackStateCollection,
          QQueryProperty
        > {
  QueryBuilder<PlaybackStateCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PlaybackStateCollection, int, QQueryOperations>
  currentIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentIndex');
    });
  }

  QueryBuilder<PlaybackStateCollection, List<int>, QQueryOperations>
  originalQueueSongIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalQueueSongIds');
    });
  }

  QueryBuilder<PlaybackStateCollection, int, QQueryOperations>
  positionMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'positionMs');
    });
  }

  QueryBuilder<PlaybackStateCollection, List<int>, QQueryOperations>
  queueSongIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'queueSongIds');
    });
  }

  QueryBuilder<PlaybackStateCollection, PlayerRepeatMode, QQueryOperations>
  repeatModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatMode');
    });
  }

  QueryBuilder<PlaybackStateCollection, bool, QQueryOperations>
  shuffleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shuffle');
    });
  }

  QueryBuilder<PlaybackStateCollection, PlaybackSource, QQueryOperations>
  sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<PlaybackStateCollection, int?, QQueryOperations>
  sourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceId');
    });
  }

  QueryBuilder<PlaybackStateCollection, double, QQueryOperations>
  speedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'speed');
    });
  }

  QueryBuilder<PlaybackStateCollection, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
