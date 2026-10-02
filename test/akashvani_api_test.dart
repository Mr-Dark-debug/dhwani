import 'dart:convert';
import 'dart:typed_data';

import 'package:dhwani/data/datasources/akashvani_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'official Darbhanga HLS is merged ahead of stale discovery URL',
    () async {
      final dio = Dio()..httpClientAdapter = _AkashvaniAdapter();
      final stations = await AkashvaniApi(dio: dio).stations();

      expect(stations, hasLength(1));
      final station = stations.single;
      expect(station.name, 'Akashvani Darbhanga');
      expect(station.frequency, 1296);
      expect(
        station.streams.first.url,
        'https://radio.wavespb.com/live/current/darbhanga.m3u8',
      );
      expect(station.streams.first.hls, isTrue);
      // The retired CloudFront mirror (HTTP 404 since 2026-10-01) is no
      // longer emitted; the current WAVES URL and the legacy BitGravity URL
      // remain as fallbacks behind the official URL.
      expect(
        station.streams.map((stream) => stream.url),
        containsAll([
          'https://legacy.test/darbhanga.m3u8',
          AkashvaniApi.currentDarbhangaStreamUrl,
        ]),
      );
      expect(
        station.streams.map((stream) => stream.url),
        isNot(contains(AkashvaniApi.darbhangaDeliveryStreamUrl)),
      );
    },
  );

  test(
    'Bihar stations refresh from the official page, not the stale feed',
    () async {
      final dio = Dio()..httpClientAdapter = _BiharAdapter();
      final stations = await AkashvaniApi(dio: dio).stations();

      final patna = stations.singleWhere(
        (item) => item.name == 'Akashvani Patna',
      );
      expect(
        patna.streams.first.url,
        'https://radio.wavespb.com/live/c398958b3874b441/c398958b3874b441.m3u8',
      );
      final bhagalpur = stations.singleWhere(
        (item) => item.name == 'Akashvani Bhagalpur',
      );
      expect(
        bhagalpur.streams.first.url,
        'https://radio.wavespb.com/live/a8c78a8fe3ebebb9/a8c78a8fe3ebebb9.m3u8',
      );
    },
  );

  test('known-current Darbhanga URL survives live-page failure', () async {
    final dio = Dio()
      ..httpClientAdapter = _AkashvaniAdapter(failLivePage: true);
    final station = (await AkashvaniApi(dio: dio).stations()).single;

    expect(station.streams.first.url, 'https://legacy.test/darbhanga.m3u8');
    expect(
      station.streams.map((stream) => stream.url),
      contains(AkashvaniApi.currentDarbhangaStreamUrl),
    );
  });
}

class _AkashvaniAdapter implements HttpClientAdapter {
  _AkashvaniAdapter({this.failLivePage = false});

  final bool failLivePage;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.toString() == AkashvaniApi.feedUrl) {
      return ResponseBody.fromString(
        jsonEncode([
          {
            'name': 'Akashvani Darbhanga',
            'state': 'BIHAR',
            'language': 'Maithili, Hindi',
            'stream_url': 'https://legacy.test/darbhanga.m3u8',
            'epg_id': 69,
          },
        ]),
        200,
        headers: {
          // raw.githubusercontent.com currently serves this JSON feed as
          // text/plain, so Android receives a String rather than a decoded List.
          Headers.contentTypeHeader: ['text/plain'],
        },
      );
    }
    if (failLivePage) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'simulated official page failure',
      );
    }
    if (options.uri.toString() ==
        'https://radio.wavespb.com/live/current/darbhanga.m3u8') {
      return ResponseBody.fromString(
        '#EXTM3U\n#EXTINF:10,\nsegment.aac\n',
        200,
      );
    }
    return ResponseBody.fromString(
      """
      <script>
      var channels = {
        '69': {
          name: 'Akashvani Darbhanga',
          state: 'Bihar',
          live_url: 'https://radio.wavespb.com/live/current/darbhanga.m3u8'
        }
      };
      </script>
      """,
      200,
      headers: {
        Headers.contentTypeHeader: ['text/html'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _BiharAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.toString() == AkashvaniApi.feedUrl) {
      // The discovery feed still carries retired BitGravity URLs for Bihar.
      return ResponseBody.fromString(
        jsonEncode([
          {
            'name': 'Akashvani Patna',
            'state': 'BIHAR',
            'language': 'Maithili, Hindi',
            'stream_url':
                'https://air.pc.cdn.bitgravity.com/air/live/pbaudio087/playlist.m3u8',
            'epg_id': 70,
          },
          {
            'name': 'Akashvani Bhagalpur',
            'state': 'BIHAR',
            'language': 'Maithili, Hindi',
            'stream_url':
                'https://air.pc.cdn.bitgravity.com/air/live/pbaudio292/playlist.m3u8',
            'epg_id': 68,
          },
        ]),
        200,
      );
    }
    return ResponseBody.fromString(
      """
      <script>
      var channels = {
        '68': {
          name: 'Akashvani Bhagalpur',
          //live_url: 'https://air.pc.cdn.bitgravity.com/air/live/pbaudio292/playlist.m3u8',
          live_url: 'https://radio.wavespb.com/live/a8c78a8fe3ebebb9/a8c78a8fe3ebebb9.m3u8'
        },
        '70': {
          name: 'Akashvani Patna',
          //live_url: 'https://air.pc.cdn.bitgravity.com/air/live/pbaudio087/playlist.m3u8',
          live_url: 'https://radio.wavespb.com/live/c398958b3874b441/c398958b3874b441.m3u8'
        }
      };
      </script>
      """,
      200,
      headers: {
        Headers.contentTypeHeader: ['text/html'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
