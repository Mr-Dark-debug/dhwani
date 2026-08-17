import 'dart:async';

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

  testWidgets('real MP3 stream reaches playing and pauses', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DhwaniApp)),
    );
    final audio = container.read(audioHandlerProvider);

    await audio.setQueueStations(const [_swissJazz], selected: _swissJazz);
    await audio.selectStation(_swissJazz);
    unawaited(audio.play());
    final playing = await audio.snapshot
        .firstWhere((value) => value.status == DhwaniPlaybackStatus.playing)
        .timeout(const Duration(seconds: 30));
    expect(playing.station?.id, _swissJazz.id);
    expect(playing.stream?.url, _swissJazz.streams.single.url);

    await audio.pause();
    final paused = await audio.snapshot
        .firstWhere((value) => value.status == DhwaniPlaybackStatus.paused)
        .timeout(const Duration(seconds: 5));
    expect(paused.status, DhwaniPlaybackStatus.paused);
    await audio.stop();
  });
}

const _swissJazz = RadioStation(
  id: 'live-smoke-swiss-jazz',
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
