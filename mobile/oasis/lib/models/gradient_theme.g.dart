// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gradient_theme.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetGradientThemeModelCollection on Isar {
  IsarCollection<GradientThemeModel> get gradientThemeModels =>
      this.collection();
}

const GradientThemeModelSchema = CollectionSchema(
  name: r'GradientThemeModel',
  id: -1041359893477186510,
  properties: {
    r'endColorValue': PropertySchema(
      id: 0,
      name: r'endColorValue',
      type: IsarType.long,
    ),
    r'isCurrent': PropertySchema(
      id: 1,
      name: r'isCurrent',
      type: IsarType.bool,
    ),
    r'isPreset': PropertySchema(
      id: 2,
      name: r'isPreset',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 3,
      name: r'name',
      type: IsarType.string,
    ),
    r'startColorValue': PropertySchema(
      id: 4,
      name: r'startColorValue',
      type: IsarType.long,
    )
  },
  estimateSize: _gradientThemeModelEstimateSize,
  serialize: _gradientThemeModelSerialize,
  deserialize: _gradientThemeModelDeserialize,
  deserializeProp: _gradientThemeModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _gradientThemeModelGetId,
  getLinks: _gradientThemeModelGetLinks,
  attach: _gradientThemeModelAttach,
  version: '3.1.0+1',
);

int _gradientThemeModelEstimateSize(
  GradientThemeModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _gradientThemeModelSerialize(
  GradientThemeModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.endColorValue);
  writer.writeBool(offsets[1], object.isCurrent);
  writer.writeBool(offsets[2], object.isPreset);
  writer.writeString(offsets[3], object.name);
  writer.writeLong(offsets[4], object.startColorValue);
}

GradientThemeModel _gradientThemeModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GradientThemeModel(
    endColorValue: reader.readLong(offsets[0]),
    id: id,
    isCurrent: reader.readBoolOrNull(offsets[1]) ?? false,
    isPreset: reader.readBoolOrNull(offsets[2]) ?? false,
    name: reader.readString(offsets[3]),
    startColorValue: reader.readLong(offsets[4]),
  );
  return object;
}

P _gradientThemeModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 2:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _gradientThemeModelGetId(GradientThemeModel object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _gradientThemeModelGetLinks(
    GradientThemeModel object) {
  return [];
}

void _gradientThemeModelAttach(
    IsarCollection<dynamic> col, Id id, GradientThemeModel object) {
  object.id = id;
}

extension GradientThemeModelQueryWhereSort
    on QueryBuilder<GradientThemeModel, GradientThemeModel, QWhere> {
  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GradientThemeModelQueryWhere
    on QueryBuilder<GradientThemeModel, GradientThemeModel, QWhereClause> {
  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterWhereClause>
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

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension GradientThemeModelQueryFilter
    on QueryBuilder<GradientThemeModel, GradientThemeModel, QFilterCondition> {
  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      endColorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endColorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      endColorValueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endColorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      endColorValueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endColorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      endColorValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endColorValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      idGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      idLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      idBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      isCurrentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCurrent',
        value: value,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      isPresetEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPreset',
        value: value,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      startColorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startColorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      startColorValueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startColorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      startColorValueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startColorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterFilterCondition>
      startColorValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startColorValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension GradientThemeModelQueryObject
    on QueryBuilder<GradientThemeModel, GradientThemeModel, QFilterCondition> {}

extension GradientThemeModelQueryLinks
    on QueryBuilder<GradientThemeModel, GradientThemeModel, QFilterCondition> {}

extension GradientThemeModelQuerySortBy
    on QueryBuilder<GradientThemeModel, GradientThemeModel, QSortBy> {
  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      sortByEndColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endColorValue', Sort.asc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      sortByEndColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endColorValue', Sort.desc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      sortByIsCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCurrent', Sort.asc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      sortByIsCurrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCurrent', Sort.desc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      sortByIsPreset() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPreset', Sort.asc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      sortByIsPresetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPreset', Sort.desc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      sortByStartColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startColorValue', Sort.asc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      sortByStartColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startColorValue', Sort.desc);
    });
  }
}

extension GradientThemeModelQuerySortThenBy
    on QueryBuilder<GradientThemeModel, GradientThemeModel, QSortThenBy> {
  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      thenByEndColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endColorValue', Sort.asc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      thenByEndColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endColorValue', Sort.desc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      thenByIsCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCurrent', Sort.asc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      thenByIsCurrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCurrent', Sort.desc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      thenByIsPreset() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPreset', Sort.asc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      thenByIsPresetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPreset', Sort.desc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      thenByStartColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startColorValue', Sort.asc);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QAfterSortBy>
      thenByStartColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startColorValue', Sort.desc);
    });
  }
}

extension GradientThemeModelQueryWhereDistinct
    on QueryBuilder<GradientThemeModel, GradientThemeModel, QDistinct> {
  QueryBuilder<GradientThemeModel, GradientThemeModel, QDistinct>
      distinctByEndColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endColorValue');
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QDistinct>
      distinctByIsCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCurrent');
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QDistinct>
      distinctByIsPreset() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPreset');
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QDistinct>
      distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GradientThemeModel, GradientThemeModel, QDistinct>
      distinctByStartColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startColorValue');
    });
  }
}

extension GradientThemeModelQueryProperty
    on QueryBuilder<GradientThemeModel, GradientThemeModel, QQueryProperty> {
  QueryBuilder<GradientThemeModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<GradientThemeModel, int, QQueryOperations>
      endColorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endColorValue');
    });
  }

  QueryBuilder<GradientThemeModel, bool, QQueryOperations> isCurrentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCurrent');
    });
  }

  QueryBuilder<GradientThemeModel, bool, QQueryOperations> isPresetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPreset');
    });
  }

  QueryBuilder<GradientThemeModel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<GradientThemeModel, int, QQueryOperations>
      startColorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startColorValue');
    });
  }
}
