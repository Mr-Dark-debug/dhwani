import 'package:dhwani/app/app.dart';
import 'package:dhwani/app/providers.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:dhwani/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android equalizer and repeated reminders initialize', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final context = tester.element(find.byType(DhwaniApp));
    final container = ProviderScope.containerOf(context);

    final audio = container.read(audioHandlerProvider);
    expect(audio.equalizerSupported, isTrue);
    final equalizer = await audio.equalizerParameters().timeout(
      const Duration(seconds: 12),
    );
    if (equalizer != null) expect(equalizer.bands, isNotEmpty);
    audio.configureEqualizer('voice');

    final notifications = container.read(notificationServiceProvider);
    await notifications.cancelAllReminders();
    final at = DateTime.now().add(const Duration(minutes: 10));
    await notifications.scheduleReminder(
      station: _station,
      at: at,
      alarm: false,
      repeatWeekdays: {at.weekday, at.add(const Duration(days: 1)).weekday},
      recordingDuration: const Duration(minutes: 30),
    );
    final pending = await notifications.pending();
    expect(pending, hasLength(2));
    expect(
      pending.every((item) => item.payload?.startsWith('record:') == true),
      isTrue,
    );
    await notifications.cancelAllReminders();
  });
}

const _station = RadioStation(
  id: 'integration-platform',
  name: 'Integration Radio',
  country: 'Switzerland',
  countryCode: 'CH',
  band: RadioBand.net,
  streams: [StationStream(url: 'https://example.com/live.mp3')],
  directory: RadioDirectory.custom,
);
