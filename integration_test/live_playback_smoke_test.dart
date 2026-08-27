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

  testWidgets('real live stream reaches playing and pauses', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DhwaniApp)),
    );
    final audio = container.read(audioHandlerProvider);
    // Exercise the real audio-service/ExoPlayer path on a fresh install.
    // Playback must not depend on notification runtime permission.
    final playingFuture = audio.snapshot
        .firstWhere((value) => value.status == DhwaniPlaybackStatus.playing)
        .timeout(const Duration(seconds: 30));
    await audio
        .tuneStation(
          _liveStation,
          queueStations: const [_liveStation],
          autoplay: true,
        )
        .timeout(const Duration(seconds: 30));
    final playing = await playingFuture;
    expect(playing.station?.id, _liveStation.id);
    expect(
      _liveStation.streams.map((stream) => stream.url),
      contains(playing.stream?.url),
    );

    await audio.pause();
    final paused = await audio.snapshot
        .firstWhere((value) => value.status == DhwaniPlaybackStatus.paused)
        .timeout(const Duration(seconds: 5));
    expect(paused.status, DhwaniPlaybackStatus.paused);
    await audio.stop();
  });
}

const _liveStation = RadioStation(
  id: 'live-smoke-radio-swiss-jazz',
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
    StationStream(
      url: 'https://icecast.radiofrance.fr/fip-midfi.mp3',
      codec: 'MP3',
      bitrate: 128,
    ),
  ],
  languages: ['German', 'French', 'Italian'],
  tags: ['music', 'public radio'],
  directory: RadioDirectory.custom,
  verified: true,
);
