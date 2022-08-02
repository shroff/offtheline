// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, unused_local_variable

extension GetNoteCollection on Isar {
  IsarCollection<Note> get notes => getCollection();
}

const NoteSchema = CollectionSchema(
  name: 'Note',
  schema:
      '{"name":"Note","idName":"id","properties":[{"name":"archived","type":"Bool"},{"name":"color","type":"String"},{"name":"creationTime","type":"Long"},{"name":"details","type":"String"},{"name":"starred","type":"Bool"},{"name":"title","type":"String"},{"name":"updateTime","type":"Long"}],"indexes":[],"links":[]}',
  idName: 'id',
  propertyIds: {
    'archived': 0,
    'color': 1,
    'creationTime': 2,
    'details': 3,
    'starred': 4,
    'title': 5,
    'updateTime': 6
  },
  listProperties: {},
  indexIds: {},
  indexValueTypes: {},
  linkIds: {},
  backlinkLinkNames: {},
  getId: _noteGetId,
  setId: _noteSetId,
  getLinks: _noteGetLinks,
  attachLinks: _noteAttachLinks,
  serializeNative: _noteSerializeNative,
  deserializeNative: _noteDeserializeNative,
  deserializePropNative: _noteDeserializePropNative,
  serializeWeb: _noteSerializeWeb,
  deserializeWeb: _noteDeserializeWeb,
  deserializePropWeb: _noteDeserializePropWeb,
  version: 3,
);

int? _noteGetId(Note object) {
  if (object.id == Isar.autoIncrement) {
    return null;
  } else {
    return object.id;
  }
}

void _noteSetId(Note object, int id) {
  object.id = id;
}

List<IsarLinkBase> _noteGetLinks(Note object) {
  return [];
}

void _noteSerializeNative(IsarCollection<Note> collection, IsarRawObject rawObj,
    Note object, int staticSize, List<int> offsets, AdapterAlloc alloc) {
  var dynamicSize = 0;
  final value0 = object.archived;
  final _archived = value0;
  final value1 = object.color;
  IsarUint8List? _color;
  if (value1 != null) {
    _color = IsarBinaryWriter.utf8Encoder.convert(value1);
  }
  dynamicSize += (_color?.length ?? 0) as int;
  final value2 = object.creationTime;
  final _creationTime = value2;
  final value3 = object.details;
  IsarUint8List? _details;
  if (value3 != null) {
    _details = IsarBinaryWriter.utf8Encoder.convert(value3);
  }
  dynamicSize += (_details?.length ?? 0) as int;
  final value4 = object.starred;
  final _starred = value4;
  final value5 = object.title;
  final _title = IsarBinaryWriter.utf8Encoder.convert(value5);
  dynamicSize += (_title.length) as int;
  final value6 = object.updateTime;
  final _updateTime = value6;
  final size = staticSize + dynamicSize;

  rawObj.buffer = alloc(size);
  rawObj.buffer_length = size;
  final buffer = IsarNative.bufAsBytes(rawObj.buffer, size);
  final writer = IsarBinaryWriter(buffer, staticSize);
  writer.writeBool(offsets[0], _archived);
  writer.writeBytes(offsets[1], _color);
  writer.writeDateTime(offsets[2], _creationTime);
  writer.writeBytes(offsets[3], _details);
  writer.writeBool(offsets[4], _starred);
  writer.writeBytes(offsets[5], _title);
  writer.writeDateTime(offsets[6], _updateTime);
}

Note _noteDeserializeNative(IsarCollection<Note> collection, int id,
    IsarBinaryReader reader, List<int> offsets) {
  final object = Note(
    archived: reader.readBool(offsets[0]),
    color: reader.readStringOrNull(offsets[1]),
    creationTime: reader.readDateTime(offsets[2]),
    details: reader.readStringOrNull(offsets[3]),
    id: id,
    starred: reader.readBool(offsets[4]),
    title: reader.readString(offsets[5]),
    updateTime: reader.readDateTime(offsets[6]),
  );
  return object;
}

