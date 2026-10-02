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
  // Retired 2026-10-01: the CloudFront delivery distribution that previously
  // mirrored the Darbhanga WAVES path now returns HTTP 404 for the current
  // stream identifier (verified with a bounded GET from two networks).
  // The constant is retained for diagnostics/tests but is no longer emitted
  // as a playback candidate.
  static const currentDeliveryFallback =
      'https://d3hrxqn1tritdh.cloudfront.net/8e074285599ed45d/8e074285599ed45d.m3u8';
  static const legacyBitgravityFallback =
      'https://air.pc.cdn.bitgravity.com/air/live/pbaudio160/playlist.m3u8';

  /// Current official WAVES identifiers for Bihar stations whose discovery
  /// feed (stations.json) still carries retired BitGravity `pbaudio*` URLs.
  /// Verified against https://akashvani.gov.in/radio/live.php on 2026-10-01.
  /// The map is keyed by official channel id (EPG id). It is a fallback for
  /// offline/first-run use; the live page remains authoritative at runtime.
  static const biharWavesByChannelId = <String, String>{
    '68':
        'https://radio.wavespb.com/live/a8c78a8fe3ebebb9/a8c78a8fe3ebebb9.m3u8',
    '69':
        'https://radio.wavespb.com/live/8e074285599ed45d/8e074285599ed45d.m3u8',
    '70':
        'https://radio.wavespb.com/live/c398958b3874b441/c398958b3874b441.m3u8',
    '71':
        'https://radio.wavespb.com/live/cef8ad34fec1c9d9/cef8ad34fec1c9d9.m3u8',
    '72':
        'https://radio.wavespb.com/live/e82b2584f0277bda/e82b2584f0277bda.m3u8',
    '73':
        'https://radio.wavespb.com/live/2d4feb204790b6e3/2d4feb204790b6e3.m3u8',
    '74':
        'https://radio.wavespb.com/live/cd626d48acead509/cd626d48acead509.m3u8',
  };

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
  Map<String, String>? _recentOfficialMap;
  DateTime? _recentOfficialMapAt;
  final Map<String, DarbhangaCandidateSource> _knownSources = {};

  /// Fetches the official live page once and returns every channel's current
  /// `live_url`. Results are reused for [discoveryReuse] so refreshing the
  /// whole Akashvani catalogue costs one bounded HTTP GET, not one per
  /// station. Returns an empty map when the page cannot be read; callers
  /// must fall back to feed/seed URLs in that case.
  Future<Map<String, String>> officialStreamMap({
    bool forceRefresh = false,
  }) async {
    final now = _now();
    if (!forceRefresh &&
        _recentOfficialMap != null &&
        _recentOfficialMapAt != null &&
        now.difference(_recentOfficialMapAt!) < discoveryReuse) {
      return _recentOfficialMap!;
    }
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
      final parsed = parseOfficialStreamMap(response.data ?? '');
      if (parsed.isNotEmpty) {
        _recentOfficialMap = parsed;
        _recentOfficialMapAt = now;
        return parsed;
      }
      return _recentOfficialMap ?? const {};
    } catch (error, stack) {
      DhwaniLog.api(
        'Akashvani official stream map unavailable; feed URLs retained',
        error,
        stack,
      );
      return _recentOfficialMap ?? const {};
    }
  }

  /// Returns the official live URL for any Akashvani catalogue station, or
  /// null when the page does not list its channel. Prefers a fresh fetch,
  /// then the cached map, then the baked Bihar WAVES table for offline use.
  Future<String?> officialUrlForStation(
    RadioStation station, {
    bool forceRefresh = false,
  }) async {
    final channel = channelIdForStation(station);
    if (channel == null) return null;
    final live = await officialStreamMap(forceRefresh: forceRefresh);
    final url = live[channel];
    if (url != null && url.isNotEmpty) return url;
    return biharWavesByChannelId[channel];
  }

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
      for (final url in const [currentWavesFallback, legacyBitgravityFallback])
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

  static String parseOfficialStreamUrl(String html) =>
      parseOfficialStreamUrlFor(
        html,
        channelId,
        expectedName: 'Akashvani Darbhanga',
      );

  /// Parses the official `live.php` page for an arbitrary Akashvani channel.
  ///
  /// Commented-out `//live_url:` entries (the page keeps retired BitGravity
  /// URLs as comments) are ignored. Only trusted HTTPS URLs are returned.
  static String parseOfficialStreamUrlFor(
    String html,
    String targetChannelId, {
    String? expectedName,
  }) {
    final body = _extractChannelObject(html, targetChannelId);
    if (expectedName != null) {
      final name = _extractJsString(body, 'name');
      if (name != expectedName) {
        throw FormatException(
          'Official channel $targetChannelId identity changed.',
        );
      }
    }
    final liveUrl = _extractJsString(body, 'live_url').trim();
    final uri = Uri.tryParse(liveUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException(
        'Channel $targetChannelId live_url is not trusted HTTPS.',
      );
    }
    return uri.toString();
  }

  /// Best-effort parse of every `'<id>': { ... live_url: '...' }` entry on
  /// the official page. Used to refresh all Akashvani stations in one fetch
  /// instead of one request per station. Commented entries are skipped and
  /// non-HTTPS entries are dropped.
  static Map<String, String> parseOfficialStreamMap(String html) {
    final result = <String, String>{};
    final keyPattern = RegExp(r"""['"](\d{1,4})['"]\s*:\s*\{""");
    for (final keyMatch in keyPattern.allMatches(html)) {
      final id = keyMatch.group(1)!;
      if (result.containsKey(id)) continue;
      final open = html.indexOf('{', keyMatch.end - 1);
      if (open < 0) continue;
      final body = _balancedBody(html, open);
      if (body == null) continue;
      String liveUrl;
      try {
        liveUrl = _extractJsString(body, 'live_url').trim();
      } on FormatException {
        continue;
      }
      final uri = Uri.tryParse(liveUrl);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) continue;
      result[id] = uri.toString();
    }
    return result;
  }

  /// Official channel id for an Akashvani catalogue station, derived from the
  /// discovery feed's EPG id (`sourceId`) or the `air:<id>` station id.
  static String? channelIdForStation(RadioStation station) {
    final source = station.sourceId?.trim();
    if (source != null && RegExp(r'^\d{1,4}$').hasMatch(source)) return source;
    final id = station.id.trim();
    if (id.startsWith('air:')) {
      final suffix = id.substring(4);
      if (RegExp(r'^\d{1,4}$').hasMatch(suffix)) return suffix;
    }
    return null;
  }

  static String _extractChannelObject(String source, String id) {
    final key = RegExp(
      "['\"]${RegExp.escape(id)}['\"]\\s*:",
    ).firstMatch(source);
    if (key == null) {
      throw FormatException('Official channel $id missing.');
    }
    final open = source.indexOf('{', key.end);
    if (open < 0) {
      throw FormatException('Official channel $id malformed.');
    }
    final body = _balancedBody(source, open);
    if (body == null) {
      throw FormatException('Official channel $id object is incomplete.');
    }
    return body;
  }

  static String? _balancedBody(String source, int open) {
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
    return null;
  }

  static String _extractJsString(String objectBody, String property) {
    // The official page keeps retired BitGravity URLs as `//live_url:`
    // comments. A match on such a commented line must be skipped, otherwise
    // a stale 404 URL would shadow the current WAVES URL on the next line.
    final pattern = RegExp(
      "${RegExp.escape(property)}\\s*:\\s*(['\"])(.*?)\\1",
      dotAll: true,
    );
    for (final match in pattern.allMatches(objectBody)) {
      final lineStart = objectBody.lastIndexOf('\n', match.start) + 1;
      final linePrefix = objectBody.substring(lineStart, match.start);
      final commentIndex = linePrefix.indexOf('//');
      if (commentIndex >= 0) {
        // `https://` inside the value is after the match, not in the prefix,
        // so any `//` in the prefix is a JS comment marker.
        continue;
      }
      // Require a plausible delimiter before the property (start, comma,
      // newline, or brace) so `next: '...'` values cannot false-match.
      final before = linePrefix.trimRight();
      if (before.isNotEmpty &&
          !before.endsWith(',') &&
          !before.endsWith('{') &&
          lineStart != 0) {
        // Check the immediate preceding non-space character in the body.
        var cursor = match.start - 1;
        while (cursor >= 0 &&
            (objectBody[cursor] == ' ' ||
                objectBody[cursor] == '\t' ||
                objectBody[cursor] == '\r' ||
                objectBody[cursor] == '\n')) {
          cursor--;
        }
        final delimiter = cursor < 0 ? '' : objectBody[cursor];
        if (delimiter != ',' && delimiter != '{' && delimiter != '\n') {
          continue;
        }
      }
      return match
          .group(2)!
          .replaceAll(r'\/', '/')
          .replaceAll(r"\'", "'")
          .replaceAll(r'\"', '"');
    }
    throw FormatException('Official channel is missing $property.');
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
