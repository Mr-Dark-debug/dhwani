import 'dart:io';
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
      // The app records platform callback failures in main.dart; mirror that
      // behavior in this standalone probe so the final snapshot can report the
      // classified candidate failure.
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
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    addTearDown(client.close);
    for (final stream in station.streams.take(2)) {
      try {
        final request = await client
            .getUrl(Uri.parse(stream.url))
            .timeout(const Duration(seconds: 10));
        request.followRedirects = false;
        request.headers.set('User-Agent', 'Dhwani/1 (com.prashant.dhwani)');
        final response = await request.close().timeout(
          const Duration(seconds: 10),
        );
        // ignore: avoid_print
        print(
          'Darbhanga HTTP probe (${Uri.parse(stream.url).host}): '
          'status=${response.statusCode}; '
          'location=${response.headers.value(HttpHeaders.locationHeader)}; '
          'contentType=${response.headers.contentType}',
        );
        await response.drain<void>();
      } catch (error) {
        // ignore: avoid_print
        print(
          'Darbhanga HTTP probe (${Uri.parse(stream.url).host}) failed: '
          '$error',
        );
      }
    }
    final attemptedHosts = <String>[];
    final subscription = audio.snapshot.listen((snapshot) {
      final host = Uri.tryParse(snapshot.stream?.url ?? '')?.host;
      if (host != null && host.isNotEmpty && !attemptedHosts.contains(host)) {
        attemptedHosts.add(host);
      }
    });
    addTearDown(subscription.cancel);

    expect(station.streams.first.url, AkashvaniApi.darbhangaDeliveryStreamUrl);
    await audio
        .tuneStation(station, queueStations: [station], autoplay: true)
        .timeout(const Duration(seconds: 30));

    expect(attemptedHosts, isNotEmpty);
    expect(attemptedHosts.first, 'd3hrxqn1tritdh.cloudfront.net');
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
      'attempted ${attemptedHosts.join(', ')}; '
      'failure=${audio.snapshot.value.failure?.reason.name}; '
      'diagnostic=${audio.snapshot.value.failure?.diagnostic}',
    );
    await audio.stop();
  });
}
