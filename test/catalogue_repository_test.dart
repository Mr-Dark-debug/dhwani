import 'package:dhwani/core/persistence/app_database.dart';
import 'package:dhwani/data/datasources/akashvani_api.dart';
import 'package:dhwani/data/datasources/radio_browser_api.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:dhwani/data/repositories/catalogue_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'fresh official Darbhanga stream is retained ahead of fallbacks',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = CatalogueRepository(
        database: database,
        radioBrowser: _EmptyRadioBrowser(),
        akashvani: _CurrentAkashvani(),
      );

      await repository.bootstrap();

      final station = (await database.allStations()).singleWhere(
        (item) => item.isDarbhanga,
      );
      expect(
        station.streams.first.url,
        'https://radio.wavespb.com/live/current/darbhanga.m3u8',
      );
      expect(
        station.streams.map((stream) => stream.url),
        contains(
          'https://air.pc.cdn.bitgravity.com/air/live/pbaudio160/playlist.m3u8',
        ),
      );
    },
  );

  test('Darbhanga fallback does not reorder another country station', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = CatalogueRepository(
      database: database,
      radioBrowser: _SwissRadioBrowser(),
      akashvani: _EmptyAkashvani(),
    );

    await repository.bootstrap();

    final swiss = (await database.allStations()).singleWhere(
      (item) => item.id == 'test:swiss',
    );
    expect(swiss.streams.map((stream) => stream.url).toList(), const [
      'https://example.test/swiss-primary.mp3',
      'https://example.test/swiss-backup.mp3',
    ]);
  });
}

class _CurrentAkashvani extends AkashvaniApi {
  @override
  Future<List<RadioStation>> stations() async => const [
    RadioStation(
      id: 'air:69',
      name: 'Akashvani Darbhanga',
      country: 'India',
      countryCode: 'IN',
      state: 'Bihar',
      city: 'Darbhanga',
      band: RadioBand.am,
      frequency: 1296,
      frequencyUnit: 'kHz',
      streams: [
        StationStream(
          url: 'https://radio.wavespb.com/live/current/darbhanga.m3u8',
          hls: true,
        ),
      ],
      directory: RadioDirectory.akashvani,
    ),
  ];
}

class _EmptyRadioBrowser extends RadioBrowserApi {
  @override
  Future<List<RadioStation>> popular({int limit = 250}) async => const [];
}

class _EmptyAkashvani extends AkashvaniApi {
  @override
  Future<List<RadioStation>> stations() async => const [];
}

class _SwissRadioBrowser extends RadioBrowserApi {
  @override
  Future<List<RadioStation>> popular({int limit = 250}) async => const [
    RadioStation(
      id: 'test:swiss',
      name: 'Swiss Regression Station',
      country: 'Switzerland',
      countryCode: 'CH',
      band: RadioBand.net,
      streams: [
        StationStream(url: 'https://example.test/swiss-primary.mp3'),
        StationStream(url: 'https://example.test/swiss-backup.mp3'),
      ],
      directory: RadioDirectory.radioBrowser,
    ),
  ];
}
