import 'package:dhwani/app/app.dart';
import 'package:dhwani/app/providers.dart';
import 'package:dhwani/core/audio/dhwani_audio_handler.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:dhwani/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('100 transitions plus repeated section navigation stay stable', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboardingComplete', true);
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DhwaniApp)),
    );
    final audio = container.read(audioHandlerProvider);
    final stations = List.generate(
      7,
      (index) => RadioStation(
        id: 'stress-$index',
        name: 'Stress Station $index',
        country: 'Testland',
        countryCode: 'TT',
        band: RadioBand.net,
        streams: [StationStream(url: 'https://stress$index.invalid/live')],
        directory: RadioDirectory.custom,
      ),
    );
    await audio.tuneStation(
      stations.first,
      queueStations: stations,
      autoplay: false,
    );

    for (var index = 0; index < 100; index++) {
      await audio.tuneRelative(index.isEven ? 1 : -1, autoplay: false);
    }

    for (var cycle = 0; cycle < 5; cycle++) {
      await tester.tap(find.byKey(const Key('nav-discover')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-saved')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-recordings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-radio')));
      await tester.pumpAndSettle();
    }

    expect(audio.snapshot.value.busy, isFalse);
    expect(audio.snapshot.value.failure, isNull);
    expect(audio.snapshot.value.status, DhwaniPlaybackStatus.ready);
    expect(find.byType(DhwaniApp), findsOneWidget);
  });
}