P _noteDeserializePropNative<P>(
    int id, IsarBinaryReader reader, int propertyIndex, int offset) {
  switch (propertyIndex) {
    case -1:
      return id as P;
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw 'Illegal propertyIndex';
  }
}

dynamic _noteSerializeWeb(IsarCollection<Note> collection, Note object) {
  final jsObj = IsarNative.newJsObject();
  IsarNative.jsObjectSet(jsObj, 'archived', object.archived);
  IsarNative.jsObjectSet(jsObj, 'color', object.color);
  IsarNative.jsObjectSet(jsObj, 'creationTime',
      object.creationTime.toUtc().millisecondsSinceEpoch);
  IsarNative.jsObjectSet(jsObj, 'details', object.details);
  IsarNative.jsObjectSet(jsObj, 'id', object.id);
  IsarNative.jsObjectSet(jsObj, 'starred', object.starred);
  IsarNative.jsObjectSet(jsObj, 'title', object.title);
  IsarNative.jsObjectSet(
      jsObj, 'updateTime', object.updateTime.toUtc().millisecondsSinceEpoch);
  return jsObj;
}

Note _noteDeserializeWeb(IsarCollection<Note> collection, dynamic jsObj) {
  final object = Note(
    archived: IsarNative.jsObjectGet(jsObj, 'archived') ?? false,
    color: IsarNative.jsObjectGet(jsObj, 'color'),
    creationTime: IsarNative.jsObjectGet(jsObj, 'creationTime') != null
        ? DateTime.fromMillisecondsSinceEpoch(
                IsarNative.jsObjectGet(jsObj, 'creationTime'),
                isUtc: true)
            .toLocal()
        : DateTime.fromMillisecondsSinceEpoch(0),
    details: IsarNative.jsObjectGet(jsObj, 'details'),
    id: IsarNative.jsObjectGet(jsObj, 'id'),
    starred: IsarNative.jsObjectGet(jsObj, 'starred') ?? false,
    title: IsarNative.jsObjectGet(jsObj, 'title') ?? '',
    updateTime: IsarNative.jsObjectGet(jsObj, 'updateTime') != null
        ? DateTime.fromMillisecondsSinceEpoch(
                IsarNative.jsObjectGet(jsObj, 'updateTime'),
                isUtc: true)
            .toLocal()
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
  return object;
}

P _noteDeserializePropWeb<P>(Object jsObj, String propertyName) {
  switch (propertyName) {
    case 'archived':
      return (IsarNative.jsObjectGet(jsObj, 'archived') ?? false) as P;
    case 'color':
      return (IsarNative.jsObjectGet(jsObj, 'color')) as P;
    case 'creationTime':
      return (IsarNative.jsObjectGet(jsObj, 'creationTime') != null
          ? DateTime.fromMillisecondsSinceEpoch(
                  IsarNative.jsObjectGet(jsObj, 'creationTime'),
                  isUtc: true)
              .toLocal()
          : DateTime.fromMillisecondsSinceEpoch(0)) as P;
    case 'details':
      return (IsarNative.jsObjectGet(jsObj, 'details')) as P;
    case 'id':
      return (IsarNative.jsObjectGet(jsObj, 'id')) as P;
    case 'starred':
      return (IsarNative.jsObjectGet(jsObj, 'starred') ?? false) as P;
    case 'title':
      return (IsarNative.jsObjectGet(jsObj, 'title') ?? '') as P;
    case 'updateTime':
      return (IsarNative.jsObjectGet(jsObj, 'updateTime') != null
          ? DateTime.fromMillisecondsSinceEpoch(
                  IsarNative.jsObjectGet(jsObj, 'updateTime'),
                  isUtc: true)
              .toLocal()
          : DateTime.fromMillisecondsSinceEpoch(0)) as P;
    default:
      throw 'Illegal propertyName';
  }
}

void _noteAttachLinks(IsarCollection col, int id, Note object) {}

extension NoteQueryWhereSort on QueryBuilder<Note, Note, QWhere> {
  QueryBuilder<Note, Note, QAfterWhere> anyId() {
    return addWhereClauseInternal(const IdWhereClause.any());
  }
}

extension NoteQueryWhere on QueryBuilder<Note, Note, QWhereClause> {
  QueryBuilder<Note, Note, QAfterWhereClause> idEqualTo(int id) {
    return addWhereClauseInternal(IdWhereClause.between(
      lower: id,
      includeLower: true,
      upper: id,
      includeUpper: true,
    ));
  }

  QueryBuilder<Note, Note, QAfterWhereClause> idNotEqualTo(int id) {
    if (whereSortInternal == Sort.asc) {
      return addWhereClauseInternal(
        IdWhereClause.lessThan(upper: id, includeUpper: false),
      ).addWhereClauseInternal(
        IdWhereClause.greaterThan(lower: id, includeLower: false),
      );
    } else {
      return addWhereClauseInternal(
        IdWhereClause.greaterThan(lower: id, includeLower: false),
      ).addWhereClauseInternal(
        IdWhereClause.lessThan(upper: id, includeUpper: false),
      );
    }
  }

  QueryBuilder<Note, Note, QAfterWhereClause> idGreaterThan(int id,
      {bool include = false}) {
    return addWhereClauseInternal(
      IdWhereClause.greaterThan(lower: id, includeLower: include),
    );
  }

  QueryBuilder<Note, Note, QAfterWhereClause> idLessThan(int id,
      {bool include = false}) {
    return addWhereClauseInternal(
      IdWhereClause.lessThan(upper: id, includeUpper: include),
    );
  }

  QueryBuilder<Note, Note, QAfterWhereClause> idBetween(
    int lowerId,
    int upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addWhereClauseInternal(IdWhereClause.between(
      lower: lowerId,
      includeLower: includeLower,
      upper: upperId,
      includeUpper: includeUpper,
    ));
  }
}

extension NoteQueryFilter on QueryBuilder<Note, Note, QFilterCondition> {
  QueryBuilder<Note, Note, QAfterFilterCondition> archivedEqualTo(bool value) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'archived',
      value: value,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> colorIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'color',
      value: null,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> colorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'color',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> colorGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'color',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> colorLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'color',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> colorBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'color',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> colorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'color',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> colorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'color',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> colorContains(String value,
      {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'color',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> colorMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'color',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> creationTimeEqualTo(
      DateTime value) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'creationTime',
      value: value,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> creationTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'creationTime',
      value: value,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> creationTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'creationTime',
      value: value,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> creationTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'creationTime',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> detailsIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'details',
      value: null,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> detailsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'details',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> detailsGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'details',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> detailsLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'details',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> detailsBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'details',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> detailsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'details',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> detailsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'details',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> detailsContains(String value,
      {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'details',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> detailsMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'details',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> idIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'id',
      value: null,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> idEqualTo(int value) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'id',
      value: value,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> idGreaterThan(
    int value, {
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'id',
      value: value,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> idLessThan(
    int value, {
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'id',
      value: value,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> idBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'id',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> starredEqualTo(bool value) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'starred',
      value: value,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'title',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'title',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> titleLessThan(
    String value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'title',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'title',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'title',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'title',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> titleContains(String value,
      {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'title',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> titleMatches(String pattern,
      {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'title',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> updateTimeEqualTo(
      DateTime value) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'updateTime',
      value: value,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> updateTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'updateTime',
      value: value,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> updateTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'updateTime',
      value: value,
    ));
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> updateTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'updateTime',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
    ));
  }
}

extension NoteQueryLinks on QueryBuilder<Note, Note, QFilterCondition> {}

extension NoteQueryWhereSortBy on QueryBuilder<Note, Note, QSortBy> {
  QueryBuilder<Note, Note, QAfterSortBy> sortByArchived() {
    return addSortByInternal('archived', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByArchivedDesc() {
    return addSortByInternal('archived', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByColor() {
    return addSortByInternal('color', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByColorDesc() {
    return addSortByInternal('color', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByCreationTime() {
    return addSortByInternal('creationTime', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByCreationTimeDesc() {
    return addSortByInternal('creationTime', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByDetails() {
    return addSortByInternal('details', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByDetailsDesc() {
    return addSortByInternal('details', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortById() {
    return addSortByInternal('id', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByIdDesc() {
    return addSortByInternal('id', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByStarred() {
    return addSortByInternal('starred', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByStarredDesc() {
    return addSortByInternal('starred', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByTitle() {
    return addSortByInternal('title', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByTitleDesc() {
    return addSortByInternal('title', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByUpdateTime() {
    return addSortByInternal('updateTime', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByUpdateTimeDesc() {
    return addSortByInternal('updateTime', Sort.desc);
  }
}

extension NoteQueryWhereSortThenBy on QueryBuilder<Note, Note, QSortThenBy> {
  QueryBuilder<Note, Note, QAfterSortBy> thenByArchived() {
    return addSortByInternal('archived', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByArchivedDesc() {
    return addSortByInternal('archived', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByColor() {
    return addSortByInternal('color', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByColorDesc() {
    return addSortByInternal('color', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByCreationTime() {
    return addSortByInternal('creationTime', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByCreationTimeDesc() {
    return addSortByInternal('creationTime', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByDetails() {
    return addSortByInternal('details', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByDetailsDesc() {
    return addSortByInternal('details', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenById() {
    return addSortByInternal('id', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByIdDesc() {
    return addSortByInternal('id', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByStarred() {
    return addSortByInternal('starred', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByStarredDesc() {
    return addSortByInternal('starred', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByTitle() {
    return addSortByInternal('title', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByTitleDesc() {
    return addSortByInternal('title', Sort.desc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByUpdateTime() {
    return addSortByInternal('updateTime', Sort.asc);
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByUpdateTimeDesc() {
    return addSortByInternal('updateTime', Sort.desc);
  }
}

extension NoteQueryWhereDistinct on QueryBuilder<Note, Note, QDistinct> {
  QueryBuilder<Note, Note, QDistinct> distinctByArchived() {
    return addDistinctByInternal('archived');
  }

  QueryBuilder<Note, Note, QDistinct> distinctByColor(
      {bool caseSensitive = true}) {
    return addDistinctByInternal('color', caseSensitive: caseSensitive);
  }

  QueryBuilder<Note, Note, QDistinct> distinctByCreationTime() {
    return addDistinctByInternal('creationTime');
  }

  QueryBuilder<Note, Note, QDistinct> distinctByDetails(
      {bool caseSensitive = true}) {
    return addDistinctByInternal('details', caseSensitive: caseSensitive);
  }

  QueryBuilder<Note, Note, QDistinct> distinctById() {
    return addDistinctByInternal('id');
  }

  QueryBuilder<Note, Note, QDistinct> distinctByStarred() {
    return addDistinctByInternal('starred');
  }

  QueryBuilder<Note, Note, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return addDistinctByInternal('title', caseSensitive: caseSensitive);
  }

  QueryBuilder<Note, Note, QDistinct> distinctByUpdateTime() {
    return addDistinctByInternal('updateTime');
  }
}

extension NoteQueryProperty on QueryBuilder<Note, Note, QQueryProperty> {
  QueryBuilder<Note, bool, QQueryOperations> archivedProperty() {
    return addPropertyNameInternal('archived');
  }

  QueryBuilder<Note, String?, QQueryOperations> colorProperty() {
    return addPropertyNameInternal('color');
  }

  QueryBuilder<Note, DateTime, QQueryOperations> creationTimeProperty() {
    return addPropertyNameInternal('creationTime');
  }

  QueryBuilder<Note, String?, QQueryOperations> detailsProperty() {
    return addPropertyNameInternal('details');
  }

  QueryBuilder<Note, int?, QQueryOperations> idProperty() {
    return addPropertyNameInternal('id');
  }

  QueryBuilder<Note, bool, QQueryOperations> starredProperty() {
    return addPropertyNameInternal('starred');
  }

  QueryBuilder<Note, String, QQueryOperations> titleProperty() {
    return addPropertyNameInternal('title');
  }

  QueryBuilder<Note, DateTime, QQueryOperations> updateTimeProperty() {
    return addPropertyNameInternal('updateTime');
  }
}
