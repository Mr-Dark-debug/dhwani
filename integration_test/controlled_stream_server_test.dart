import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dhwani/app/app.dart';
import 'package:dhwani/app/providers.dart';
import 'package:dhwani/core/audio/dhwani_audio_handler.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:dhwani/main.dart' as app;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('controlled streams redirect, fail, and cancel stale tuning', (
    tester,
  ) async {
    final fixture = await _BrokenRadioFixture.start();
    addTearDown(fixture.close);
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DhwaniApp)),
    );
    final audio = container.read(audioHandlerProvider);

    final redirected = fixture.station('redirected', '/redirect');
    await audio.tuneStation(
      redirected,
      queueStations: [redirected],
      autoplay: true,
    );
    expect(audio.snapshot.value.status, DhwaniPlaybackStatus.playing);

    final missing = fixture.station('missing', '/404');
    await audio.tuneStation(missing, queueStations: [missing], autoplay: true);
    expect(audio.snapshot.value.status, DhwaniPlaybackStatus.unavailable);
    expect(audio.snapshot.value.busy, isFalse);

    final delayed = fixture.station('delayed', '/delayed');
    final newest = fixture.station('newest', '/working.wav');
    final stale = audio.tuneStation(
      delayed,
      queueStations: [delayed, newest],
      autoplay: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await audio.tuneStation(
      newest,
      queueStations: [delayed, newest],
      autoplay: true,
    );
    await stale;

    expect(audio.currentStation?.id, newest.id);
    expect(audio.snapshot.value.station?.id, newest.id);
    expect(audio.snapshot.value.status, DhwaniPlaybackStatus.playing);
    await audio.stop();
  });
}

class _BrokenRadioFixture {
  _BrokenRadioFixture(this.server, this.wav);

  final HttpServer server;
  final Uint8List wav;
  StreamSubscription<HttpRequest>? _requests;

  static Future<_BrokenRadioFixture> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _BrokenRadioFixture(server, _toneWav());
    fixture._requests = server.listen(fixture._handle);
    return fixture;
  }

  String get baseUrl => 'http://127.0.0.1:${server.port}';

  RadioStation station(String id, String path) => RadioStation(
    id: 'controlled-$id',
    name: 'Controlled $id',
    country: 'Testland',
    countryCode: 'TT',
    band: RadioBand.net,
    streams: [StationStream(url: '$baseUrl$path', codec: 'WAV')],
    directory: RadioDirectory.custom,
    verified: true,
  );

  Future<void> _handle(HttpRequest request) async {
    switch (request.uri.path) {
      case '/redirect':
        request.response.statusCode = HttpStatus.found;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          '/working.wav',
        );
        await request.response.close();
        return;
      case '/delayed':
        await Future<void>.delayed(const Duration(milliseconds: 800));
        await _writeWav(request.response);
        return;
      case '/working.wav':
        await _writeWav(request.response);
        return;
      case '/404':
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      case '/500':
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
        return;
      case '/drop':
        request.response.headers.contentType = ContentType('audio', 'wav');
        request.response.add(wav.sublist(0, math.min(8192, wav.length)));
        await request.response.close();
        return;
      default:
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
    }
  }

  Future<void> _writeWav(HttpResponse response) async {
    response.headers.contentType = ContentType('audio', 'wav');
    response.contentLength = wav.length;
    response.add(wav);
    await response.close();
  }

  Future<void> close() async {
    await _requests?.cancel();
    await server.close(force: true);
  }
}

Uint8List _toneWav() {
  const sampleRate = 8000;
  const seconds = 8;
  const channels = 1;
  const bytesPerSample = 2;
  final sampleCount = sampleRate * seconds;
  final dataLength = sampleCount * channels * bytesPerSample;
  final bytes = ByteData(44 + dataLength);

  void text(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      bytes.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  text(0, 'RIFF');
  bytes.setUint32(4, 36 + dataLength, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, channels, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * channels * bytesPerSample, Endian.little);
  bytes.setUint16(32, channels * bytesPerSample, Endian.little);
  bytes.setUint16(34, bytesPerSample * 8, Endian.little);
  text(36, 'data');
  bytes.setUint32(40, dataLength, Endian.little);
  for (var index = 0; index < sampleCount; index++) {
    final sample = (math.sin(2 * math.pi * 220 * index / sampleRate) * 2400)
        .round();
    bytes.setInt16(44 + index * 2, sample, Endian.little);
  }
  return bytes.buffer.asUint8List();
}
