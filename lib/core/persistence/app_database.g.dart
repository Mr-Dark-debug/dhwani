// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StationsTable extends Stations with TableInfo<$StationsTable, Station> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _favouriteMeta = const VerificationMeta(
    'favourite',
  );
  @override
  late final GeneratedColumn<bool> favourite = GeneratedColumn<bool>(
    'favourite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favourite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _customMeta = const VerificationMeta('custom');
  @override
  late final GeneratedColumn<bool> custom = GeneratedColumn<bool>(
    'custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payload,
    favourite,
    custom,
    sortOrder,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Station> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('favourite')) {
      context.handle(
        _favouriteMeta,
        favourite.isAcceptableOrUnknown(data['favourite']!, _favouriteMeta),
      );
    }
    if (data.containsKey('custom')) {
      context.handle(
        _customMeta,
        custom.isAcceptableOrUnknown(data['custom']!, _customMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Station map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Station(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      favourite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favourite'],
      )!,
      custom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}custom'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StationsTable createAlias(String alias) {
    return $StationsTable(attachedDatabase, alias);
  }
}

class Station extends DataClass implements Insertable<Station> {
  final String id;
  final String payload;
  final bool favourite;
  final bool custom;
  final int sortOrder;
  final DateTime updatedAt;
  const Station({
    required this.id,
    required this.payload,
    required this.favourite,
    required this.custom,
    required this.sortOrder,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['favourite'] = Variable<bool>(favourite);
    map['custom'] = Variable<bool>(custom);
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StationsCompanion toCompanion(bool nullToAbsent) {
    return StationsCompanion(
      id: Value(id),
      payload: Value(payload),
      favourite: Value(favourite),
      custom: Value(custom),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
    );
  }

  factory Station.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Station(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      favourite: serializer.fromJson<bool>(json['favourite']),
      custom: serializer.fromJson<bool>(json['custom']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'favourite': serializer.toJson<bool>(favourite),
      'custom': serializer.toJson<bool>(custom),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Station copyWith({
    String? id,
    String? payload,
    bool? favourite,
    bool? custom,
    int? sortOrder,
    DateTime? updatedAt,
  }) => Station(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    favourite: favourite ?? this.favourite,
    custom: custom ?? this.custom,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Station copyWithCompanion(StationsCompanion data) {
    return Station(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      favourite: data.favourite.present ? data.favourite.value : this.favourite,
      custom: data.custom.present ? data.custom.value : this.custom,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Station(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('favourite: $favourite, ')
          ..write('custom: $custom, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, payload, favourite, custom, sortOrder, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Station &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.favourite == this.favourite &&
          other.custom == this.custom &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt);
}

class StationsCompanion extends UpdateCompanion<Station> {
  final Value<String> id;
  final Value<String> payload;
  final Value<bool> favourite;
  final Value<bool> custom;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StationsCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.favourite = const Value.absent(),
    this.custom = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StationsCompanion.insert({
    required String id,
    required String payload,
    this.favourite = const Value.absent(),
    this.custom = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<Station> createCustom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<bool>? favourite,
    Expression<bool>? custom,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (favourite != null) 'favourite': favourite,
      if (custom != null) 'custom': custom,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StationsCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<bool>? favourite,
    Value<bool>? custom,
    Value<int>? sortOrder,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StationsCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      favourite: favourite ?? this.favourite,
      custom: custom ?? this.custom,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (favourite.present) {
      map['favourite'] = Variable<bool>(favourite.value);
    }
    if (custom.present) {
      map['custom'] = Variable<bool>(custom.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StationsCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('favourite: $favourite, ')
          ..write('custom: $custom, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryItemsTable extends HistoryItems
    with TableInfo<$HistoryItemsTable, HistoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _stationIdMeta = const VerificationMeta(
    'stationId',
  );
  @override
  late final GeneratedColumn<String> stationId = GeneratedColumn<String>(
    'station_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stationPayloadMeta = const VerificationMeta(
    'stationPayload',
  );
  @override
  late final GeneratedColumn<String> stationPayload = GeneratedColumn<String>(
    'station_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    stationId,
    stationPayload,
    playedAt,
    durationSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('station_id')) {
      context.handle(
        _stationIdMeta,
        stationId.isAcceptableOrUnknown(data['station_id']!, _stationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stationIdMeta);
    }
    if (data.containsKey('station_payload')) {
      context.handle(
        _stationPayloadMeta,
        stationPayload.isAcceptableOrUnknown(
          data['station_payload']!,
          _stationPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stationPayloadMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  HistoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryItem(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      stationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_id'],
      )!,
      stationPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_payload'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
    );
  }

  @override
  $HistoryItemsTable createAlias(String alias) {
    return $HistoryItemsTable(attachedDatabase, alias);
  }
}

class HistoryItem extends DataClass implements Insertable<HistoryItem> {
  final int rowId;
  final String stationId;
  final String stationPayload;
  final DateTime playedAt;
  final int durationSeconds;
  const HistoryItem({
    required this.rowId,
    required this.stationId,
    required this.stationPayload,
    required this.playedAt,
    required this.durationSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['station_id'] = Variable<String>(stationId);
    map['station_payload'] = Variable<String>(stationPayload);
    map['played_at'] = Variable<DateTime>(playedAt);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    return map;
  }

  HistoryItemsCompanion toCompanion(bool nullToAbsent) {
    return HistoryItemsCompanion(
      rowId: Value(rowId),
      stationId: Value(stationId),
      stationPayload: Value(stationPayload),
      playedAt: Value(playedAt),
      durationSeconds: Value(durationSeconds),
    );
  }

  factory HistoryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryItem(
      rowId: serializer.fromJson<int>(json['rowId']),
      stationId: serializer.fromJson<String>(json['stationId']),
      stationPayload: serializer.fromJson<String>(json['stationPayload']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'stationId': serializer.toJson<String>(stationId),
      'stationPayload': serializer.toJson<String>(stationPayload),
      'playedAt': serializer.toJson<DateTime>(playedAt),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
    };
  }

  HistoryItem copyWith({
    int? rowId,
    String? stationId,
    String? stationPayload,
    DateTime? playedAt,
    int? durationSeconds,
  }) => HistoryItem(
    rowId: rowId ?? this.rowId,
    stationId: stationId ?? this.stationId,
    stationPayload: stationPayload ?? this.stationPayload,
    playedAt: playedAt ?? this.playedAt,
    durationSeconds: durationSeconds ?? this.durationSeconds,
  );
  HistoryItem copyWithCompanion(HistoryItemsCompanion data) {
    return HistoryItem(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      stationId: data.stationId.present ? data.stationId.value : this.stationId,
      stationPayload: data.stationPayload.present
          ? data.stationPayload.value
          : this.stationPayload,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryItem(')
          ..write('rowId: $rowId, ')
          ..write('stationId: $stationId, ')
          ..write('stationPayload: $stationPayload, ')
          ..write('playedAt: $playedAt, ')
          ..write('durationSeconds: $durationSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(rowId, stationId, stationPayload, playedAt, durationSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryItem &&
          other.rowId == this.rowId &&
          other.stationId == this.stationId &&
          other.stationPayload == this.stationPayload &&
          other.playedAt == this.playedAt &&
          other.durationSeconds == this.durationSeconds);
}

class HistoryItemsCompanion extends UpdateCompanion<HistoryItem> {
  final Value<int> rowId;
  final Value<String> stationId;
  final Value<String> stationPayload;
  final Value<DateTime> playedAt;
  final Value<int> durationSeconds;
  const HistoryItemsCompanion({
    this.rowId = const Value.absent(),
    this.stationId = const Value.absent(),
    this.stationPayload = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
  });
  HistoryItemsCompanion.insert({
    this.rowId = const Value.absent(),
    required String stationId,
    required String stationPayload,
    required DateTime playedAt,
    this.durationSeconds = const Value.absent(),
  }) : stationId = Value(stationId),
       stationPayload = Value(stationPayload),
       playedAt = Value(playedAt);
  static Insertable<HistoryItem> custom({
    Expression<int>? rowId,
    Expression<String>? stationId,
    Expression<String>? stationPayload,
    Expression<DateTime>? playedAt,
    Expression<int>? durationSeconds,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (stationId != null) 'station_id': stationId,
      if (stationPayload != null) 'station_payload': stationPayload,
      if (playedAt != null) 'played_at': playedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    });
  }

  HistoryItemsCompanion copyWith({
    Value<int>? rowId,
    Value<String>? stationId,
    Value<String>? stationPayload,
    Value<DateTime>? playedAt,
    Value<int>? durationSeconds,
  }) {
    return HistoryItemsCompanion(
      rowId: rowId ?? this.rowId,
      stationId: stationId ?? this.stationId,
      stationPayload: stationPayload ?? this.stationPayload,
      playedAt: playedAt ?? this.playedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (stationId.present) {
      map['station_id'] = Variable<String>(stationId.value);
    }
    if (stationPayload.present) {
      map['station_payload'] = Variable<String>(stationPayload.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryItemsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('stationId: $stationId, ')
          ..write('stationPayload: $stationPayload, ')
          ..write('playedAt: $playedAt, ')
          ..write('durationSeconds: $durationSeconds')
          ..write(')'))
        .toString();
  }
}

class $RecordingItemsTable extends RecordingItems
    with TableInfo<$RecordingItemsTable, RecordingItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordingItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stationPayloadMeta = const VerificationMeta(
    'stationPayload',
  );
  @override
  late final GeneratedColumn<String> stationPayload = GeneratedColumn<String>(
    'station_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stationPayload,
    path,
    name,
    createdAt,
    durationSeconds,
    sizeBytes,
    format,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recording_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordingItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('station_payload')) {
      context.handle(
        _stationPayloadMeta,
        stationPayload.isAcceptableOrUnknown(
          data['station_payload']!,
          _stationPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stationPayloadMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordingItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordingItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      stationPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_payload'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
    );
  }

  @override
  $RecordingItemsTable createAlias(String alias) {
    return $RecordingItemsTable(attachedDatabase, alias);
  }
}

class RecordingItem extends DataClass implements Insertable<RecordingItem> {
  final String id;
  final String stationPayload;
  final String path;
  final String name;
  final DateTime createdAt;
  final int durationSeconds;
  final int sizeBytes;
  final String format;
  const RecordingItem({
    required this.id,
    required this.stationPayload,
    required this.path,
    required this.name,
    required this.createdAt,
    required this.durationSeconds,
    required this.sizeBytes,
    required this.format,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['station_payload'] = Variable<String>(stationPayload);
    map['path'] = Variable<String>(path);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['format'] = Variable<String>(format);
    return map;
  }

  RecordingItemsCompanion toCompanion(bool nullToAbsent) {
    return RecordingItemsCompanion(
      id: Value(id),
      stationPayload: Value(stationPayload),
      path: Value(path),
      name: Value(name),
      createdAt: Value(createdAt),
      durationSeconds: Value(durationSeconds),
      sizeBytes: Value(sizeBytes),
      format: Value(format),
    );
  }

  factory RecordingItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordingItem(
      id: serializer.fromJson<String>(json['id']),
      stationPayload: serializer.fromJson<String>(json['stationPayload']),
      path: serializer.fromJson<String>(json['path']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      format: serializer.fromJson<String>(json['format']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'stationPayload': serializer.toJson<String>(stationPayload),
      'path': serializer.toJson<String>(path),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'format': serializer.toJson<String>(format),
    };
  }

  RecordingItem copyWith({
    String? id,
    String? stationPayload,
    String? path,
    String? name,
    DateTime? createdAt,
    int? durationSeconds,
    int? sizeBytes,
    String? format,
  }) => RecordingItem(
    id: id ?? this.id,
    stationPayload: stationPayload ?? this.stationPayload,
    path: path ?? this.path,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    format: format ?? this.format,
  );
  RecordingItem copyWithCompanion(RecordingItemsCompanion data) {
    return RecordingItem(
      id: data.id.present ? data.id.value : this.id,
      stationPayload: data.stationPayload.present
          ? data.stationPayload.value
          : this.stationPayload,
      path: data.path.present ? data.path.value : this.path,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      format: data.format.present ? data.format.value : this.format,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordingItem(')
          ..write('id: $id, ')
          ..write('stationPayload: $stationPayload, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('format: $format')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    stationPayload,
    path,
    name,
    createdAt,
    durationSeconds,
    sizeBytes,
    format,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordingItem &&
          other.id == this.id &&
          other.stationPayload == this.stationPayload &&
          other.path == this.path &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.durationSeconds == this.durationSeconds &&
          other.sizeBytes == this.sizeBytes &&
          other.format == this.format);
}

class RecordingItemsCompanion extends UpdateCompanion<RecordingItem> {
  final Value<String> id;
  final Value<String> stationPayload;
  final Value<String> path;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> durationSeconds;
  final Value<int> sizeBytes;
  final Value<String> format;
  final Value<int> rowid;
  const RecordingItemsCompanion({
    this.id = const Value.absent(),
    this.stationPayload = const Value.absent(),
    this.path = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.format = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordingItemsCompanion.insert({
    required String id,
    required String stationPayload,
    required String path,
    required String name,
    required DateTime createdAt,
    required int durationSeconds,
    required int sizeBytes,
    required String format,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       stationPayload = Value(stationPayload),
       path = Value(path),
       name = Value(name),
       createdAt = Value(createdAt),
       durationSeconds = Value(durationSeconds),
       sizeBytes = Value(sizeBytes),
       format = Value(format);
  static Insertable<RecordingItem> custom({
    Expression<String>? id,
    Expression<String>? stationPayload,
    Expression<String>? path,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? durationSeconds,
    Expression<int>? sizeBytes,
    Expression<String>? format,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stationPayload != null) 'station_payload': stationPayload,
      if (path != null) 'path': path,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (format != null) 'format': format,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordingItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? stationPayload,
    Value<String>? path,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int>? durationSeconds,
    Value<int>? sizeBytes,
    Value<String>? format,
    Value<int>? rowid,
  }) {
    return RecordingItemsCompanion(
      id: id ?? this.id,
      stationPayload: stationPayload ?? this.stationPayload,
      path: path ?? this.path,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      format: format ?? this.format,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (stationPayload.present) {
      map['station_payload'] = Variable<String>(stationPayload.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordingItemsCompanion(')
          ..write('id: $id, ')
          ..write('stationPayload: $stationPayload, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('format: $format, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BrokenReportsTable extends BrokenReports
    with TableInfo<$BrokenReportsTable, BrokenReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrokenReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stationIdMeta = const VerificationMeta(
    'stationId',
  );
  @override
  late final GeneratedColumn<String> stationId = GeneratedColumn<String>(
    'station_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reportedAtMeta = const VerificationMeta(
    'reportedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reportedAt = GeneratedColumn<DateTime>(
    'reported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [stationId, reportedAt, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'broken_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<BrokenReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('station_id')) {
      context.handle(
        _stationIdMeta,
        stationId.isAcceptableOrUnknown(data['station_id']!, _stationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stationIdMeta);
    }
    if (data.containsKey('reported_at')) {
      context.handle(
        _reportedAtMeta,
        reportedAt.isAcceptableOrUnknown(data['reported_at']!, _reportedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reportedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stationId};
  @override
  BrokenReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BrokenReport(
      stationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_id'],
      )!,
      reportedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reported_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $BrokenReportsTable createAlias(String alias) {
    return $BrokenReportsTable(attachedDatabase, alias);
  }
}

class BrokenReport extends DataClass implements Insertable<BrokenReport> {
  final String stationId;
  final DateTime reportedAt;
  final String? note;
  const BrokenReport({
    required this.stationId,
    required this.reportedAt,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['station_id'] = Variable<String>(stationId);
    map['reported_at'] = Variable<DateTime>(reportedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  BrokenReportsCompanion toCompanion(bool nullToAbsent) {
    return BrokenReportsCompanion(
      stationId: Value(stationId),
      reportedAt: Value(reportedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory BrokenReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BrokenReport(
      stationId: serializer.fromJson<String>(json['stationId']),
      reportedAt: serializer.fromJson<DateTime>(json['reportedAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stationId': serializer.toJson<String>(stationId),
      'reportedAt': serializer.toJson<DateTime>(reportedAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  BrokenReport copyWith({
    String? stationId,
    DateTime? reportedAt,
    Value<String?> note = const Value.absent(),
  }) => BrokenReport(
    stationId: stationId ?? this.stationId,
    reportedAt: reportedAt ?? this.reportedAt,
    note: note.present ? note.value : this.note,
  );
  BrokenReport copyWithCompanion(BrokenReportsCompanion data) {
    return BrokenReport(
      stationId: data.stationId.present ? data.stationId.value : this.stationId,
      reportedAt: data.reportedAt.present
          ? data.reportedAt.value
          : this.reportedAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BrokenReport(')
          ..write('stationId: $stationId, ')
          ..write('reportedAt: $reportedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stationId, reportedAt, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrokenReport &&
          other.stationId == this.stationId &&
          other.reportedAt == this.reportedAt &&
          other.note == this.note);
}

class BrokenReportsCompanion extends UpdateCompanion<BrokenReport> {
  final Value<String> stationId;
  final Value<DateTime> reportedAt;
  final Value<String?> note;
  final Value<int> rowid;
  const BrokenReportsCompanion({
    this.stationId = const Value.absent(),
    this.reportedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BrokenReportsCompanion.insert({
    required String stationId,
    required DateTime reportedAt,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : stationId = Value(stationId),
       reportedAt = Value(reportedAt);
  static Insertable<BrokenReport> custom({
    Expression<String>? stationId,
    Expression<DateTime>? reportedAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stationId != null) 'station_id': stationId,
      if (reportedAt != null) 'reported_at': reportedAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BrokenReportsCompanion copyWith({
    Value<String>? stationId,
    Value<DateTime>? reportedAt,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return BrokenReportsCompanion(
      stationId: stationId ?? this.stationId,
      reportedAt: reportedAt ?? this.reportedAt,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stationId.present) {
      map['station_id'] = Variable<String>(stationId.value);
    }
    if (reportedAt.present) {
      map['reported_at'] = Variable<DateTime>(reportedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrokenReportsCompanion(')
          ..write('stationId: $stationId, ')
          ..write('reportedAt: $reportedAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StationCollectionsTable extends StationCollections
    with TableInfo<$StationCollectionsTable, StationCollection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StationCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'station_collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<StationCollection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StationCollection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StationCollection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StationCollectionsTable createAlias(String alias) {
    return $StationCollectionsTable(attachedDatabase, alias);
  }
}

class StationCollection extends DataClass
    implements Insertable<StationCollection> {
  final String id;
  final String name;
  final int sortOrder;
  final DateTime createdAt;
  const StationCollection({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StationCollectionsCompanion toCompanion(bool nullToAbsent) {
    return StationCollectionsCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory StationCollection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StationCollection(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StationCollection copyWith({
    String? id,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  }) => StationCollection(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  StationCollection copyWithCompanion(StationCollectionsCompanion data) {
    return StationCollection(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StationCollection(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StationCollection &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class StationCollectionsCompanion extends UpdateCompanion<StationCollection> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StationCollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StationCollectionsCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<StationCollection> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StationCollectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return StationCollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StationCollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionMembersTable extends CollectionMembers
    with TableInfo<$CollectionMembersTable, CollectionMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stationIdMeta = const VerificationMeta(
    'stationId',
  );
  @override
  late final GeneratedColumn<String> stationId = GeneratedColumn<String>(
    'station_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stationPayloadMeta = const VerificationMeta(
    'stationPayload',
  );
  @override
  late final GeneratedColumn<String> stationPayload = GeneratedColumn<String>(
    'station_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    collectionId,
    stationId,
    stationPayload,
    sortOrder,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('station_id')) {
      context.handle(
        _stationIdMeta,
        stationId.isAcceptableOrUnknown(data['station_id']!, _stationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stationIdMeta);
    }
    if (data.containsKey('station_payload')) {
      context.handle(
        _stationPayloadMeta,
        stationPayload.isAcceptableOrUnknown(
          data['station_payload']!,
          _stationPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stationPayloadMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collectionId, stationId};
  @override
  CollectionMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionMember(
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      stationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_id'],
      )!,
      stationPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_payload'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $CollectionMembersTable createAlias(String alias) {
    return $CollectionMembersTable(attachedDatabase, alias);
  }
}

class CollectionMember extends DataClass
    implements Insertable<CollectionMember> {
  final String collectionId;
  final String stationId;
  final String stationPayload;
  final int sortOrder;
  final DateTime addedAt;
  const CollectionMember({
    required this.collectionId,
    required this.stationId,
    required this.stationPayload,
    required this.sortOrder,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_id'] = Variable<String>(collectionId);
    map['station_id'] = Variable<String>(stationId);
    map['station_payload'] = Variable<String>(stationPayload);
    map['sort_order'] = Variable<int>(sortOrder);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  CollectionMembersCompanion toCompanion(bool nullToAbsent) {
    return CollectionMembersCompanion(
      collectionId: Value(collectionId),
      stationId: Value(stationId),
      stationPayload: Value(stationPayload),
      sortOrder: Value(sortOrder),
      addedAt: Value(addedAt),
    );
  }

  factory CollectionMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionMember(
      collectionId: serializer.fromJson<String>(json['collectionId']),
      stationId: serializer.fromJson<String>(json['stationId']),
      stationPayload: serializer.fromJson<String>(json['stationPayload']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionId': serializer.toJson<String>(collectionId),
      'stationId': serializer.toJson<String>(stationId),
      'stationPayload': serializer.toJson<String>(stationPayload),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  CollectionMember copyWith({
    String? collectionId,
    String? stationId,
    String? stationPayload,
    int? sortOrder,
    DateTime? addedAt,
  }) => CollectionMember(
    collectionId: collectionId ?? this.collectionId,
    stationId: stationId ?? this.stationId,
    stationPayload: stationPayload ?? this.stationPayload,
    sortOrder: sortOrder ?? this.sortOrder,
    addedAt: addedAt ?? this.addedAt,
  );
  CollectionMember copyWithCompanion(CollectionMembersCompanion data) {
    return CollectionMember(
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      stationId: data.stationId.present ? data.stationId.value : this.stationId,
      stationPayload: data.stationPayload.present
          ? data.stationPayload.value
          : this.stationPayload,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionMember(')
          ..write('collectionId: $collectionId, ')
          ..write('stationId: $stationId, ')
          ..write('stationPayload: $stationPayload, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(collectionId, stationId, stationPayload, sortOrder, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionMember &&
          other.collectionId == this.collectionId &&
          other.stationId == this.stationId &&
          other.stationPayload == this.stationPayload &&
          other.sortOrder == this.sortOrder &&
          other.addedAt == this.addedAt);
}

class CollectionMembersCompanion extends UpdateCompanion<CollectionMember> {
  final Value<String> collectionId;
  final Value<String> stationId;
  final Value<String> stationPayload;
  final Value<int> sortOrder;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const CollectionMembersCompanion({
    this.collectionId = const Value.absent(),
    this.stationId = const Value.absent(),
    this.stationPayload = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionMembersCompanion.insert({
    required String collectionId,
    required String stationId,
    required String stationPayload,
    this.sortOrder = const Value.absent(),
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : collectionId = Value(collectionId),
       stationId = Value(stationId),
       stationPayload = Value(stationPayload),
       addedAt = Value(addedAt);
  static Insertable<CollectionMember> custom({
    Expression<String>? collectionId,
    Expression<String>? stationId,
    Expression<String>? stationPayload,
    Expression<int>? sortOrder,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionId != null) 'collection_id': collectionId,
      if (stationId != null) 'station_id': stationId,
      if (stationPayload != null) 'station_payload': stationPayload,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionMembersCompanion copyWith({
    Value<String>? collectionId,
    Value<String>? stationId,
    Value<String>? stationPayload,
    Value<int>? sortOrder,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return CollectionMembersCompanion(
      collectionId: collectionId ?? this.collectionId,
      stationId: stationId ?? this.stationId,
      stationPayload: stationPayload ?? this.stationPayload,
      sortOrder: sortOrder ?? this.sortOrder,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (stationId.present) {
      map['station_id'] = Variable<String>(stationId.value);
    }
    if (stationPayload.present) {
      map['station_payload'] = Variable<String>(stationPayload.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionMembersCompanion(')
          ..write('collectionId: $collectionId, ')
          ..write('stationId: $stationId, ')
          ..write('stationPayload: $stationPayload, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StationsTable stations = $StationsTable(this);
  late final $HistoryItemsTable historyItems = $HistoryItemsTable(this);
  late final $RecordingItemsTable recordingItems = $RecordingItemsTable(this);
  late final $BrokenReportsTable brokenReports = $BrokenReportsTable(this);
  late final $StationCollectionsTable stationCollections =
      $StationCollectionsTable(this);
  late final $CollectionMembersTable collectionMembers =
      $CollectionMembersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    stations,
    historyItems,
    recordingItems,
    brokenReports,
    stationCollections,
    collectionMembers,
  ];
}

typedef $$StationsTableCreateCompanionBuilder =
    StationsCompanion Function({
      required String id,
      required String payload,
      Value<bool> favourite,
      Value<bool> custom,
      Value<int> sortOrder,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StationsTableUpdateCompanionBuilder =
    StationsCompanion Function({
      Value<String> id,
      Value<String> payload,
      Value<bool> favourite,
      Value<bool> custom,
      Value<int> sortOrder,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StationsTableFilterComposer
    extends Composer<_$AppDatabase, $StationsTable> {
  $$StationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favourite => $composableBuilder(
    column: $table.favourite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get custom => $composableBuilder(
    column: $table.custom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StationsTableOrderingComposer
    extends Composer<_$AppDatabase, $StationsTable> {
  $$StationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favourite => $composableBuilder(
    column: $table.favourite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get custom => $composableBuilder(
    column: $table.custom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StationsTable> {
  $$StationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<bool> get favourite =>
      $composableBuilder(column: $table.favourite, builder: (column) => column);

  GeneratedColumn<bool> get custom =>
      $composableBuilder(column: $table.custom, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StationsTable,
          Station,
          $$StationsTableFilterComposer,
          $$StationsTableOrderingComposer,
          $$StationsTableAnnotationComposer,
          $$StationsTableCreateCompanionBuilder,
          $$StationsTableUpdateCompanionBuilder,
          (Station, BaseReferences<_$AppDatabase, $StationsTable, Station>),
          Station,
          PrefetchHooks Function()
        > {
  $$StationsTableTableManager(_$AppDatabase db, $StationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<bool> favourite = const Value.absent(),
                Value<bool> custom = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StationsCompanion(
                id: id,
                payload: payload,
                favourite: favourite,
                custom: custom,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                Value<bool> favourite = const Value.absent(),
                Value<bool> custom = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StationsCompanion.insert(
                id: id,
                payload: payload,
                favourite: favourite,
                custom: custom,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StationsTable,
      Station,
      $$StationsTableFilterComposer,
      $$StationsTableOrderingComposer,
      $$StationsTableAnnotationComposer,
      $$StationsTableCreateCompanionBuilder,
      $$StationsTableUpdateCompanionBuilder,
      (Station, BaseReferences<_$AppDatabase, $StationsTable, Station>),
      Station,
      PrefetchHooks Function()
    >;
typedef $$HistoryItemsTableCreateCompanionBuilder =
    HistoryItemsCompanion Function({
      Value<int> rowId,
      required String stationId,
      required String stationPayload,
      required DateTime playedAt,
      Value<int> durationSeconds,
    });
typedef $$HistoryItemsTableUpdateCompanionBuilder =
    HistoryItemsCompanion Function({
      Value<int> rowId,
      Value<String> stationId,
      Value<String> stationPayload,
      Value<DateTime> playedAt,
      Value<int> durationSeconds,
    });

class $$HistoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $HistoryItemsTable> {
  $$HistoryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stationId => $composableBuilder(
    column: $table.stationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stationPayload => $composableBuilder(
    column: $table.stationPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $HistoryItemsTable> {
  $$HistoryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stationId => $composableBuilder(
    column: $table.stationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stationPayload => $composableBuilder(
    column: $table.stationPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistoryItemsTable> {
  $$HistoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get stationId =>
      $composableBuilder(column: $table.stationId, builder: (column) => column);

  GeneratedColumn<String> get stationPayload => $composableBuilder(
    column: $table.stationPayload,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );
}

class $$HistoryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HistoryItemsTable,
          HistoryItem,
          $$HistoryItemsTableFilterComposer,
          $$HistoryItemsTableOrderingComposer,
          $$HistoryItemsTableAnnotationComposer,
          $$HistoryItemsTableCreateCompanionBuilder,
          $$HistoryItemsTableUpdateCompanionBuilder,
          (
            HistoryItem,
            BaseReferences<_$AppDatabase, $HistoryItemsTable, HistoryItem>,
          ),
          HistoryItem,
          PrefetchHooks Function()
        > {
  $$HistoryItemsTableTableManager(_$AppDatabase db, $HistoryItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> stationId = const Value.absent(),
                Value<String> stationPayload = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
              }) => HistoryItemsCompanion(
                rowId: rowId,
                stationId: stationId,
                stationPayload: stationPayload,
                playedAt: playedAt,
                durationSeconds: durationSeconds,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String stationId,
                required String stationPayload,
                required DateTime playedAt,
                Value<int> durationSeconds = const Value.absent(),
              }) => HistoryItemsCompanion.insert(
                rowId: rowId,
                stationId: stationId,
                stationPayload: stationPayload,
                playedAt: playedAt,
                durationSeconds: durationSeconds,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HistoryItemsTable,
      HistoryItem,
      $$HistoryItemsTableFilterComposer,
      $$HistoryItemsTableOrderingComposer,
      $$HistoryItemsTableAnnotationComposer,
      $$HistoryItemsTableCreateCompanionBuilder,
      $$HistoryItemsTableUpdateCompanionBuilder,
      (
        HistoryItem,
        BaseReferences<_$AppDatabase, $HistoryItemsTable, HistoryItem>,
      ),
      HistoryItem,
      PrefetchHooks Function()
    >;
typedef $$RecordingItemsTableCreateCompanionBuilder =
    RecordingItemsCompanion Function({
      required String id,
      required String stationPayload,
      required String path,
      required String name,
      required DateTime createdAt,
      required int durationSeconds,
      required int sizeBytes,
      required String format,
      Value<int> rowid,
    });
typedef $$RecordingItemsTableUpdateCompanionBuilder =
    RecordingItemsCompanion Function({
      Value<String> id,
      Value<String> stationPayload,
      Value<String> path,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<int> durationSeconds,
      Value<int> sizeBytes,
      Value<String> format,
      Value<int> rowid,
    });

class $$RecordingItemsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordingItemsTable> {
  $$RecordingItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stationPayload => $composableBuilder(
    column: $table.stationPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecordingItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordingItemsTable> {
  $$RecordingItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stationPayload => $composableBuilder(
    column: $table.stationPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordingItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordingItemsTable> {
  $$RecordingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stationPayload => $composableBuilder(
    column: $table.stationPayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);
}

class $$RecordingItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordingItemsTable,
          RecordingItem,
          $$RecordingItemsTableFilterComposer,
          $$RecordingItemsTableOrderingComposer,
          $$RecordingItemsTableAnnotationComposer,
          $$RecordingItemsTableCreateCompanionBuilder,
          $$RecordingItemsTableUpdateCompanionBuilder,
          (
            RecordingItem,
            BaseReferences<_$AppDatabase, $RecordingItemsTable, RecordingItem>,
          ),
          RecordingItem,
          PrefetchHooks Function()
        > {
  $$RecordingItemsTableTableManager(
    _$AppDatabase db,
    $RecordingItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordingItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordingItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordingItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> stationPayload = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordingItemsCompanion(
                id: id,
                stationPayload: stationPayload,
                path: path,
                name: name,
                createdAt: createdAt,
                durationSeconds: durationSeconds,
                sizeBytes: sizeBytes,
                format: format,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String stationPayload,
                required String path,
                required String name,
                required DateTime createdAt,
                required int durationSeconds,
                required int sizeBytes,
                required String format,
                Value<int> rowid = const Value.absent(),
              }) => RecordingItemsCompanion.insert(
                id: id,
                stationPayload: stationPayload,
                path: path,
                name: name,
                createdAt: createdAt,
                durationSeconds: durationSeconds,
                sizeBytes: sizeBytes,
                format: format,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordingItemsTable,
      RecordingItem,
      $$RecordingItemsTableFilterComposer,
      $$RecordingItemsTableOrderingComposer,
      $$RecordingItemsTableAnnotationComposer,
      $$RecordingItemsTableCreateCompanionBuilder,
      $$RecordingItemsTableUpdateCompanionBuilder,
      (
        RecordingItem,
        BaseReferences<_$AppDatabase, $RecordingItemsTable, RecordingItem>,
      ),
      RecordingItem,
      PrefetchHooks Function()
    >;
typedef $$BrokenReportsTableCreateCompanionBuilder =
    BrokenReportsCompanion Function({
      required String stationId,
      required DateTime reportedAt,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$BrokenReportsTableUpdateCompanionBuilder =
    BrokenReportsCompanion Function({
      Value<String> stationId,
      Value<DateTime> reportedAt,
      Value<String?> note,
      Value<int> rowid,
    });

class $$BrokenReportsTableFilterComposer
    extends Composer<_$AppDatabase, $BrokenReportsTable> {
  $$BrokenReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get stationId => $composableBuilder(
    column: $table.stationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reportedAt => $composableBuilder(
    column: $table.reportedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BrokenReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $BrokenReportsTable> {
  $$BrokenReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get stationId => $composableBuilder(
    column: $table.stationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reportedAt => $composableBuilder(
    column: $table.reportedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BrokenReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrokenReportsTable> {
  $$BrokenReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get stationId =>
      $composableBuilder(column: $table.stationId, builder: (column) => column);

  GeneratedColumn<DateTime> get reportedAt => $composableBuilder(
    column: $table.reportedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$BrokenReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BrokenReportsTable,
          BrokenReport,
          $$BrokenReportsTableFilterComposer,
          $$BrokenReportsTableOrderingComposer,
          $$BrokenReportsTableAnnotationComposer,
          $$BrokenReportsTableCreateCompanionBuilder,
          $$BrokenReportsTableUpdateCompanionBuilder,
          (
            BrokenReport,
            BaseReferences<_$AppDatabase, $BrokenReportsTable, BrokenReport>,
          ),
          BrokenReport,
          PrefetchHooks Function()
        > {
  $$BrokenReportsTableTableManager(_$AppDatabase db, $BrokenReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrokenReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BrokenReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BrokenReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> stationId = const Value.absent(),
                Value<DateTime> reportedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BrokenReportsCompanion(
                stationId: stationId,
                reportedAt: reportedAt,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String stationId,
                required DateTime reportedAt,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BrokenReportsCompanion.insert(
                stationId: stationId,
                reportedAt: reportedAt,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BrokenReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BrokenReportsTable,
      BrokenReport,
      $$BrokenReportsTableFilterComposer,
      $$BrokenReportsTableOrderingComposer,
      $$BrokenReportsTableAnnotationComposer,
      $$BrokenReportsTableCreateCompanionBuilder,
      $$BrokenReportsTableUpdateCompanionBuilder,
      (
        BrokenReport,
        BaseReferences<_$AppDatabase, $BrokenReportsTable, BrokenReport>,
      ),
      BrokenReport,
      PrefetchHooks Function()
    >;
typedef $$StationCollectionsTableCreateCompanionBuilder =
    StationCollectionsCompanion Function({
      required String id,
      required String name,
      Value<int> sortOrder,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$StationCollectionsTableUpdateCompanionBuilder =
    StationCollectionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$StationCollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $StationCollectionsTable> {
  $$StationCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StationCollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $StationCollectionsTable> {
  $$StationCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StationCollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StationCollectionsTable> {
  $$StationCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StationCollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StationCollectionsTable,
          StationCollection,
          $$StationCollectionsTableFilterComposer,
          $$StationCollectionsTableOrderingComposer,
          $$StationCollectionsTableAnnotationComposer,
          $$StationCollectionsTableCreateCompanionBuilder,
          $$StationCollectionsTableUpdateCompanionBuilder,
          (
            StationCollection,
            BaseReferences<
              _$AppDatabase,
              $StationCollectionsTable,
              StationCollection
            >,
          ),
          StationCollection,
          PrefetchHooks Function()
        > {
  $$StationCollectionsTableTableManager(
    _$AppDatabase db,
    $StationCollectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StationCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StationCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StationCollectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StationCollectionsCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => StationCollectionsCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StationCollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StationCollectionsTable,
      StationCollection,
      $$StationCollectionsTableFilterComposer,
      $$StationCollectionsTableOrderingComposer,
      $$StationCollectionsTableAnnotationComposer,
      $$StationCollectionsTableCreateCompanionBuilder,
      $$StationCollectionsTableUpdateCompanionBuilder,
      (
        StationCollection,
        BaseReferences<
          _$AppDatabase,
          $StationCollectionsTable,
          StationCollection
        >,
      ),
      StationCollection,
      PrefetchHooks Function()
    >;
typedef $$CollectionMembersTableCreateCompanionBuilder =
    CollectionMembersCompanion Function({
      required String collectionId,
      required String stationId,
      required String stationPayload,
      Value<int> sortOrder,
      required DateTime addedAt,
      Value<int> rowid,
    });
typedef $$CollectionMembersTableUpdateCompanionBuilder =
    CollectionMembersCompanion Function({
      Value<String> collectionId,
      Value<String> stationId,
      Value<String> stationPayload,
      Value<int> sortOrder,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

class $$CollectionMembersTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionMembersTable> {
  $$CollectionMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stationId => $composableBuilder(
    column: $table.stationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stationPayload => $composableBuilder(
    column: $table.stationPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectionMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionMembersTable> {
  $$CollectionMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stationId => $composableBuilder(
    column: $table.stationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stationPayload => $composableBuilder(
    column: $table.stationPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionMembersTable> {
  $$CollectionMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stationId =>
      $composableBuilder(column: $table.stationId, builder: (column) => column);

  GeneratedColumn<String> get stationPayload => $composableBuilder(
    column: $table.stationPayload,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$CollectionMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionMembersTable,
          CollectionMember,
          $$CollectionMembersTableFilterComposer,
          $$CollectionMembersTableOrderingComposer,
          $$CollectionMembersTableAnnotationComposer,
          $$CollectionMembersTableCreateCompanionBuilder,
          $$CollectionMembersTableUpdateCompanionBuilder,
          (
            CollectionMember,
            BaseReferences<
              _$AppDatabase,
              $CollectionMembersTable,
              CollectionMember
            >,
          ),
          CollectionMember,
          PrefetchHooks Function()
        > {
  $$CollectionMembersTableTableManager(
    _$AppDatabase db,
    $CollectionMembersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionMembersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> collectionId = const Value.absent(),
                Value<String> stationId = const Value.absent(),
                Value<String> stationPayload = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionMembersCompanion(
                collectionId: collectionId,
                stationId: stationId,
                stationPayload: stationPayload,
                sortOrder: sortOrder,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collectionId,
                required String stationId,
                required String stationPayload,
                Value<int> sortOrder = const Value.absent(),
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => CollectionMembersCompanion.insert(
                collectionId: collectionId,
                stationId: stationId,
                stationPayload: stationPayload,
                sortOrder: sortOrder,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectionMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionMembersTable,
      CollectionMember,
      $$CollectionMembersTableFilterComposer,
      $$CollectionMembersTableOrderingComposer,
      $$CollectionMembersTableAnnotationComposer,
      $$CollectionMembersTableCreateCompanionBuilder,
      $$CollectionMembersTableUpdateCompanionBuilder,
      (
        CollectionMember,
        BaseReferences<
          _$AppDatabase,
          $CollectionMembersTable,
          CollectionMember
        >,
      ),
      CollectionMember,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StationsTableTableManager get stations =>
      $$StationsTableTableManager(_db, _db.stations);
  $$HistoryItemsTableTableManager get historyItems =>
      $$HistoryItemsTableTableManager(_db, _db.historyItems);
  $$RecordingItemsTableTableManager get recordingItems =>
      $$RecordingItemsTableTableManager(_db, _db.recordingItems);
  $$BrokenReportsTableTableManager get brokenReports =>
      $$BrokenReportsTableTableManager(_db, _db.brokenReports);
  $$StationCollectionsTableTableManager get stationCollections =>
      $$StationCollectionsTableTableManager(_db, _db.stationCollections);
  $$CollectionMembersTableTableManager get collectionMembers =>
      $$CollectionMembersTableTableManager(_db, _db.collectionMembers);
}
