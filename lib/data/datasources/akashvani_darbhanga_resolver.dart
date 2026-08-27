import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/dhwani_log.dart';
import '../models/radio_station.dart';

enum DarbhangaCandidateSource {
  officialPage,
  lastKnownGood,
  redirectDelivery,
  stationFeed,
  emergencyFallback,
}

enum DarbhangaAvailability {
  active,
  offAir,
  networkUnavailable,
  discoveryUnavailable,
}

class DarbhangaCandidate {
  const DarbhangaCandidate({required this.stream, required this.source});

  final StationStream stream;
  final DarbhangaCandidateSource source;
}

class DarbhangaResolution {
  const DarbhangaResolution({
    required this.candidates,
    required this.availability,
    this.diagnostic,
  });

  final List<DarbhangaCandidate> candidates;
  final DarbhangaAvailability availability;
  final String? diagnostic;

  RadioStation applyTo(RadioStation station) => station.copyWith(
    streams: candidates.map((candidate) => candidate.stream).toList(),
  );
}

class AkashvaniDarbhangaResolver {
  AkashvaniDarbhangaResolver({
    Dio? dio,
    SharedPreferences? preferences,
    DateTime Function()? now,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 4),
               receiveTimeout: const Duration(seconds: 4),
               sendTimeout: const Duration(seconds: 4),
             ),
           ),
       _preferences = preferences,
       _now = now ?? DateTime.now;

  static const officialLivePageUrl = 'https://akashvani.gov.in/radio/live.php';
  static const channelId = '69';
  static const epgId = '333';
  static const currentWavesFallback =
      'https://radio.wavespb.com/live/8e074285599ed45d/8e074285599ed45d.m3u8';
  static const currentDeliveryFallback =
      'https://d3hrxqn1tritdh.cloudfront.net/8e074285599ed45d/8e074285599ed45d.m3u8';
  static const legacyBitgravityFallback =
      'https://air.pc.cdn.bitgravity.com/air/live/pbaudio160/playlist.m3u8';

  static const discoveryReuse = Duration(minutes: 15);
  static const lastKnownGoodMaxAge = Duration(days: 7);
  static const maxConsecutiveFailures = 3;
  static const _cacheKey = 'darbhangaLastKnownGoodV1';
  static const _maxManifestBytes = 64 * 1024;
  static const _maxRedirects = 5;

  final Dio _dio;
  final SharedPreferences? _preferences;
  final DateTime Function() _now;
  DarbhangaResolution? _recentResolution;
  DateTime? _recentResolutionAt;
  final Map<String, DarbhangaCandidateSource> _knownSources = {};

  Future<DarbhangaResolution> resolve({
    required RadioStation station,
    bool forceRefresh = false,
  }) async {
    if (!station.isDarbhanga) {
      return DarbhangaResolution(
        candidates: station.streams
            .map(
              (stream) => DarbhangaCandidate(
                stream: stream,
                source: DarbhangaCandidateSource.stationFeed,
              ),
            )
            .toList(),
        availability: DarbhangaAvailability.discoveryUnavailable,
        diagnostic: 'Resolver bypassed for non-Darbhanga station.',
      );
    }

    final now = _now();
    if (!forceRefresh &&
        _recentResolution != null &&
        _recentResolutionAt != null &&
        now.difference(_recentResolutionAt!) < discoveryReuse) {
      return _mergeWithStation(_recentResolution!, station);
    }

    final official = <DarbhangaCandidate>[];
    final redirectDelivery = <DarbhangaCandidate>[];
    var availability = DarbhangaAvailability.discoveryUnavailable;
    String? diagnostic;
    try {
      final response = await _dio.get<String>(
        officialLivePageUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: const {
            'Accept': 'text/html,application/xhtml+xml',
            'User-Agent': 'Dhwani/1.4 (Android; com.prashant.dhwani)',
          },
        ),
      );
      final officialUrl = parseOfficialStreamUrl(response.data ?? '');
      official.add(
        DarbhangaCandidate(
          stream: StationStream(url: officialUrl, hls: true),
          source: DarbhangaCandidateSource.officialPage,
        ),
      );
      final probe = await _probeHls(officialUrl);
      diagnostic = probe.diagnostic;
      if (probe.validHls) {
        availability = DarbhangaAvailability.active;
      } else if (probe.statusCode == 404 || probe.statusCode == 410) {
        availability = DarbhangaAvailability.offAir;
      } else if (probe.networkFailure) {
        availability = DarbhangaAvailability.networkUnavailable;
      }
      for (final target in probe.redirectTargets) {
        if (target != officialUrl) {
          redirectDelivery.add(
            DarbhangaCandidate(
              stream: StationStream(url: target, hls: true),
              source: DarbhangaCandidateSource.redirectDelivery,
            ),
          );
        }
      }
    } catch (error, stack) {
      diagnostic = _safeDiagnostic(error);
      availability = _isNetworkFailure(error)
          ? DarbhangaAvailability.networkUnavailable
          : DarbhangaAvailability.discoveryUnavailable;
      DhwaniLog.api('Darbhanga official discovery failed safely', error, stack);
    }

    final cached = _readLastKnownGood(now);
    final ordered = <DarbhangaCandidate>[
      ...official,
      ?cached,
      ...redirectDelivery,
      ...station.streams.map(
        (stream) => DarbhangaCandidate(
          stream: stream,
          source: DarbhangaCandidateSource.stationFeed,
        ),
      ),
      for (final url in const [
        currentWavesFallback,
        currentDeliveryFallback,
        legacyBitgravityFallback,
      ])
        DarbhangaCandidate(
          stream: StationStream(url: url, hls: true),
          source: DarbhangaCandidateSource.emergencyFallback,
        ),
    ];
    final resolution = DarbhangaResolution(
      candidates: _deduplicate(ordered),
      availability: availability,
      diagnostic: diagnostic,
    );
    _recentResolution = resolution;
    _recentResolutionAt = now;
    for (final candidate in resolution.candidates) {
      _knownSources[candidate.stream.url] = candidate.source;
    }
    return resolution;
  }

  Future<void> recordPlaybackResult(
    String url, {
    required bool success,
    String? failureReason,
  }) async {
    final preferences = _preferences;
    if (preferences == null) return;
    final now = _now();
    final current = _readCacheMap();
    if (success) {
      await preferences.setString(
        _cacheKey,
        jsonEncode({
          'url': url,
          'discoveredAt': current != null && current['url'] == url
              ? current['discoveredAt'] ?? now.toIso8601String()
              : now.toIso8601String(),
          'lastSuccessfulPlayback': now.toIso8601String(),
          'source':
              (_knownSources[url] ?? DarbhangaCandidateSource.stationFeed).name,
          'consecutiveFailureCount': 0,
        }),
      );
      return;
    }
    if (current?['url'] != url) return;
    final failures =
        ((current?['consecutiveFailureCount'] as num?)?.toInt() ?? 0) + 1;
    if (failures >= maxConsecutiveFailures) {
      await preferences.remove(_cacheKey);
      _recentResolution = null;
      _recentResolutionAt = null;
      return;
    }
    await preferences.setString(
      _cacheKey,
      jsonEncode({
        ...?current,
        'consecutiveFailureCount': failures,
        'lastFailureReason': failureReason,
      }),
    );
  }

  static String parseOfficialStreamUrl(String html) {
    final body = _extractChannelObject(html, channelId);
    final name = _extractJsString(body, 'name');
    if (name != 'Akashvani Darbhanga') {
      throw const FormatException('Official channel 69 identity changed.');
    }
    final liveUrl = _extractJsString(body, 'live_url').trim();
    final uri = Uri.tryParse(liveUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Darbhanga live_url is not trusted HTTPS.');
    }
    return uri.toString();
  }

  static String _extractChannelObject(String source, String id) {
    final key = RegExp(
      "['\"]${RegExp.escape(id)}['\"]\\s*:",
    ).firstMatch(source);
    if (key == null) {
      throw const FormatException('Official channel 69 missing.');
    }
    final open = source.indexOf('{', key.end);
    if (open < 0) {
      throw const FormatException('Official channel 69 malformed.');
    }
    var depth = 0;
    String? quote;
    var escaped = false;
    for (var index = open; index < source.length; index++) {
      final character = source[index];
      if (quote != null) {
        if (escaped) {
          escaped = false;
        } else if (character == r'\') {
          escaped = true;
        } else if (character == quote) {
          quote = null;
        }
        continue;
      }
      if (character == "'" || character == '"') {
        quote = character;
      } else if (character == '{') {
        depth++;
      } else if (character == '}') {
        depth--;
        if (depth == 0) return source.substring(open + 1, index);
      }
    }
    throw const FormatException('Official channel 69 object is incomplete.');
  }

  static String _extractJsString(String objectBody, String property) {
    final match = RegExp(
      "(?:^|[,\\n])\\s*${RegExp.escape(property)}\\s*:\\s*(['\"])(.*?)\\1",
      multiLine: true,
      dotAll: true,
    ).firstMatch(objectBody);
    if (match == null) {
      throw FormatException('Official channel 69 is missing $property.');
    }
    return match
        .group(2)!
        .replaceAll(r'\/', '/')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\"', '"');
  }

  Future<_HlsProbe> _probeHls(String initialUrl) async {
    var current = Uri.parse(initialUrl);
    final redirects = <String>[];
    for (var count = 0; count <= _maxRedirects; count++) {
      try {
        final response = await _dio.get<ResponseBody>(
          current.toString(),
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: false,
            validateStatus: (_) => true,
            headers: const {
              'Accept':
                  'application/vnd.apple.mpegurl,application/x-mpegURL,*/*',
              'Referer': officialLivePageUrl,
              'User-Agent': 'Dhwani/1.4 (Android; com.prashant.dhwani)',
              'Range': 'bytes=0-65535',
            },
          ),
        );
        final status = response.statusCode ?? 0;
        if (status >= 300 && status < 400) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location == null || count == _maxRedirects) {
            return _HlsProbe(
              statusCode: status,
              redirectTargets: redirects,
              diagnostic: 'Darbhanga redirect chain is invalid or too long.',
            );
          }
          final next = current.resolve(location);
          if (next.scheme != 'https' || next.host.isEmpty) {
            return _HlsProbe(
              statusCode: status,
              redirectTargets: redirects,
              diagnostic: 'Darbhanga redirect target is not trusted HTTPS.',
            );
          }
          redirects.add(next.toString());
          current = next;
          continue;
        }
        if ((status != 200 && status != 206) || response.data == null) {
          return _HlsProbe(
            statusCode: status,
            redirectTargets: redirects,
            diagnostic: 'Darbhanga manifest returned HTTP $status.',
          );
        }
        final body = await _readBounded(response.data!);
        final valid = _resemblesHls(body);
        return _HlsProbe(
          validHls: valid,
          statusCode: status,
          redirectTargets: redirects,
          diagnostic: valid
              ? 'Validated Darbhanga HLS manifest.'
              : 'Darbhanga response was not an HLS manifest.',
        );
      } catch (error) {
        return _HlsProbe(
          networkFailure: _isNetworkFailure(error),
          redirectTargets: redirects,
          diagnostic: _safeDiagnostic(error),
        );
      }
    }
    return _HlsProbe(
      redirectTargets: redirects,
      diagnostic: 'Darbhanga redirect limit reached.',
    );
  }

  static Future<String> _readBounded(ResponseBody body) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in body.stream) {
      final remaining = _maxManifestBytes - bytes.length;
      if (remaining <= 0) break;
      bytes.add(
        chunk.length <= remaining
            ? chunk
            : Uint8List.sublistView(chunk, 0, remaining),
      );
      if (bytes.length >= _maxManifestBytes) break;
    }
    return utf8.decode(bytes.takeBytes(), allowMalformed: true);
  }

  static bool _resemblesHls(String body) {
    final lines = const LineSplitter()
        .convert(body)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty || lines.first != '#EXTM3U') return false;
    final hasPlaylistEntry = lines.any(
      (line) =>
          line.startsWith('#EXT-X-STREAM-INF') || line.startsWith('#EXTINF'),
    );
    final hasUri = lines.any((line) => !line.startsWith('#'));
    return hasPlaylistEntry && hasUri;
  }

  DarbhangaResolution _mergeWithStation(
    DarbhangaResolution resolution,
    RadioStation station,
  ) => DarbhangaResolution(
    candidates: _deduplicate([
      ...resolution.candidates,
      ...station.streams.map(
        (stream) => DarbhangaCandidate(
          stream: stream,
          source: DarbhangaCandidateSource.stationFeed,
        ),
      ),
    ]),
    availability: resolution.availability,
    diagnostic: resolution.diagnostic,
  );

  DarbhangaCandidate? _readLastKnownGood(DateTime now) {
    final cache = _readCacheMap();
    if (cache == null) return null;
    final url = cache['url']?.toString() ?? '';
    final lastSuccess = DateTime.tryParse(
      cache['lastSuccessfulPlayback']?.toString() ?? '',
    );
    final failures = (cache['consecutiveFailureCount'] as num?)?.toInt() ?? 0;
    if (url.isEmpty ||
        lastSuccess == null ||
        now.difference(lastSuccess) > lastKnownGoodMaxAge ||
        failures >= maxConsecutiveFailures) {
      return null;
    }
    return DarbhangaCandidate(
      stream: StationStream(url: url, hls: true),
      source: DarbhangaCandidateSource.lastKnownGood,
    );
  }

  Map<String, Object?>? _readCacheMap() {
    final encoded = _preferences?.getString(_cacheKey);
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(encoded);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }

  static List<DarbhangaCandidate> _deduplicate(
    Iterable<DarbhangaCandidate> input,
  ) {
    final result = <String, DarbhangaCandidate>{};
    for (final candidate in input) {
      final uri = Uri.tryParse(candidate.stream.url.trim());
      if (uri == null ||
          (uri.scheme != 'https' && uri.scheme != 'http') ||
          uri.host.isEmpty) {
        continue;
      }
      result.putIfAbsent(uri.toString(), () => candidate);
    }
    return result.values.toList();
  }

  static bool _isNetworkFailure(Object error) {
    if (error is TimeoutException || error is SocketException) return true;
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => true,
        _ => _isNetworkFailure(error.error ?? ''),
      };
    }
    final text = error.toString().toLowerCase();
    return text.contains('dns') ||
        text.contains('host lookup') ||
        text.contains('connection reset') ||
        text.contains('handshake') ||
        text.contains('certificate') ||
        text.contains('timed out');
  }

  static String _safeDiagnostic(Object error) {
    final raw = error.toString();
    return raw.replaceAllMapped(RegExp(r'https?://[^\s]+'), (match) {
      final uri = Uri.tryParse(match.group(0)!);
      if (uri == null) return '<invalid-url>';
      return '${uri.scheme}://${uri.host}${uri.path}';
    });
  }
}

class _HlsProbe {
  const _HlsProbe({
    this.validHls = false,
    this.statusCode,
    this.networkFailure = false,
    this.redirectTargets = const [],
    required this.diagnostic,
  });

  final bool validHls;
  final int? statusCode;
  final bool networkFailure;
  final List<String> redirectTargets;
  final String diagnostic;
}
