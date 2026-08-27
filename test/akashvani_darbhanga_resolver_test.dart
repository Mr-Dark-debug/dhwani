import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dhwani/data/datasources/akashvani_darbhanga_resolver.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    now = DateTime.utc(2026, 8, 28, 6);
  });

  AkashvaniDarbhangaResolver resolver(_ResolverAdapter adapter) =>
      AkashvaniDarbhangaResolver(
        dio: Dio()..httpClientAdapter = adapter,
        preferences: preferences,
        now: () => now,
      );

  test(
    'official source returns a new URL and makes it candidate one',
    () async {
      const fresh = 'https://official.example/live/new.m3u8';
      final adapter = _ResolverAdapter({
        AkashvaniDarbhangaResolver.officialLivePageUrl: [_ok(_html(fresh))],
        fresh: [_ok(_mediaPlaylist)],
      });

      final result = await resolver(adapter).resolve(station: _darbhanga);

      expect(result.availability, DarbhangaAvailability.active);
      expect(result.candidates.first.stream.url, fresh);
      expect(
        result.candidates.first.source,
        DarbhangaCandidateSource.officialPage,
      );
    },
  );

  test(
    'bounded partial response is accepted only when it is valid HLS',
    () async {
      const fresh = 'https://official.example/live/partial.m3u8';
      final adapter = _ResolverAdapter({
        AkashvaniDarbhangaResolver.officialLivePageUrl: [_ok(_html(fresh))],
        fresh: [_Reply(status: 206, body: _mediaPlaylist)],
      });

      final result = await resolver(adapter).resolve(station: _darbhanga);

      expect(result.availability, DarbhangaAvailability.active);
    },
  );

  test('structured channel 69 parsing is independent of property distance', () {
    final html =
        """
      var channels = {
        '12': {name: 'Other', live_url: 'https://other.test/a.m3u8'},
        '69': {
          image: '${'x' * 2500}',
          live_url: 'https://official.example/live/reordered.m3u8',
          name: 'Akashvani Darbhanga',
          next: 'assamase'
        }
      };
    """;

    expect(
      AkashvaniDarbhangaResolver.parseOfficialStreamUrl(html),
      'https://official.example/live/reordered.m3u8',
    );
  });

  test('cached last-known-good URL is retained when discovery fails', () async {
    const cached = 'https://cache.example/darbhanga.m3u8';
    final writer = resolver(_ResolverAdapter(const {}));
    await writer.recordPlaybackResult(cached, success: true);
    final adapter = _ResolverAdapter({
      AkashvaniDarbhangaResolver.officialLivePageUrl: [
        _error(const SocketException('offline')),
      ],
    });

    final result = await resolver(adapter).resolve(station: _darbhanga);

    expect(result.candidates.first.stream.url, cached);
    expect(
      result.candidates.first.source,
      DarbhangaCandidateSource.lastKnownGood,
    );
  });

  test('cached URL failure can force refresh to a new official URL', () async {
    const cached = 'https://cache.example/old.m3u8';
    const fresh = 'https://official.example/live/fresh.m3u8';
    final subject = resolver(
      _ResolverAdapter({
        AkashvaniDarbhangaResolver.officialLivePageUrl: [
          _error(const SocketException('offline')),
          _ok(_html(fresh)),
        ],
        fresh: [_ok(_mediaPlaylist)],
      }),
    );
    await subject.recordPlaybackResult(cached, success: true);

    expect(
      (await subject.resolve(station: _darbhanga)).candidates.first.stream.url,
      cached,
    );
    final refreshed = await subject.resolve(
      station: _darbhanga,
      forceRefresh: true,
    );
    expect(refreshed.candidates.first.stream.url, fresh);
    expect(refreshed.availability, DarbhangaAvailability.active);
  });

  test('WAVES redirect is captured as a delivery candidate', () async {
    const waves = 'https://radio.waves.test/live/id/id.m3u8';
    const delivery = 'https://cdn-a.example/id/id.m3u8';
    final adapter = _ResolverAdapter({
      AkashvaniDarbhangaResolver.officialLivePageUrl: [_ok(_html(waves))],
      waves: [_redirect(delivery)],
      delivery: [_ok(_masterPlaylist)],
    });

    final result = await resolver(adapter).resolve(station: _darbhanga);

    expect(result.availability, DarbhangaAvailability.active);
    expect(
      result.candidates
          .where(
            (candidate) =>
                candidate.source == DarbhangaCandidateSource.redirectDelivery,
          )
          .single
          .stream
          .url,
      delivery,
    );
  });

  test('forced discovery learns a rotated CDN hostname', () async {
    const wavesA = 'https://radio.waves.test/live/a/a.m3u8';
    const wavesB = 'https://radio.waves.test/live/b/b.m3u8';
    const cdnA = 'https://cdn-a.example/a/a.m3u8';
    const cdnB = 'https://cdn-b.example/b/b.m3u8';
    final adapter = _ResolverAdapter({
      AkashvaniDarbhangaResolver.officialLivePageUrl: [
        _ok(_html(wavesA)),
        _ok(_html(wavesB)),
      ],
      wavesA: [_redirect(cdnA)],
      cdnA: [_ok(_mediaPlaylist)],
      wavesB: [_redirect(cdnB)],
      cdnB: [_ok(_mediaPlaylist)],
    });
    final subject = resolver(adapter);

    final first = await subject.resolve(station: _darbhanga);
    final second = await subject.resolve(
      station: _darbhanga,
      forceRefresh: true,
    );

    expect(first.candidates.map((item) => item.stream.url), contains(cdnA));
    expect(second.candidates.map((item) => item.stream.url), contains(cdnB));
    expect(
      second.candidates.map((item) => item.stream.url),
      isNot(contains(cdnA)),
    );
  });

  test('old CloudFront 404 stays behind a refreshed official URL', () async {
    const old = 'https://old-cloudfront.example/id.m3u8';
    const fresh = 'https://official.example/new.m3u8';
    final writer = resolver(_ResolverAdapter(const {}));
    await writer.recordPlaybackResult(old, success: true);
    final adapter = _ResolverAdapter({
      AkashvaniDarbhangaResolver.officialLivePageUrl: [_ok(_html(fresh))],
      fresh: [_ok(_mediaPlaylist)],
    });

    final result = await resolver(adapter).resolve(station: _darbhanga);

    expect(result.candidates.first.stream.url, fresh);
    expect(result.candidates[1].stream.url, old);
  });

  test('refreshed URL validates and reports active', () async {
    const fresh = 'https://official.example/refreshed.m3u8';
    final result = await resolver(
      _ResolverAdapter({
        AkashvaniDarbhangaResolver.officialLivePageUrl: [_ok(_html(fresh))],
        fresh: [_ok(_mediaPlaylist)],
      }),
    ).resolve(station: _darbhanga, forceRefresh: true);

    expect(result.availability, DarbhangaAvailability.active);
    expect(result.diagnostic, contains('Validated'));
  });

  test('official current URL returning 404 reports off air cleanly', () async {
    const missing = 'https://official.example/off-air.m3u8';
    final result = await resolver(
      _ResolverAdapter({
        AkashvaniDarbhangaResolver.officialLivePageUrl: [_ok(_html(missing))],
        missing: [_status(404)],
      }),
    ).resolve(station: _darbhanga);

    expect(result.availability, DarbhangaAvailability.offAir);
    expect(result.candidates, isNotEmpty);
    expect(result.diagnostic, contains('404'));
  });

  test('network timeout is distinct from off air', () async {
    final result = await resolver(
      _ResolverAdapter({
        AkashvaniDarbhangaResolver.officialLivePageUrl: [
          _error(TimeoutException('page timed out')),
        ],
      }),
    ).resolve(station: _darbhanga);

    expect(result.availability, DarbhangaAvailability.networkUnavailable);
  });

  test('DNS failure is distinct from off air', () async {
    final result = await resolver(
      _ResolverAdapter({
        AkashvaniDarbhangaResolver.officialLivePageUrl: [
          _error(const SocketException('Failed host lookup')),
        ],
      }),
    ).resolve(station: _darbhanga);

    expect(result.availability, DarbhangaAvailability.networkUnavailable);
  });

  test('TLS and reset failures are distinct from off air', () async {
    for (final error in <Object>[
      const HandshakeException('certificate handshake failed'),
      const SocketException('Connection reset by peer'),
    ]) {
      final result = await resolver(
        _ResolverAdapter({
          AkashvaniDarbhangaResolver.officialLivePageUrl: [_error(error)],
        }),
      ).resolve(station: _darbhanga);
      expect(result.availability, DarbhangaAvailability.networkUnavailable);
    }
  });

  test('official discovery page unavailable keeps fallbacks', () async {
    final result = await resolver(
      _ResolverAdapter({
        AkashvaniDarbhangaResolver.officialLivePageUrl: [_status(503)],
      }),
    ).resolve(station: _darbhanga);

    expect(result.availability, DarbhangaAvailability.discoveryUnavailable);
    expect(result.candidates.map((item) => item.stream.url), contains(_stale));
  });

  test('fresh official URL is ahead of stale station feed URL', () async {
    const fresh = 'https://official.example/current.m3u8';
    final result = await resolver(
      _ResolverAdapter({
        AkashvaniDarbhangaResolver.officialLivePageUrl: [_ok(_html(fresh))],
        fresh: [_ok(_mediaPlaylist)],
      }),
    ).resolve(station: _darbhanga);

    expect(result.candidates.first.stream.url, fresh);
    expect(result.candidates.map((item) => item.stream.url), contains(_stale));
  });

  test('duplicate URLs are removed without reordering', () async {
    const fresh = AkashvaniDarbhangaResolver.currentWavesFallback;
    final station = _darbhanga.copyWith(
      streams: const [
        StationStream(url: fresh, hls: true),
        StationStream(url: fresh, hls: true),
        StationStream(url: _stale, hls: true),
      ],
    );
    final result = await resolver(
      _ResolverAdapter({
        AkashvaniDarbhangaResolver.officialLivePageUrl: [_ok(_html(fresh))],
        fresh: [_ok(_mediaPlaylist)],
      }),
    ).resolve(station: station);
    final urls = result.candidates.map((item) => item.stream.url).toList();

    expect(urls.toSet(), hasLength(urls.length));
    expect(urls.first, fresh);
  });

  test('redirect chain cannot loop forever', () async {
    const a = 'https://redirect.example/a.m3u8';
    const b = 'https://redirect.example/b.m3u8';
    final adapter = _ResolverAdapter({
      AkashvaniDarbhangaResolver.officialLivePageUrl: [_ok(_html(a))],
      a: [_redirect(b)],
      b: [_redirect(a)],
    });

    final result = await resolver(adapter).resolve(station: _darbhanga);

    expect(result.availability, isNot(DarbhangaAvailability.active));
    expect(adapter.totalManifestRequests, lessThanOrEqualTo(6));
  });

  test('three failures invalidate the cached last-known-good URL', () async {
    const cached = 'https://cache.example/failing.m3u8';
    final subject = resolver(_ResolverAdapter(const {}));
    await subject.recordPlaybackResult(cached, success: true);
    for (var count = 0; count < 3; count++) {
      await subject.recordPlaybackResult(
        cached,
        success: false,
        failureReason: 'notFound',
      );
    }
    final result = await resolver(
      _ResolverAdapter({
        AkashvaniDarbhangaResolver.officialLivePageUrl: [
          _error(const SocketException('offline')),
        ],
      }),
    ).resolve(station: _darbhanga);

    expect(result.candidates.first.stream.url, isNot(cached));
  });

  test('non-Darbhanga stations are returned byte-for-byte in order', () async {
    const other = RadioStation(
      id: 'other',
      name: 'Other Station',
      country: 'Germany',
      countryCode: 'DE',
      band: RadioBand.net,
      streams: [
        StationStream(url: 'https://one.example/live.mp3'),
        StationStream(url: 'https://two.example/live.mp3'),
      ],
      directory: RadioDirectory.radioBrowser,
    );
    final adapter = _ResolverAdapter(const {});

    final result = await resolver(adapter).resolve(station: other);

    expect(
      result.candidates.map((item) => item.stream.toJson()).toList(),
      other.streams.map((item) => item.toJson()).toList(),
    );
    expect(adapter.calls, isEmpty);
  });
}

