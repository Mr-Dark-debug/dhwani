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

  test('backup format is versioned and contains only user data', () async {
    await database.setFavourite(station, true);
    final backup = jsonDecode(await database.exportUserData()) as Map;

    expect(backup['format'], 'dhwani-backup');
    expect(backup['version'], 1);
    expect(backup['stations'], hasLength(1));
  });
}
