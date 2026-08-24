import 'dart:convert';

import 'package:dhwani/core/persistence/app_database.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  const station = RadioStation(
    id: 'favorite',
    name: 'Akashvani Darbhanga',
    country: 'India',
    countryCode: 'IN',
    state: 'Bihar',
    city: 'Darbhanga',
    band: RadioBand.am,
    frequency: 1296,
    frequencyUnit: 'kHz',
    streams: [StationStream(url: 'https://example.test/live.m3u8')],
    languages: ['Maithili', 'Hindi'],
    directory: RadioDirectory.offlineSeed,
  );

  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('favourite and custom station survive structured storage', () async {
    await database.saveCustomStation(station);
    await database.setFavourite(station, true);

    expect(await database.isFavourite(station.id), isTrue);
    final stored = await database.allStations();
    expect(stored.single.name, station.name);
    expect(stored.single.userAdded, isTrue);
  });

  test('history de-duplicates stations by most recent occurrence', () async {
    await database.addHistory(station);
    await database.addHistory(station, duration: const Duration(seconds: 30));

    final history = await database.watchHistory().first;
    expect(history, hasLength(1));
    expect(history.single.id, station.id);
  });

  test('history summaries retain play count and listening duration', () async {
    await database.addHistory(station, duration: const Duration(seconds: 30));
    await database.addHistory(station, duration: const Duration(seconds: 45));

    final summary = (await database.watchHistorySummaries().first).single;
    expect(summary.playCount, 2);
    expect(summary.totalDuration, const Duration(seconds: 75));

    await database.deleteHistoryForStation(station.id);
    expect(await database.watchHistorySummaries().first, isEmpty);
  });

  test('one confirmed playback session updates one history row', () async {
    final sessionId = await database.startHistorySession(station);
    await database.updateHistorySession(sessionId, const Duration(seconds: 12));

    final summary = (await database.watchHistorySummaries().first).single;
    expect(summary.playCount, 1);
    expect(summary.totalDuration, const Duration(seconds: 12));
  });

  test('favourites can be reordered without losing flags', () async {
    final second = station.copyWith(name: 'Patna');
    final secondStation = RadioStation.fromJson({
      ...second.toJson(),
      'id': 'second',
    });
    await database.setFavourite(station, true);
    await database.setFavourite(secondStation, true);
    await database.reorderFavourites([secondStation.id, station.id]);

    final favourites = await database.watchFavourites().first;
    expect(favourites.map((item) => item.id), [secondStation.id, station.id]);
  });

  test('collections persist members and are included in backup', () async {
    await database.createCollection('home', 'Home');
    await database.addToCollection('home', station);

    final collections = await database.watchCollections().first;
    expect(collections.single.name, 'Home');
    expect(collections.single.stationCount, 1);
    expect(
      (await database.watchCollectionStations('home').first).single.id,
      station.id,
    );

    final backup = jsonDecode(await database.exportUserData()) as Map;
    expect(backup['collections'], hasLength(1));
  });

  test('stream outcomes update durable health and ranking metadata', () async {
    await database.upsertStations([station]);
    await database.recordStreamResult(
      station,
      station.streams.single.url,
      success: true,
    );

    final updated = (await database.allStations()).single;
    expect(updated.health, StationHealth.online);
    expect(updated.lastSuccessfulPlayback, isNotNull);
    expect(updated.streams.single.lastSuccess, isNotNull);
    expect(updated.lastResolvedStreamUrl, station.streams.single.url);
    expect(updated.lastFailureReason, isNull);
  });

  test('regional failure is not persisted as globally offline', () async {
    await database.upsertStations([station]);
    await database.recordStreamResult(
      station,
      station.streams.single.url,
      success: false,
      failureReason: 'geoBlocked',
    );

    final updated = (await database.allStations()).single;
    expect(updated.health, StationHealth.unavailableHere);
    expect(updated.health, isNot(StationHealth.offline));
    expect(updated.lastFailureReason, 'geoBlocked');
  });

  test('backup format is versioned and contains only user data', () async {
    await database.setFavourite(station, true);
    final backup = jsonDecode(await database.exportUserData()) as Map;

    expect(backup['format'], 'dhwani-backup');
    expect(backup['version'], 1);
    expect(backup['stations'], hasLength(1));
  });
}
