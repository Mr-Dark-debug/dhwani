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
  final Map<String, _MirrorHealth> _mirrorHealth = {};

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

  Future<List<RadioStation>> byCountry(
    String countryCode, {
    int limit = 500,
    int maxStations = 10000,
    Future<void> Function(List<RadioStation> page)? onPage,
    CancelToken? cancelToken,
  }) async {
    final pageSize = limit.clamp(50, 500);
    final result = <String, RadioStation>{};
    final started = DateTime.now();
    var offset = 0;
    while (result.length < maxStations &&
        DateTime.now().difference(started) < const Duration(seconds: 45)) {
      if (cancelToken?.isCancelled == true) throw cancelToken!.cancelError!;
      final page = await _stations(
        '/json/stations/bycountrycodeexact/${countryCode.toUpperCase()}',
        query: {
          'hidebroken': 'true',
          'order': 'clickcount',
          'reverse': 'true',
          'limit': '$pageSize',
          'offset': '$offset',
        },
        cancelToken: cancelToken,
      );
      for (final station in page) {
        result[station.id] = station;
      }
      if (page.isNotEmpty) await onPage?.call(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    return result.values.take(maxStations).toList();
  }

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
    CancelToken? cancelToken,
  }) async {
    final data = await _getList(path, query: query, cancelToken: cancelToken);
    return data
        .map(RadioStation.fromRadioBrowser)
        .where((station) => station.id != 'rb:null' && station.canPlay)
        .toList();
  }

  Future<List<Map<String, Object?>>> _getList(
    String path, {
    Map<String, Object?>? query,
    CancelToken? cancelToken,
  }) async {
    final response = await _get(path, query: query, cancelToken: cancelToken);
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
    CancelToken? cancelToken,
  }) async {
    final servers = await discoverServers();
    Object? lastError;
    final now = DateTime.now();
    final ordered = [...servers]
      ..sort((a, b) {
        final aHealth = _mirrorHealth[a] ?? const _MirrorHealth();
        final bHealth = _mirrorHealth[b] ?? const _MirrorHealth();
        final aBlocked = aHealth.retryAfter?.isAfter(now) == true;
        final bBlocked = bHealth.retryAfter?.isAfter(now) == true;
        if (aBlocked != bBlocked) return aBlocked ? 1 : -1;
        final failures = aHealth.failures.compareTo(bHealth.failures);
        if (failures != 0) return failures;
        return aHealth.averageLatencyMs.compareTo(bHealth.averageLatencyMs);
      });
    for (final server in ordered.take(4)) {
      if (cancelToken?.isCancelled == true) throw cancelToken!.cancelError!;
      final health = _mirrorHealth[server] ?? const _MirrorHealth();
      if (health.retryAfter?.isAfter(DateTime.now()) == true &&
          ordered.any(
            (candidate) =>
                (_mirrorHealth[candidate]?.retryAfter?.isAfter(
                      DateTime.now(),
                    ) ??
                    false) ==
                false,
          )) {
        continue;
      }
      final stopwatch = Stopwatch()..start();
      try {
        final response = await _dio.get<Object?>(
          '$server$path',
          queryParameters: query,
          cancelToken: cancelToken,
        );
        stopwatch.stop();
        _mirrorHealth[server] = health.succeeded(stopwatch.elapsedMilliseconds);
        return response;
      } catch (error, stack) {
        stopwatch.stop();
        if (error is DioException && CancelToken.isCancel(error)) rethrow;
        lastError = error;
        _mirrorHealth[server] = health.failed();
        DhwaniLog.api(
          '${Uri.parse(server).host} failed for $path; trying next mirror',
          error,
          stack,
        );
      }
    }
    DhwaniLog.api('All Radio Browser mirrors failed for $path', lastError);
    throw const RadioDirectoryException(
      'The station directory is temporarily unavailable. Cached stations remain usable.',
    );
  }

  static int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

class RadioDirectoryException implements Exception {
  const RadioDirectoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class _MirrorHealth {
  const _MirrorHealth({
    this.failures = 0,
    this.averageLatencyMs = 1000,
    this.retryAfter,
  });

  final int failures;
  final int averageLatencyMs;
  final DateTime? retryAfter;

  _MirrorHealth succeeded(int latencyMs) => _MirrorHealth(
    averageLatencyMs: ((averageLatencyMs * 2) + latencyMs) ~/ 3,
  );

  _MirrorHealth failed() {
    final nextFailures = failures + 1;
    final seconds = min(60, 1 << min(nextFailures, 5));
    return _MirrorHealth(
      failures: nextFailures,
      averageLatencyMs: averageLatencyMs,
      retryAfter: DateTime.now().add(Duration(seconds: seconds)),
    );
  }
}
