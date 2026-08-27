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
    final result = <RadioStation>[];
    for (final station in stations) {
      if (!station.isDarbhanga) {
        result.add(station);
        continue;
      }
      final resolution = await _darbhangaResolver.resolve(station: station);
      result.add(resolution.applyTo(station));
    }
    return result;
  }

  static Dio _defaultDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 12),
      headers: const {'User-Agent': 'Dhwani/1.0 (com.prashant.dhwani)'},
    ),
  );
}
