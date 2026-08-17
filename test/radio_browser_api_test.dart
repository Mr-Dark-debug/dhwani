import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dhwani/data/datasources/radio_browser_api.dart';

void main() {
  test('Radio Browser retries the next discovered mirror', () async {
    final dio = Dio();
    final adapter = _RadioBrowserAdapter();
    dio.httpClientAdapter = adapter;
    final api = RadioBrowserApi(dio: dio);

    final stations = await api.byCountry('CH');

    expect(adapter.stationRequests, 2);
    expect(stations, hasLength(1));
    expect(stations.single.name, 'Radio Swiss Jazz');
    expect(stations.single.countryCode, 'CH');
  });

  test('Radio Browser rejects malformed list responses', () async {
    final dio = Dio();
    dio.httpClientAdapter = _MalformedAdapter();
    final api = RadioBrowserApi(dio: dio);

    await expectLater(api.countries(), throwsA(isA<FormatException>()));
  });
}

class _RadioBrowserAdapter implements HttpClientAdapter {
  int stationRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.host == 'all.api.radio-browser.info') {
      return _json([
        {'name': 'one.api.radio-browser.info'},
        {'name': 'two.api.radio-browser.info'},
      ]);
    }
    stationRequests++;
    if (stationRequests == 1) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'simulated mirror failure',
      );
    }
    return _json([
      {
        'stationuuid': 'swiss-jazz',
        'name': 'Radio Swiss Jazz',
        'country': 'Switzerland',
        'countrycode': 'CH',
        'url_resolved': 'https://stream.example.test/swiss.mp3',
        'codec': 'MP3',
        'bitrate': 128,
        'language': 'German',
        'tags': 'jazz',
        'lastcheckok': 1,
      },
    ]);
  }

  @override
  void close({bool force = false}) {}
}

class _MalformedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.host == 'all.api.radio-browser.info') {
      return _json([
        {'name': 'one.api.radio-browser.info'},
      ]);
    }
    return _json({'unexpected': true});
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
