import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/radio_station.dart';
import 'akashvani_darbhanga_resolver.dart';

class AkashvaniApi {
  AkashvaniApi({Dio? dio, AkashvaniDarbhangaResolver? darbhangaResolver})
    : this._(dio ?? _defaultDio(), darbhangaResolver);

  AkashvaniApi._(this._dio, AkashvaniDarbhangaResolver? resolver)
    : _darbhangaResolver = resolver ?? AkashvaniDarbhangaResolver(dio: _dio);

  static const feedUrl =
      'https://raw.githubusercontent.com/codito/akashvani/master/stations.json';
  static const officialLivePageUrl =
      AkashvaniDarbhangaResolver.officialLivePageUrl;
  static const currentDarbhangaStreamUrl =
      AkashvaniDarbhangaResolver.currentWavesFallback;
  static const darbhangaDeliveryStreamUrl =
      AkashvaniDarbhangaResolver.currentDeliveryFallback;
  final Dio _dio;
  final AkashvaniDarbhangaResolver _darbhangaResolver;

  Future<List<RadioStation>> stations() async {
    final response = await _dio.get<Object?>(feedUrl);
    final raw = response.data;
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! List) {
      throw const FormatException('Akashvani feed is not a list');
    }
    final stations = decoded
        .whereType<Map>()
        .map((item) => RadioStation.fromAkashvani(item.cast<String, Object?>()))
        .where((station) => station.canPlay)
        .toList();
    return _withResolvedDarbhangaStreams(stations);
  }

  Future<List<RadioStation>> _withResolvedDarbhangaStreams(
    List<RadioStation> stations,
  ) async {
    // One bounded fetch of the official live page refreshes every Akashvani
    // station at once. This matters because the discovery feed still carries
    // retired BitGravity `pbaudio*` URLs for Bihar (68 Bhagalpur, 69
    // Darbhanga, 70 Patna, 71 Rainbow Patna, 72 VBS Patna, 73 Purnia) that
    // return HTTP 404, while the live page already lists current WAVES URLs.
    // Darbhanga keeps its full HLS-validated resolver; the remaining
    // stations get the official URL prepended without per-station probing
    // (playback failover remains the validator).
    Map<String, String> official = const {};
    try {
      official = await _darbhangaResolver.officialStreamMap();
    } catch (_) {
      official = const {};
    }
    final result = <RadioStation>[];
    for (final station in stations) {
      if (!station.isDarbhanga) {
        result.add(_withOfficialUrl(station, official));
        continue;
      }
      final resolution = await _darbhangaResolver.resolve(station: station);
      result.add(resolution.applyTo(station));
    }
    return result;
  }

  RadioStation _withOfficialUrl(
    RadioStation station,
    Map<String, String> official,
  ) {
    final channel = AkashvaniDarbhangaResolver.channelIdForStation(station);
    final officialUrl = channel == null
        ? null
        : official[channel] ??
              AkashvaniDarbhangaResolver.biharWavesByChannelId[channel];
    if (officialUrl == null || officialUrl.isEmpty) return station;
    if (station.streams.any((stream) => stream.url == officialUrl)) {
      return station;
    }
    return station.copyWith(
      streams: [
        StationStream(url: officialUrl, hls: true),
        ...station.streams,
      ],
    );
  }

  static Dio _defaultDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 12),
      headers: const {'User-Agent': 'Dhwani/1.0 (com.prashant.dhwani)'},
    ),
  );
}
