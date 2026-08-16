import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../data/models/radio_station.dart';
import '../../data/models/recording_entry.dart';

part 'app_database.g.dart';

class Stations extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  BoolColumn get favourite => boolean().withDefault(const Constant(false))();
  BoolColumn get custom => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class HistoryItems extends Table {
  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get stationId => text()();
  TextColumn get stationPayload => text()();
  DateTimeColumn get playedAt => dateTime()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
}

class RecordingItems extends Table {
  TextColumn get id => text()();
  TextColumn get stationPayload => text()();
  TextColumn get path => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get durationSeconds => integer()();
  IntColumn get sizeBytes => integer()();
  TextColumn get format => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BrokenReports extends Table {
  TextColumn get stationId => text()();
  DateTimeColumn get reportedAt => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {stationId};
}

@DriftDatabase(tables: [Stations, HistoryItems, RecordingItems, BrokenReports])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'dhwani'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Stream<List<RadioStation>> watchStations() =>
      (select(
        stations,
      )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).watch().map(
        (rows) => rows.map((row) => RadioStation.decode(row.payload)).toList(),
      );

  Future<List<RadioStation>> allStations() async => (await select(
    stations,
  ).get()).map((row) => RadioStation.decode(row.payload)).toList();

  Future<void> upsertStations(Iterable<RadioStation> values) async {
    final now = DateTime.now();
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        stations,
        values
            .map(
              (station) => StationsCompanion.insert(
                id: station.id,
                payload: station.encode(),
                custom: Value(station.userAdded),
                updatedAt: now,
              ),
            )
            .toList(),
      );
    });
  }

  Future<void> saveCustomStation(RadioStation station) =>
      into(stations).insertOnConflictUpdate(
        StationsCompanion.insert(
          id: station.id,
          payload: station.copyWith(userAdded: true).encode(),
          custom: const Value(true),
          updatedAt: DateTime.now(),
        ),
      );

  Future<void> deleteCustomStation(String id) => (delete(
    stations,
  )..where((row) => row.id.equals(id) & row.custom.equals(true))).go();

  Stream<List<RadioStation>> watchFavourites() =>
      (select(stations)
            ..where((row) => row.favourite.equals(true))
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .watch()
          .map(
            (rows) =>
                rows.map((row) => RadioStation.decode(row.payload)).toList(),
          );

  Stream<List<RadioStation>> watchCustomStations() =>
      (select(stations)
            ..where((row) => row.custom.equals(true))
            ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
          .watch()
          .map(
            (rows) =>
                rows.map((row) => RadioStation.decode(row.payload)).toList(),
          );

  Future<bool> isFavourite(String id) async =>
      (await (select(
        stations,
      )..where((row) => row.id.equals(id))).getSingleOrNull())?.favourite ??
      false;

  Future<void> setFavourite(RadioStation station, bool value) async {
    final existing = await (select(
      stations,
    )..where((row) => row.id.equals(station.id))).getSingleOrNull();
    final custom = existing?.custom ?? station.userAdded;
    final persisted = station.copyWith(userAdded: custom);
    if (existing != null) {
      await (update(stations)..where((row) => row.id.equals(station.id))).write(
        StationsCompanion(
          payload: Value(persisted.encode()),
          favourite: Value(value),
          custom: Value(custom),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
    }
    await into(stations).insert(
      StationsCompanion.insert(
        id: station.id,
        payload: persisted.encode(),
        favourite: Value(value),
        custom: Value(custom),
        sortOrder: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> addHistory(
    RadioStation station, {
    Duration duration = Duration.zero,
  }) => into(historyItems).insert(
    HistoryItemsCompanion.insert(
      stationId: station.id,
      stationPayload: station.encode(),
      playedAt: DateTime.now(),
      durationSeconds: Value(duration.inSeconds),
    ),
  );

  Stream<List<RadioStation>> watchHistory() =>
      (select(historyItems)
            ..orderBy([(row) => OrderingTerm.desc(row.playedAt)])
            ..limit(100))
          .watch()
          .map((rows) {
            final seen = <String>{};
            return rows
                .where((row) => seen.add(row.stationId))
                .map((row) => RadioStation.decode(row.stationPayload))
                .toList();
          });

  Future<void> clearHistory() => delete(historyItems).go();

  Future<void> addRecording(RecordingEntry entry) =>
      into(recordingItems).insertOnConflictUpdate(
        RecordingItemsCompanion.insert(
          id: entry.id,
          stationPayload: entry.station.encode(),
          path: entry.path,
          name: entry.name,
          createdAt: entry.createdAt,
          durationSeconds: entry.duration.inSeconds,
          sizeBytes: entry.sizeBytes,
          format: entry.format,
        ),
      );

  Stream<List<RecordingEntry>> watchRecordings() =>
      (select(recordingItems)
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
          .watch()
          .map((rows) => rows.map(_mapRecording).toList());

  Future<List<RecordingEntry>> allRecordings() async =>
      (await select(recordingItems).get()).map(_mapRecording).toList();

  Future<void> renameRecording(String id, String name) =>
      (update(recordingItems)..where((row) => row.id.equals(id))).write(
        RecordingItemsCompanion(name: Value(name.trim())),
      );

  Future<void> deleteRecording(String id) =>
      (delete(recordingItems)..where((row) => row.id.equals(id))).go();

  Future<void> reportBroken(String stationId, {String? note}) =>
      into(brokenReports).insertOnConflictUpdate(
        BrokenReportsCompanion.insert(
          stationId: stationId,
          reportedAt: DateTime.now(),
          note: Value(note),
        ),
      );

  Future<String> exportUserData() async {
    final stationRows = await select(stations).get();
    final historyRows = await select(historyItems).get();
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'dhwani-backup',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'stations': stationRows
          .where((row) => row.favourite || row.custom)
          .map(
            (row) => {
              'payload': jsonDecode(row.payload),
              'favourite': row.favourite,
              'custom': row.custom,
            },
          )
          .toList(),
      'history': historyRows
          .take(200)
          .map(
            (row) => {
              'station': jsonDecode(row.stationPayload),
              'playedAt': row.playedAt.toIso8601String(),
            },
          )
          .toList(),
    });
  }

  RecordingEntry _mapRecording(RecordingItem row) => RecordingEntry(
    id: row.id,
    station: RadioStation.decode(row.stationPayload),
    path: row.path,
    name: row.name,
    createdAt: row.createdAt,
    duration: Duration(seconds: row.durationSeconds),
    sizeBytes: row.sizeBytes,
    format: row.format,
  );
}
