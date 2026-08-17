import '../../core/logging/dhwani_log.dart';
import '../../core/persistence/app_database.dart';
import '../datasources/akashvani_api.dart';
import '../datasources/radio_browser_api.dart';
import '../models/radio_station.dart';

class CatalogueRepository {
  CatalogueRepository({
    required this.database,
    required this.radioBrowser,
    required this.akashvani,
  });

  final AppDatabase database;
  final RadioBrowserApi radioBrowser;
  final AkashvaniApi akashvani;

  Stream<List<RadioStation>> watchStations() => database.watchStations();
  Stream<List<RadioStation>> watchFavourites() => database.watchFavourites();
  Stream<List<RadioStation>> watchHistory() => database.watchHistory();

  Future<void> bootstrap() async {
    final cached = await database.allStations();
    if (cached.isEmpty) {
      await database.upsertStations(_offlineSeeds);
    } else {
      final merged = _merge([..._offlineSeeds, ...cached]);
      await database.upsertStations(merged);
    }
    await refresh();
  }

  Future<void> refresh() async {
    final cached = await database.allStations();
    final results = await Future.wait<List<RadioStation>>([
      akashvani.stations().catchError((Object error, StackTrace stack) {
        DhwaniLog.api(
          'Akashvani refresh failed; cache remains available',
          error,
          stack,
        );
        return <RadioStation>[];
      }),
      radioBrowser.popular().catchError((Object error, StackTrace stack) {
        DhwaniLog.api(
          'Radio Browser refresh failed; cache remains available',
          error,
          stack,
        );
        return <RadioStation>[];
      }),
    ]);
    final merged = _merge([
      ..._offlineSeeds,
      ...cached,
      ...results.expand((stations) => stations),
    ]);
    if (merged.isNotEmpty) await database.upsertStations(merged);
  }

  Future<List<CountrySummary>> countries() async {
    try {
      final result = await radioBrowser.countries();
      result.sort((a, b) {
        if (a.code == 'IN') return -1;
        if (b.code == 'IN') return 1;
        return a.name.compareTo(b.name);
      });
      return result;
    } catch (_) {
      final cached = await database.allStations();
      final grouped = <String, CountrySummary>{};
      for (final station in cached) {
        final previous = grouped[station.countryCode];
        grouped[station.countryCode] = CountrySummary(
          name: station.country,
          code: station.countryCode,
          stationCount: (previous?.stationCount ?? 0) + 1,
        );
      }
      return grouped.values.toList()
        ..sort((a, b) => a.code == 'IN' ? -1 : a.name.compareTo(b.name));
    }
  }

  Future<void> loadCountry(String code) async {
    final stations = await radioBrowser.byCountry(code);
    if (stations.isNotEmpty) await database.upsertStations(stations);
  }

  Future<List<RadioStation>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    final local = await searchLocal(query);
    if (normalized.length < 3) return local;
    return searchRemote(query, localResults: local);
  }

  Future<List<RadioStation>> searchLocal(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    return (await database.allStations())
        .where((station) => station.searchableText.contains(normalized))
        .toList();
  }

  Future<List<RadioStation>> searchRemote(
    String query, {
    List<RadioStation>? localResults,
  }) async {
    final local = localResults ?? await searchLocal(query);
    try {
      final remote = await radioBrowser.search(query);
      await database.upsertStations(remote);
      return _merge([...local, ...remote]);
    } catch (_) {
      return local;
    }
  }

  Future<void> favourite(RadioStation station, bool value) =>
      database.setFavourite(station, value);
  Future<void> addHistory(RadioStation station) => database.addHistory(station);

  static List<RadioStation> _merge(Iterable<RadioStation> input) {
    final result = <String, RadioStation>{};
    for (final station in input) {
      final semanticKey = station.isDarbhanga
          ? 'akashvani-darbhanga'
          : station.id;
      final filteredStationStreams = station.streams
          .where((s) => !s.url.contains('wavespb.com'))
          .toList();
      final previous = result[semanticKey];
      if (previous == null) {
        result[semanticKey] = station.copyWith(
          streams: filteredStationStreams.isNotEmpty
              ? filteredStationStreams
              : station.streams,
        );
      } else {
        final previousFiltered = previous.streams
            .where((s) => !s.url.contains('wavespb.com'))
            .toList();
        final urls = <String, StationStream>{
          for (final stream in [
            ...filteredStationStreams,
            ...previousFiltered,
          ])
            stream.url: stream,
        };
        result[semanticKey] = previous.copyWith(
          streams: urls.values.isNotEmpty
              ? urls.values.toList()
              : previous.streams,
        );
      }
    }
    return result.values.toList();
  }

  static const _offlineSeeds = [
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
          url:
              'https://airhlspush.pc.cdn.bitgravity.com/httppush/hlspbaudio160/hlspbaudio160_Auto.m3u8',
          hls: true,
        ),
        StationStream(
          url:
              'https://air.pc.cdn.bitgravity.com/air/live/pbaudio160/playlist.m3u8',
          hls: true,
        ),
      ],
      languages: ['Maithili', 'Hindi'],
      tags: ['Akashvani', 'public radio'],
      directory: RadioDirectory.offlineSeed,
      sourceId: '69',
      verified: true,
    ),
    RadioStation(
      id: 'air:70',
      name: 'Akashvani Patna',
      country: 'India',
      countryCode: 'IN',
      state: 'Bihar',
      city: 'Patna',
      band: RadioBand.net,
      streams: [
        StationStream(
          url:
              'https://air.pc.cdn.bitgravity.com/air/live/pbaudio087/playlist.m3u8',
          hls: true,
        ),
      ],
      languages: ['Maithili', 'Hindi'],
      tags: ['Akashvani', 'public radio'],
      directory: RadioDirectory.offlineSeed,
      sourceId: '70',
    ),
    RadioStation(
      id: 'seed:radio-swiss-jazz',
      name: 'Radio Swiss Jazz',
      country: 'Switzerland',
      countryCode: 'CH',
      band: RadioBand.net,
      streams: [
        StationStream(
          url: 'https://stream.srg-ssr.ch/m/rsj/mp3_128',
          codec: 'MP3',
          bitrate: 128,
        ),
      ],
      languages: ['Music'],
      tags: ['jazz', 'public radio', 'high quality'],
      directory: RadioDirectory.offlineSeed,
      verified: true,
    ),
  ];
}
