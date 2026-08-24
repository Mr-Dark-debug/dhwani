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

class StationCollections extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CollectionMembers extends Table {
  TextColumn get collectionId => text()();
  TextColumn get stationId => text()();
  TextColumn get stationPayload => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {collectionId, stationId};
}

class HistorySummary {
  const HistorySummary({
    required this.station,
    required this.lastPlayedAt,
    required this.playCount,
    required this.totalDuration,
  });

  final RadioStation station;
  final DateTime lastPlayedAt;
  final int playCount;
  final Duration totalDuration;
}

class StationCollectionSummary {
  const StationCollectionSummary({
    required this.id,
    required this.name,
    required this.stationCount,
  });

  final String id;
  final String name;
  final int stationCount;
}

@DriftDatabase(
  tables: [
    Stations,
    HistoryItems,
    RecordingItems,
    BrokenReports,
    StationCollections,
    CollectionMembers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'dhwani'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(stationCollections);
        await migrator.createTable(collectionMembers);
      }
    },
  );

  Stream<List<RadioStation>> watchStations() =>
      (select(
        stations,
      )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).watch().map(
        (rows) => rows.map((row) => RadioStation.decode(row.payload)).toList(),
      );

  Future<List<RadioStation>> allStations() async => (await select(
    stations,
  ).get()).map((row) => RadioStation.decode(row.payload)).toList();

  Future<void> clearCatalogueCache() =>
      (delete(stations)..where(
            (row) => row.custom.equals(false) & row.favourite.equals(false),
          ))
          .go();

  Future<int> pruneStaleCatalogue(DateTime cutoff) =>
      (delete(stations)..where(
            (row) =>
                row.custom.equals(false) &
                row.favourite.equals(false) &
                row.updatedAt.isSmallerThanValue(cutoff),
          ))
          .go();

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

  Future<void> reorderFavourites(List<String> stationIds) =>
      transaction(() async {
        for (var index = 0; index < stationIds.length; index++) {
          await (update(stations)
                ..where((row) => row.id.equals(stationIds[index])))
              .write(StationsCompanion(sortOrder: Value(index)));
        }
      });

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

  /// Starts one durable listening session after playback is confirmed.
  ///
  /// The returned row id is updated when the session pauses, stops, switches,
  /// or fails. This prevents navigation taps and failed connection attempts
  /// from inflating listening history.
  Future<int> startHistorySession(RadioStation station) =>
      into(historyItems).insert(
        HistoryItemsCompanion.insert(
          stationId: station.id,
          stationPayload: station.encode(),
          playedAt: DateTime.now(),
        ),
      );

  Future<void> updateHistorySession(int rowId, Duration duration) =>
      (update(historyItems)..where((row) => row.rowId.equals(rowId))).write(
        HistoryItemsCompanion(
          durationSeconds: Value(duration.inSeconds.clamp(0, 1 << 31)),
        ),
      );

  Future<void> importHistory(
    RadioStation station,
    DateTime playedAt, {
    Duration duration = Duration.zero,
  }) => into(historyItems).insert(
    HistoryItemsCompanion.insert(
      stationId: station.id,
      stationPayload: station.encode(),
      playedAt: playedAt,
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

  Stream<List<HistorySummary>> watchHistorySummaries() =>
      (select(historyItems)
            ..orderBy([(row) => OrderingTerm.desc(row.playedAt)])
            ..limit(500))
          .watch()
          .map((rows) {
            final summaries = <String, HistorySummary>{};
            for (final row in rows) {
              final existing = summaries[row.stationId];
              summaries[row.stationId] = HistorySummary(
                station:
                    existing?.station ??
                    RadioStation.decode(row.stationPayload),
                lastPlayedAt: existing?.lastPlayedAt ?? row.playedAt,
                playCount: (existing?.playCount ?? 0) + 1,
                totalDuration:
                    (existing?.totalDuration ?? Duration.zero) +
                    Duration(seconds: row.durationSeconds),
              );
            }
            return summaries.values.toList();
          });

  Future<void> clearHistory() => delete(historyItems).go();

  Future<void> deleteHistoryForStation(String stationId) => (delete(
    historyItems,
  )..where((row) => row.stationId.equals(stationId))).go();

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

  Future<void> clearRecordings() => delete(recordingItems).go();

  Future<void> reportBroken(String stationId, {String? note}) =>
      into(brokenReports).insertOnConflictUpdate(
        BrokenReportsCompanion.insert(
          stationId: stationId,
          reportedAt: DateTime.now(),
          note: Value(note),
        ),
      );

  Future<void> recordStreamResult(
    RadioStation station,
    String streamUrl, {
    required bool success,
    String? failureReason,
    Duration? startupTime,
  }) async {
    final now = DateTime.now();
    final existing = await (select(
      stations,
    )..where((row) => row.id.equals(station.id))).getSingleOrNull();
    final base = existing == null
        ? station
        : RadioStation.decode(existing.payload);
    final incomingByUrl = {
      for (final stream in station.streams) stream.url: stream,
    };
    final allStreams = <StationStream>[
      ...base.streams,
      ...station.streams.where(
        (candidate) =>
            !base.streams.any((persisted) => persisted.url == candidate.url),
      ),
    ];
    final streams = allStreams
        .map(
          (stream) => stream.url == streamUrl
              ? stream.copyWith(
                  lastAttempt: now,
                  lastSuccess: success ? now : stream.lastSuccess,
                  failureCount: success ? 0 : stream.failureCount + 1,
                  lastFailureReason: success ? null : failureReason,
                  lastStartupMs: startupTime?.inMilliseconds,
                )
              : incomingByUrl[stream.url] ?? stream,
        )
        .toList();
    final failures = success ? 0 : base.failureCount + 1;
    final recentlySuccessful =
        base.lastSuccessfulPlayback != null &&
        now.difference(base.lastSuccessfulPlayback!) < const Duration(days: 1);
    final failureHealth = switch (failureReason) {
      'geoBlocked' || 'unauthorized' => StationHealth.unavailableHere,
      'notFound' => StationHealth.directoryBroken,
      _ when recentlySuccessful => StationHealth.recentlyWorking,
      _ => StationHealth.unstable,
    };
    final updated = base.copyWith(
      streams: streams,
      health: success ? StationHealth.online : failureHealth,
      lastChecked: now,
      lastSuccessfulPlayback: success ? now : base.lastSuccessfulPlayback,
      lastResolvedStreamUrl: success ? streamUrl : base.lastResolvedStreamUrl,
      lastFailureReason: success ? null : failureReason,
      lastStartupMs: startupTime?.inMilliseconds,
      failureCount: failures,
    );
    if (existing == null) {
      await upsertStations([updated]);
      return;
    }
    await (update(stations)..where((row) => row.id.equals(station.id))).write(
      StationsCompanion(
        payload: Value(updated.encode()),
        updatedAt: Value(now),
      ),
    );
  }

  Stream<List<StationCollectionSummary>> watchCollections() {
    final query = select(stationCollections)
      ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]);
    return query.watch().asyncMap((rows) async {
      final result = <StationCollectionSummary>[];
      for (final row in rows) {
        final countExpression = collectionMembers.stationId.count();
        final countQuery = selectOnly(collectionMembers)
          ..addColumns([countExpression])
          ..where(collectionMembers.collectionId.equals(row.id));
        final count = await countQuery
            .map((result) => result.read(countExpression) ?? 0)
            .getSingle();
        result.add(
          StationCollectionSummary(
            id: row.id,
            name: row.name,
            stationCount: count,
          ),
        );
      }
      return result;
    });
  }

  Future<void> createCollection(String id, String name) =>
      into(stationCollections).insertOnConflictUpdate(
        StationCollectionsCompanion.insert(
          id: id,
          name: name.trim(),
          sortOrder: Value(DateTime.now().millisecondsSinceEpoch),
          createdAt: DateTime.now(),
        ),
      );

  Future<void> renameCollection(String id, String name) =>
      (update(stationCollections)..where((row) => row.id.equals(id))).write(
        StationCollectionsCompanion(name: Value(name.trim())),
      );

  Future<void> deleteCollection(String id) => transaction(() async {
    await (delete(
      collectionMembers,
    )..where((row) => row.collectionId.equals(id))).go();
    await (delete(stationCollections)..where((row) => row.id.equals(id))).go();
  });

  Future<void> addToCollection(String collectionId, RadioStation station) =>
      into(collectionMembers).insertOnConflictUpdate(
        CollectionMembersCompanion.insert(
          collectionId: collectionId,
          stationId: station.id,
          stationPayload: station.encode(),
          sortOrder: Value(DateTime.now().millisecondsSinceEpoch),
          addedAt: DateTime.now(),
        ),
      );

  Future<void> removeFromCollection(String collectionId, String stationId) =>
      (delete(collectionMembers)..where(
            (row) =>
                row.collectionId.equals(collectionId) &
                row.stationId.equals(stationId),
          ))
          .go();

  Stream<List<RadioStation>> watchCollectionStations(String collectionId) =>
      (select(collectionMembers)
            ..where((row) => row.collectionId.equals(collectionId))
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .watch()
          .map(
            (rows) => rows
                .map((row) => RadioStation.decode(row.stationPayload))
                .toList(),
          );

  Future<String> exportUserData() async {
    final stationRows = await select(stations).get();
    final historyRows = await select(historyItems).get();
    final collectionRows = await select(stationCollections).get();
    final memberRows = await select(collectionMembers).get();
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
              'durationSeconds': row.durationSeconds,
            },
          )
          .toList(),
      'collections': collectionRows
          .map(
            (row) => {
              'id': row.id,
              'name': row.name,
              'stations': memberRows
                  .where((member) => member.collectionId == row.id)
                  .map((member) => jsonDecode(member.stationPayload))
                  .toList(),
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
