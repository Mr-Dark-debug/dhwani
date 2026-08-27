import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/radio_station.dart';

class AkashvaniApi {
  AkashvaniApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 12),
              headers: const {'User-Agent': 'Dhwani/1.0 (com.prashant.dhwani)'},
            ),
          );

  static const feedUrl =
      'https://raw.githubusercontent.com/codito/akashvani/master/stations.json';
  static const officialLivePageUrl = 'https://akashvani.gov.in/radio/live.php';
  static const currentDarbhangaStreamUrl =
      'https://radio.wavespb.com/live/8e074285599ed45d/8e074285599ed45d.m3u8';
  final Dio _dio;

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
    return _withOfficialDarbhangaStream(stations);
  }

  Future<List<RadioStation>> _withOfficialDarbhangaStream(
    List<RadioStation> stations,
  ) async {
    var officialUrl = currentDarbhangaStreamUrl;
    try {
      final response = await _dio.get<String>(
        officialLivePageUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: const {
            'Accept': 'text/html,application/xhtml+xml',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 Dhwani/1.4',
          },
        ),
      );
      final html = response.data ?? '';
      final nameIndex = html.indexOf("name: 'Akashvani Darbhanga'");
      if (nameIndex >= 0) {
        final proposedEnd = nameIndex + 1000;
        final end = proposedEnd < html.length ? proposedEnd : html.length;
        final block = html.substring(nameIndex, end);
        final streamMatch = RegExp(
          r"^\s*live_url:\s*'([^']+)'",
          multiLine: true,
        ).firstMatch(block);
        final discovered = streamMatch?.group(1)?.trim();
        if (discovered != null && discovered.startsWith('https://')) {
          officialUrl = discovered;
        }
      }
    } catch (_) {}
    return stations.map((station) {
      if (!station.isDarbhanga) return station;
      final streams = <String, StationStream>{
        officialUrl: StationStream(url: officialUrl, hls: true),
        for (final stream in station.streams) stream.url: stream,
      };
      return station.copyWith(streams: streams.values.toList());
    }).toList();
  }
}
