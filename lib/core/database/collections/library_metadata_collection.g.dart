// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_metadata_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetLibraryMetadataCollectionCollection on Isar {
  IsarCollection<LibraryMetadataCollection> get libraryMetadataCollections =>
      this.collection();
}

const LibraryMetadataCollectionSchema = CollectionSchema(
  name: r'LibraryMetadataCollection',
  id: -8500150896506118078,
  properties: {
    r'lastSongSyncAt': PropertySchema(
      id: 0,
      name: r'lastSongSyncAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _libraryMetadataCollectionEstimateSize,
  serialize: _libraryMetadataCollectionSerialize,
  deserialize: _libraryMetadataCollectionDeserialize,
  deserializeProp: _libraryMetadataCollectionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _libraryMetadataCollectionGetId,
  getLinks: _libraryMetadataCollectionGetLinks,
  attach: _libraryMetadataCollectionAttach,
  version: '3.4.1',
);

int _libraryMetadataCollectionEstimateSize(
  LibraryMetadataCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _libraryMetadataCollectionSerialize(
  LibraryMetadataCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.lastSongSyncAt);
}

LibraryMetadataCollection _libraryMetadataCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LibraryMetadataCollection();
  object.id = id;
  object.lastSongSyncAt = reader.readDateTimeOrNull(offsets[0]);
  return object;
}

P _libraryMetadataCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _libraryMetadataCollectionGetId(LibraryMetadataCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _libraryMetadataCollectionGetLinks(
  LibraryMetadataCollection object,
) {
  return [];
}

void _libraryMetadataCollectionAttach(
  IsarCollection<dynamic> col,
  Id id,
  LibraryMetadataCollection object,
) {
  object.id = id;
}

extension LibraryMetadataCollectionQueryWhereSort
    on
        QueryBuilder<
          LibraryMetadataCollection,
          LibraryMetadataCollection,
          QWhere
        > {
  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterWhere
  >
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LibraryMetadataCollectionQueryWhere
    on
        QueryBuilder<
          LibraryMetadataCollection,
          LibraryMetadataCollection,
          QWhereClause
        > {
  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
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
    LibraryMetadataCollection,
    LibraryMetadataCollection,
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
    LibraryMetadataCollection,
    LibraryMetadataCollection,
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
    LibraryMetadataCollection,
    LibraryMetadataCollection,
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

extension LibraryMetadataCollectionQueryFilter
    on
        QueryBuilder<
          LibraryMetadataCollection,
          LibraryMetadataCollection,
          QFilterCondition
        > {
  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
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
    LibraryMetadataCollection,
    LibraryMetadataCollection,
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
    LibraryMetadataCollection,
    LibraryMetadataCollection,
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
    LibraryMetadataCollection,
    LibraryMetadataCollection,
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
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterFilterCondition
  >
  lastSongSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastSongSyncAt'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterFilterCondition
  >
  lastSongSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastSongSyncAt'),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterFilterCondition
  >
  lastSongSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSongSyncAt', value: value),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterFilterCondition
  >
  lastSongSyncAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSongSyncAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterFilterCondition
  >
  lastSongSyncAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSongSyncAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterFilterCondition
  >
  lastSongSyncAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSongSyncAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension LibraryMetadataCollectionQueryObject
    on
        QueryBuilder<
          LibraryMetadataCollection,
          LibraryMetadataCollection,
          QFilterCondition
        > {}

extension LibraryMetadataCollectionQueryLinks
    on
        QueryBuilder<
          LibraryMetadataCollection,
          LibraryMetadataCollection,
          QFilterCondition
        > {}

extension LibraryMetadataCollectionQuerySortBy
    on
        QueryBuilder<
          LibraryMetadataCollection,
          LibraryMetadataCollection,
          QSortBy
        > {
  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterSortBy
  >
  sortByLastSongSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSongSyncAt', Sort.asc);
    });
  }

  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterSortBy
  >
  sortByLastSongSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSongSyncAt', Sort.desc);
    });
  }
}

extension LibraryMetadataCollectionQuerySortThenBy
    on
        QueryBuilder<
          LibraryMetadataCollection,
          LibraryMetadataCollection,
          QSortThenBy
        > {
  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterSortBy
  >
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterSortBy
  >
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterSortBy
  >
  thenByLastSongSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSongSyncAt', Sort.asc);
    });
  }

  QueryBuilder<
    LibraryMetadataCollection,
    LibraryMetadataCollection,
    QAfterSortBy
  >
  thenByLastSongSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSongSyncAt', Sort.desc);
    });
  }
}

extension LibraryMetadataCollectionQueryWhereDistinct
    on
        QueryBuilder<
          LibraryMetadataCollection,
          LibraryMetadataCollection,
          QDistinct
        > {
  QueryBuilder<LibraryMetadataCollection, LibraryMetadataCollection, QDistinct>
  distinctByLastSongSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSongSyncAt');
    });
  }
}

extension LibraryMetadataCollectionQueryProperty
    on
        QueryBuilder<
          LibraryMetadataCollection,
          LibraryMetadataCollection,
          QQueryProperty
        > {
  QueryBuilder<LibraryMetadataCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LibraryMetadataCollection, DateTime?, QQueryOperations>
  lastSongSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSongSyncAt');
    });
  }
}