const _stale = 'https://feed.example/stale.m3u8';
const _darbhanga = RadioStation(
  id: 'air:69',
  name: 'Akashvani Darbhanga',
  country: 'India',
  countryCode: 'IN',
  state: 'Bihar',
  city: 'Darbhanga',
  band: RadioBand.am,
  frequency: 1296,
  frequencyUnit: 'kHz',
  streams: [StationStream(url: _stale, hls: true)],
  languages: ['Maithili', 'Hindi'],
  directory: RadioDirectory.akashvani,
);

const _mediaPlaylist =
    '#EXTM3U\n#EXT-X-TARGETDURATION:6\n#EXTINF:6,\nsegment.aac\n';
const _masterPlaylist =
    '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=64000\naudio/index.m3u8\n';

String _html(String url) =>
    """
  <li data-channel="69">Akashvani Darbhanga</li>
  <script>
    var channels = {
      '7': {name: 'Other', live_url: 'https://other.example/live.m3u8'},
      '69': {
        image: 'https://images.example/69.jpg',
        live_url: '$url',
        next: 'assamase',
        name: 'Akashvani Darbhanga'
      }
    };
  </script>
""";

class _Reply {
  const _Reply({
    this.status = 200,
    this.body = '',
    this.headers = const {},
    this.error,
  });

