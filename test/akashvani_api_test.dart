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
    },
  );
}

class _AkashvaniAdapter implements HttpClientAdapter {
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
          Headers.contentTypeHeader: ['application/json'],
        },
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
