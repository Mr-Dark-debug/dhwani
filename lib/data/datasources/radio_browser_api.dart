import 'dart:math';

import 'package:dio/dio.dart';

import '../../core/logging/dhwani_log.dart';
import '../models/radio_station.dart';

class CountrySummary {
  const CountrySummary({
    required this.name,
    required this.code,
    required this.stationCount,
  });
  final String name;
  final String code;
  final int stationCount;
}

class RadioBrowserApi {
  RadioBrowserApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 6),
              headers: const {'User-Agent': 'Dhwani/1.0 (com.prashant.dhwani)'},
            ),
          );

  final Dio _dio;
  final Random _random = Random();
  List<String> _servers = const [];
  DateTime? _serversAt;

  Future<List<String>> discoverServers({bool force = false}) async {
    if (!force &&
        _servers.isNotEmpty &&
        DateTime.now().difference(_serversAt!) < const Duration(hours: 12)) {
      return _servers;
    }
    try {
      final response = await _dio.get<List<Object?>>(
        'https://all.api.radio-browser.info/json/servers',
      );
      final names =
          (response.data ?? const [])
              .whereType<Map>()
              .map((item) => item['name']?.toString())
              .whereType<String>()
              .where((name) => name.endsWith('.api.radio-browser.info'))
              .map((name) => 'https://$name')
              .toSet()
              .toList()
            ..shuffle(_random);
      if (names.isNotEmpty) {
        _servers = names;
        _serversAt = DateTime.now();
        return names;
      }
    } catch (error, stack) {
      DhwaniLog.api('Radio Browser mirror discovery failed', error, stack);
    }
    _servers = const [
      'https://de1.api.radio-browser.info',
      'https://nl1.api.radio-browser.info',
    ];
    _serversAt = DateTime.now();
    return _servers;
  }

  Future<List<CountrySummary>> countries() async {
    final data = await _getList(
      '/json/countries',
      query: {'hidebroken': 'true', 'order': 'stationcount', 'reverse': 'true'},
    );
    return data
        .map(
          (item) => CountrySummary(
            name: item['name']?.toString() ?? 'Unknown',
            code: (item['iso_3166_1']?.toString() ?? '').toUpperCase(),
            stationCount: _int(item['stationcount']),
          ),
        )
        .where((item) => item.code.length == 2 && item.stationCount > 0)
        .toList();
  }

  Future<List<RadioStation>> popular({int limit = 250}) =>
      _stations('/json/stations/topclick/$limit');

  Future<List<RadioStation>> byCountry(String countryCode, {int limit = 500}) =>
      _stations(
        '/json/stations/bycountrycodeexact/${countryCode.toUpperCase()}',
        query: {
          'hidebroken': 'true',
          'order': 'clickcount',
          'reverse': 'true',
          'limit': '$limit',
        },
      );

  Future<List<RadioStation>> search(String query, {int limit = 100}) =>
      _stations(
        '/json/stations/search',
        query: {
          'name': query,
          'hidebroken': 'true',
          'order': 'clickcount',
          'reverse': 'true',
          'limit': '$limit',
        },
      );

  Future<void> registerClick(String uuid) async {
    if (uuid.isEmpty) return;
    try {
      await _get('/json/url/$uuid');
    } catch (error, stack) {
      DhwaniLog.api('Station click registration failed', error, stack);
    }
  }

  Future<List<RadioStation>> _stations(
    String path, {
    Map<String, Object?>? query,
  }) async {
    final data = await _getList(path, query: query);
    return data
        .map(RadioStation.fromRadioBrowser)
        .where((station) => station.id != 'rb:null' && station.canPlay)
        .toList();
  }

  Future<List<Map<String, Object?>>> _getList(
    String path, {
    Map<String, Object?>? query,
  }) async {
    final response = await _get(path, query: query);
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Radio Browser returned a non-list response');
    }
    return data
        .whereType<Map>()
        .map((item) => item.cast<String, Object?>())
        .toList();
  }

  Future<Response<Object?>> _get(
    String path, {
    Map<String, Object?>? query,
  }) async {
    final servers = await discoverServers();
    Object? lastError;
    for (final server in servers.take(4)) {
      try {
        return await _dio.get<Object?>('$server$path', queryParameters: query);
      } catch (error, stack) {
        lastError = error;
        DhwaniLog.api(
          '$server failed for $path; trying next mirror',
          error,
          stack,
        );
      }
    }
    throw StateError('All Radio Browser mirrors failed: $lastError');
  }

  static int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}