  final int status;
  final String body;
  final Map<String, List<String>> headers;
  final Object? error;
}

_Reply _ok(String body) => _Reply(body: body);
_Reply _status(int status) => _Reply(status: status);
_Reply _redirect(String location) => _Reply(
  status: 302,
  headers: {
    HttpHeaders.locationHeader: [location],
  },
);
_Reply _error(Object error) => _Reply(error: error);

class _ResolverAdapter implements HttpClientAdapter {
  _ResolverAdapter(Map<String, List<_Reply>> routes)
    : _routes = {
        for (final entry in routes.entries) entry.key: [...entry.value],
      };

  final Map<String, List<_Reply>> _routes;
  final List<String> calls = [];

  int get totalManifestRequests => calls
      .where((url) => url != AkashvaniDarbhangaResolver.officialLivePageUrl)
      .length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    calls.add(url);
    final replies = _routes[url];
    if (replies == null || replies.isEmpty) {
      throw SocketException('No test route for ${options.uri.host}');
    }
    final reply = replies.length == 1 ? replies.first : replies.removeAt(0);
    if (reply.error != null) throw reply.error!;
    return ResponseBody.fromString(
      reply.body,
      reply.status,
      headers: reply.headers,
    );
  }

  @override
  void close({bool force = false}) {}
}
