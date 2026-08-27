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
      expect(station.streams, hasLength(2));
      expect(
        station.streams.first.url,
        'https://radio.wavespb.com/live/current/darbhanga.m3u8',
      );
      expect(station.streams.first.hls, isTrue);
      expect(station.streams.last.url, 'https://legacy.test/darbhanga.m3u8');
    },
  );

  test('known-current Darbhanga URL survives live-page failure', () async {
    final dio = Dio()
      ..httpClientAdapter = _AkashvaniAdapter(failLivePage: true);
    final station = (await AkashvaniApi(dio: dio).stations()).single;

    expect(station.streams.first.url, AkashvaniApi.currentDarbhangaStreamUrl);
    expect(station.streams.last.url, 'https://legacy.test/darbhanga.m3u8');
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
    return ResponseBody.fromString(
      """
      name: 'Akashvani Darbhanga',
      live_url: 'https://radio.wavespb.com/live/current/darbhanga.m3u8',
      state: 'Bihar'
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
