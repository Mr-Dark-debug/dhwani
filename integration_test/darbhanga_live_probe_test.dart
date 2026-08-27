import 'dart:ui';

import 'package:dhwani/core/audio/dhwani_audio_handler.dart';
import 'package:dhwani/data/datasources/akashvani_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('official Darbhanga source is attempted and terminates cleanly', (
    tester,
  ) async {
    final previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      // just_audio's local header proxy can surface the same transport error
      // both through setUrl and the root platform callback. The app handles the
      // latter in main.dart; mirror that behavior in this standalone probe.
      return true;
    };
    addTearDown(
      () => PlatformDispatcher.instance.onError = previousPlatformErrorHandler,
    );
    final audio = DhwaniAudioHandler();
    addTearDown(audio.disposeHandler);
    final station = (await AkashvaniApi().stations()).singleWhere(
      (item) => item.isDarbhanga,
    );
    final attemptedHosts = <String>[];
    final subscription = audio.snapshot.listen((snapshot) {
      final host = Uri.tryParse(snapshot.stream?.url ?? '')?.host;
      if (host != null && host.isNotEmpty && !attemptedHosts.contains(host)) {
        attemptedHosts.add(host);
      }
    });
    addTearDown(subscription.cancel);

    expect(station.streams.first.url, contains('radio.wavespb.com'));
    await audio
        .tuneStation(station, queueStations: [station], autoplay: true)
        .timeout(const Duration(seconds: 30));

    expect(attemptedHosts, isNotEmpty);
    expect(attemptedHosts.first, 'radio.wavespb.com');
    expect(audio.snapshot.value.busy, isFalse);
    // Darbhanga is geo/network dependent. A bounded unavailable result is
    // truthful; PLAYING is recorded when the current network can reach India.
    expect(
      audio.snapshot.value.status,
      anyOf(
        DhwaniPlaybackStatus.playing,
        DhwaniPlaybackStatus.unavailable,
        DhwaniPlaybackStatus.geoBlocked,
        DhwaniPlaybackStatus.unsupported,
        DhwaniPlaybackStatus.offline,
      ),
    );
    // ignore: avoid_print
    print(
      'Darbhanga probe: ${audio.snapshot.value.status.name}; '
      'attempted ${attemptedHosts.join(', ')}',
    );
    await audio.stop();
  });
}
