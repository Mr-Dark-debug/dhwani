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

  testWidgets(
    'Swiss, German, and Indian stations play with queue controls and recents',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DhwaniApp)),
      );
      final audio = container.read(audioHandlerProvider);
      final database = container.read(databaseProvider);
      await database.clearHistory();

      await _tuneAndWait(audio, _stations[0]);
      await audio.skipToNext();
      await _waitForPlaying(audio, _stations[1].id);
      await audio.skipToNext();
      await _waitForPlaying(audio, _stations[2].id);
      await audio.skipToPrevious();
      await _waitForPlaying(audio, _stations[1].id);

      await audio.pause();
      expect(audio.snapshot.value.status, DhwaniPlaybackStatus.paused);
      await audio.play();
      await _waitForPlaying(audio, _stations[1].id);

      final recents = await database.watchHistory().first;
      expect(
        recents.map((station) => station.id),
        containsAll(_stations.map((station) => station.id)),
      );
      await audio.stop();
    },
  );
}

Future<void> _tuneAndWait(
  DhwaniAudioHandler audio,
  RadioStation station,
) async {
  await audio
      .tuneStation(station, queueStations: _stations, autoplay: true)
      .timeout(const Duration(seconds: 30));
  await _waitForPlaying(audio, station.id);
}

Future<void> _waitForPlaying(DhwaniAudioHandler audio, String stationId) =>
    audio.snapshot
        .firstWhere(
          (snapshot) =>
              snapshot.status == DhwaniPlaybackStatus.playing &&
              snapshot.station?.id == stationId,
        )
        .timeout(const Duration(seconds: 30));

const _stations = [
  RadioStation(
    id: 'regression-swiss-jazz',
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
    directory: RadioDirectory.custom,
    verified: true,
  ),
  RadioStation(
    id: 'regression-deutschlandfunk',
    name: 'Deutschlandfunk',
    country: 'Germany',
    countryCode: 'DE',
    band: RadioBand.net,
    streams: [
      StationStream(
        url: 'https://st01.sslstream.dlf.de/dlf/01/128/mp3/stream.mp3',
        codec: 'MP3',
        bitrate: 128,
      ),
    ],
    directory: RadioDirectory.custom,
    verified: true,
  ),
  RadioStation(
    id: 'regression-akashvani-news',
    name: 'Akashvani Live News 24x7',
    country: 'India',
    countryCode: 'IN',
    band: RadioBand.net,
    streams: [
      StationStream(
        url:
            'https://airhlspush.pc.cdn.bitgravity.com/httppush/hlspbaudio002/hlspbaudio002_Auto.m3u8',
        hls: true,
      ),
    ],
    directory: RadioDirectory.custom,
    verified: true,
  ),
];
