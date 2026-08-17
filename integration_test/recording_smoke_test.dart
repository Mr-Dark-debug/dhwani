import 'dart:io';

import 'package:dhwani/app/app.dart';
import 'package:dhwani/app/providers.dart';
import 'package:dhwani/core/recording/recording_service.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:dhwani/main.dart' as app;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real stream records a validated playable file', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DhwaniApp)),
    );
    final recorder = container.read(recordingServiceProvider);
    recorder.configure(preferredFormat: 'auto');

    await recorder.start(_swissJazz, _swissJazz.streams.single);
    await _waitForBytes(recorder);
    await Future<void>.delayed(const Duration(seconds: 10));
    final entry = await recorder.stop();

    final file = File(entry.path);
    expect(await file.exists(), isTrue);
    expect(await file.length(), greaterThan(1024));
    expect(entry.duration, greaterThan(const Duration(seconds: 8)));
    expect(entry.format, 'mp3');

    recorder.configure(preferredFormat: 'm4a');
    await recorder.start(_swissJazz, _swissJazz.streams.single);
    final convertedOutput = await _waitForBytes(recorder);
    await Future<void>.delayed(const Duration(seconds: 8));
    final converted = await recorder.stop();
    expect(await convertedOutput.length(), greaterThan(1024));
    expect(converted.format, 'm4a');
    expect(converted.duration, greaterThan(const Duration(seconds: 6)));

    await recorder.deleteAllRecordings();
    expect(await file.exists(), isFalse);
    expect(await convertedOutput.exists(), isFalse);
  });
}

Future<File> _waitForBytes(RecordingService recorder) async {
  final output = File(recorder.state.value.path!);
  for (var second = 0; second < 30; second++) {
    if (await output.exists() && await output.length() > 2048) return output;
    if (recorder.state.value.status == RecordingStatus.error) {
      fail(
        '${recorder.state.value.message ?? 'Recording connection ended'}\n'
        '${recorder.lastDiagnostic ?? 'No FFmpeg diagnostic'}',
      );
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  fail('Recording did not produce bytes within 30 seconds.');
}

const _swissJazz = RadioStation(
  id: 'recording-smoke-swiss-jazz',
  name: 'Radio Swiss Jazz',
  country: 'Switzerland',
  countryCode: 'CH',
  band: RadioBand.net,
  streams: [
    StationStream(
      url: 'https://stream.srg-ssr.ch/m/rsj/mp3_128',
      codec: 'MP3',
      bitrate: 128,
    ),
  ],
  languages: ['German'],
  tags: ['jazz'],
  directory: RadioDirectory.custom,
  verified: true,
);
