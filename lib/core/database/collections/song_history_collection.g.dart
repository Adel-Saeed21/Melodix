// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_history_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetSongHistoryCollectionCollection on Isar {
  IsarCollection<SongHistoryCollection> get songHistoryCollections =>
      this.collection();
}

const SongHistoryCollectionSchema = CollectionSchema(
  name: r'SongHistoryCollection',
  id: -5416703959067659412,
  properties: {
    r'artist': PropertySchema(id: 0, name: r'artist', type: IsarType.string),
    r'durationMs': PropertySchema(
      id: 1,
      name: r'durationMs',
      type: IsarType.long,
    ),
    r'isFavorite': PropertySchema(
      id: 2,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'listenedMs': PropertySchema(
      id: 3,
      name: r'listenedMs',
      type: IsarType.long,
    ),
    r'playCount': PropertySchema(
      id: 4,
      name: r'playCount',
      type: IsarType.long,
    ),
    r'removedAt': PropertySchema(
      id: 5,
      name: r'removedAt',
      type: IsarType.dateTime,
    ),
    r'title': PropertySchema(id: 6, name: r'title', type: IsarType.string),
  },

  estimateSize: _songHistoryCollectionEstimateSize,
  serialize: _songHistoryCollectionSerialize,
  deserialize: _songHistoryCollectionDeserialize,
  deserializeProp: _songHistoryCollectionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _songHistoryCollectionGetId,
  getLinks: _songHistoryCollectionGetLinks,
  attach: _songHistoryCollectionAttach,
  version: '3.4.1',
);

int _songHistoryCollectionEstimateSize(
  SongHistoryCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.artist.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _songHistoryCollectionSerialize(
  SongHistoryCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.artist);
  writer.writeLong(offsets[1], object.durationMs);
  writer.writeBool(offsets[2], object.isFavorite);
  writer.writeLong(offsets[3], object.listenedMs);
  writer.writeLong(offsets[4], object.playCount);
  writer.writeDateTime(offsets[5], object.removedAt);
  writer.writeString(offsets[6], object.title);
}

SongHistoryCollection _songHistoryCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SongHistoryCollection();
  object.artist = reader.readString(offsets[0]);
  object.durationMs = reader.readLong(offsets[1]);
  object.id = id;
  object.isFavorite = reader.readBool(offsets[2]);
  object.listenedMs = reader.readLong(offsets[3]);
  object.playCount = reader.readLong(offsets[4]);
  object.removedAt = reader.readDateTime(offsets[5]);
  object.title = reader.readString(offsets[6]);
  return object;
}

P _songHistoryCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _songHistoryCollectionGetId(SongHistoryCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _songHistoryCollectionGetLinks(
  SongHistoryCollection object,
) {
  return [];
}

void _songHistoryCollectionAttach(
  IsarCollection<dynamic> col,
  Id id,
  SongHistoryCollection object,
) {
  object.id = id;
}

extension SongHistoryCollectionQueryWhereSort
    on QueryBuilder<SongHistoryCollection, SongHistoryCollection, QWhere> {
  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SongHistoryCollectionQueryWhere
    on
        QueryBuilder<
          SongHistoryCollection,
          SongHistoryCollection,
          QWhereClause
        > {
  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterWhereClause>
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

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterWhereClause>
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

extension SongHistoryCollectionQueryFilter
    on
        QueryBuilder<
          SongHistoryCollection,
          SongHistoryCollection,
          QFilterCondition
        > {
  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  artistEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'artist',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  artistGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'artist',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  artistLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'artist',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  artistBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'artist',
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
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  artistStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'artist',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  artistEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'artist',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  artistContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'artist',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  artistMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'artist',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  artistIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'artist', value: ''),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  artistIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'artist', value: ''),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  durationMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'durationMs', value: value),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  durationMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'durationMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  durationMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'durationMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  durationMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'durationMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
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
    SongHistoryCollection,
    SongHistoryCollection,
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
    SongHistoryCollection,
    SongHistoryCollection,
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
    SongHistoryCollection,
    SongHistoryCollection,
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
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  isFavoriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isFavorite', value: value),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  listenedMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'listenedMs', value: value),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  listenedMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'listenedMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  listenedMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'listenedMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  listenedMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'listenedMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
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
    SongHistoryCollection,
    SongHistoryCollection,
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
    SongHistoryCollection,
    SongHistoryCollection,
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
    SongHistoryCollection,
    SongHistoryCollection,
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
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  removedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'removedAt', value: value),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  removedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'removedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  removedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'removedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  removedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'removedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
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
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    SongHistoryCollection,
    SongHistoryCollection,
    QAfterFilterCondition
  >
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }
}

extension SongHistoryCollectionQueryObject
    on
        QueryBuilder<
          SongHistoryCollection,
          SongHistoryCollection,
          QFilterCondition
        > {}

extension SongHistoryCollectionQueryLinks
    on
        QueryBuilder<
          SongHistoryCollection,
          SongHistoryCollection,
          QFilterCondition
        > {}

extension SongHistoryCollectionQuerySortBy
    on QueryBuilder<SongHistoryCollection, SongHistoryCollection, QSortBy> {
  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByArtist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artist', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByArtistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artist', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByListenedMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listenedMs', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByListenedMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listenedMs', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByPlayCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playCount', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByPlayCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playCount', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByRemovedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'removedAt', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByRemovedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'removedAt', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension SongHistoryCollectionQuerySortThenBy
    on QueryBuilder<SongHistoryCollection, SongHistoryCollection, QSortThenBy> {
  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByArtist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artist', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByArtistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artist', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByListenedMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listenedMs', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByListenedMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listenedMs', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByPlayCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playCount', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByPlayCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playCount', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByRemovedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'removedAt', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByRemovedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'removedAt', Sort.desc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QAfterSortBy>
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension SongHistoryCollectionQueryWhereDistinct
    on QueryBuilder<SongHistoryCollection, SongHistoryCollection, QDistinct> {
  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QDistinct>
  distinctByArtist({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'artist', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QDistinct>
  distinctByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationMs');
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QDistinct>
  distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QDistinct>
  distinctByListenedMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'listenedMs');
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QDistinct>
  distinctByPlayCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'playCount');
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QDistinct>
  distinctByRemovedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'removedAt');
    });
  }

  QueryBuilder<SongHistoryCollection, SongHistoryCollection, QDistinct>
  distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension SongHistoryCollectionQueryProperty
    on
        QueryBuilder<
          SongHistoryCollection,
          SongHistoryCollection,
          QQueryProperty
        > {
  QueryBuilder<SongHistoryCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SongHistoryCollection, String, QQueryOperations>
  artistProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'artist');
    });
  }

  QueryBuilder<SongHistoryCollection, int, QQueryOperations>
  durationMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationMs');
    });
  }

  QueryBuilder<SongHistoryCollection, bool, QQueryOperations>
  isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<SongHistoryCollection, int, QQueryOperations>
  listenedMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'listenedMs');
    });
  }

  QueryBuilder<SongHistoryCollection, int, QQueryOperations>
  playCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'playCount');
    });
  }

  QueryBuilder<SongHistoryCollection, DateTime, QQueryOperations>
  removedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'removedAt');
    });
  }

  QueryBuilder<SongHistoryCollection, String, QQueryOperations>
  titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
