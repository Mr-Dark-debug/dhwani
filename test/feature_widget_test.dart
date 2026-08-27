import 'package:dhwani/app/providers.dart';
import 'package:dhwani/core/audio/dhwani_audio_handler.dart';
import 'package:dhwani/core/persistence/app_database.dart';
import 'package:dhwani/core/settings/settings_controller.dart';
import 'package:dhwani/core/widgets/dhwani_shell.dart';
import 'package:dhwani/data/datasources/akashvani_api.dart';
import 'package:dhwani/data/datasources/radio_browser_api.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:dhwani/data/repositories/catalogue_repository.dart';
import 'package:dhwani/features/location/location_screens.dart';
import 'package:dhwani/features/player/player_screen.dart';
import 'package:dhwani/features/player/retro_tuner_screen.dart';
import 'package:dhwani/features/search/search_screen.dart';
import 'package:dhwani/features/settings/settings_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('search shows recent terms, clears them, and suggestions run', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'recentSearches': ['Darbhanga', 'Jazz'],
    });
    final preferences = await SharedPreferences.getInstance();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = _FakeCatalogue(database);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(preferences),
          catalogueRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Jazz'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(find.text('Recent'), findsNothing);

    await tester.tap(find.text('Darbhanga'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Akashvani Darbhanga'), findsOneWidget);
  });

  testWidgets('station list exposes requested sort modes and reorders A–Z', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final stations = [_station('z', 'Zulu'), _station('a', 'Alpha')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(preferences),
          stationsProvider.overrideWith((ref) => Stream.value(stations)),
          favouritesProvider.overrideWith((ref) => Stream.value(const [])),
          historyProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: StationListScreen(country: 'DE')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Zulu')).dy,
      lessThan(tester.getTopLeft(find.text('Alpha')).dy),
    );

    await tester.tap(find.byTooltip('Sort stations'));
    await tester.pumpAndSettle();
    for (final label in [
      'Recommended',
      'Frequency',
      'Popular',
      'A–Z',
      'Bitrate',
      'Recently played',
      'Saved first',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    await tester.scrollUntilVisible(
      find.text('A–Z'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(
      find.widgetWithText(PopupMenuItem<StationSortMode>, 'A–Z'),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Alpha')).dy,
      lessThan(tester.getTopLeft(find.text('Zulu')).dy),
    );
  });

  testWidgets('settings exposes behavioral playback and storage controls', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(preferences),
          sharedPreferencesForSettingsProvider.overrideWithValue(preferences),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auto play last station'), findsOneWidget);
    expect(find.text('Default station scope'), findsOneWidget);
    expect(find.text('Wi-Fi only'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Default recording format'), 260);
    expect(find.text('Default recording format'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Default recording directory'),
      120,
    );
    expect(find.text('Default recording directory'), findsOneWidget);
  });

  testWidgets(
    'player screen exposes top more menu, band dropdown, and 2-row controls',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = _FakeCatalogue(database);
      const testStation = RadioStation(
        id: 'air:darbhanga',
        name: 'Akashvani Darbhanga',
        country: 'India',
        countryCode: 'IN',
        state: 'Bihar',
        city: 'Darbhanga',
        band: RadioBand.am,
        frequency: 1296,
        frequencyUnit: 'kHz',
        streams: [StationStream(url: 'https://example.test/live')],
        directory: RadioDirectory.offlineSeed,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const PlayerScreen()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(preferences),
            sharedPreferencesForSettingsProvider.overrideWithValue(preferences),
            databaseProvider.overrideWithValue(database),
            catalogueRepositoryProvider.overrideWithValue(repository),
            audioHandlerProvider.overrideWithValue(_FakeAudioHandler()),
            stationsProvider.overrideWith((ref) => Stream.value([testStation])),
            selectedStationProvider.overrideWith(
              () => _TestSelectedStationController(testStation),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Verify top bar items: more menu button (3 dots) and band selector
      expect(find.byTooltip('More actions'), findsOneWidget);
      expect(find.byTooltip('Filter by source / band'), findsOneWidget);
      expect(find.byTooltip('Station information'), findsNothing);

      // Verify Row 1 control items
      expect(find.byTooltip('Previous station'), findsOneWidget);
      expect(find.byTooltip('Save favourite'), findsOneWidget);
      expect(find.byTooltip('Record live broadcast'), findsOneWidget);
      expect(find.byTooltip('Next station'), findsOneWidget);

      // Verify Row 2 main hero Play/Pause button
      expect(find.byKey(const Key('player-play-pause')), findsOneWidget);

      // Verify tapping band dropdown opens band options
      await tester.tap(find.byTooltip('Filter by source / band'));
      await tester.pumpAndSettle();
      expect(find.text('All Bands'), findsOneWidget);
      expect(find.text('AM Radio'), findsOneWidget);
      expect(find.text('FM Radio'), findsOneWidget);
      expect(find.text('Internet (NET)'), findsOneWidget);
      await tester.tap(find.text('FM Radio'));
      await tester.pumpAndSettle();

      // Verify tapping top right 3-dots more menu opens sheet with Station info
      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      expect(find.text('Station info'), findsOneWidget);
      expect(find.text('Sleep timer'), findsOneWidget);

      // Verify opening Sleep timer opens radial SleepTimerSheet
      await tester.tap(find.text('Sleep timer'));
      await tester.pumpAndSettle();
      expect(find.text('Sleep Session'), findsOneWidget);
      expect(find.text('Start Sleep Timer'), findsOneWidget);
      expect(find.text('15 m'), findsOneWidget);
      expect(find.text('30 m'), findsOneWidget);
      expect(find.text('45 m'), findsOneWidget);
      expect(find.text('DRAG TO SET'), findsOneWidget);
    },
  );

  testWidgets(
    'shell renders google nav bar tabs and navigates between sections',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = _FakeCatalogue(database);

      final router = GoRouter(
        initialLocation: '/radio',
        routes: [
          GoRoute(
            path: '/radio',
            builder: (context, state) =>
                const DhwaniShell(child: Text('Radio Body')),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) =>
                const DhwaniShell(child: Text('Discover Body')),
          ),
          GoRoute(
            path: '/saved',
            builder: (context, state) =>
                const DhwaniShell(child: Text('Saved Body')),
          ),
          GoRoute(
            path: '/recordings',
            builder: (context, state) =>
                const DhwaniShell(child: Text('Recordings Body')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(preferences),
            sharedPreferencesForSettingsProvider.overrideWithValue(preferences),
            databaseProvider.overrideWithValue(database),
            catalogueRepositoryProvider.overrideWithValue(repository),
            audioHandlerProvider.overrideWithValue(_FakeAudioHandler()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(GButton, 'Radio'), findsOneWidget);
      expect(find.widgetWithText(GButton, 'Discover'), findsOneWidget);
      expect(find.widgetWithText(GButton, 'Saved'), findsOneWidget);
      expect(find.widgetWithText(GButton, 'Recordings'), findsOneWidget);
      expect(find.text('Radio Body'), findsOneWidget);

      await tester.tap(find.widgetWithText(GButton, 'Discover'));
      await tester.pumpAndSettle();
      expect(find.text('Discover Body'), findsOneWidget);
    },
  );

  testWidgets(
    'retro tuner renders frequency, marquee, controls, and volume knob',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = _FakeCatalogue(database);
      final station = const RadioStation(
        id: 'air:darbhanga',
        name: 'Akashvani Darbhanga',
        country: 'India',
        countryCode: 'IN',
        state: 'Bihar',
        city: 'Darbhanga',
        band: RadioBand.fm,
        frequency: 100.1,
        frequencyUnit: 'MHz',
        streams: [StationStream(url: 'https://example.test/live')],
        directory: RadioDirectory.offlineSeed,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(preferences),
            sharedPreferencesForSettingsProvider.overrideWithValue(preferences),
            databaseProvider.overrideWithValue(database),
            catalogueRepositoryProvider.overrideWithValue(repository),
            audioHandlerProvider.overrideWithValue(_FakeAudioHandler()),
            selectedStationProvider.overrideWith(
              () => _TestSelectedStationController(station),
            ),
            stationsProvider.overrideWith((ref) => Stream.value([station])),
            favouritesProvider.overrideWith((ref) => Stream.value([station])),
          ],
          child: const MaterialApp(home: RetroTunerScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100.1'), findsOneWidget);
      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.text('Akashvani Darbhanga'), findsWidgets);
      expect(find.text('FM · AM · NET'), findsOneWidget);
      expect(find.text('RADIO AREA'), findsOneWidget);
      expect(find.text('STEREO'), findsOneWidget);
      expect(find.text('Favourite stations · 1'), findsOneWidget);
      expect(find.byType(RetroTunerScreen), findsOneWidget);
    },
  );
}

class _FakeAudioHandler extends Fake implements DhwaniAudioHandler {
  @override
  bool get equalizerSupported => false;

  @override
  final BehaviorSubject<DhwaniPlayerSnapshot> snapshot = BehaviorSubject.seeded(
    const DhwaniPlayerSnapshot(status: DhwaniPlaybackStatus.ready),
  );

  @override
  RadioStation? get currentStation => null;

  @override
  Future<void> setQueueStations(
    List<RadioStation> stations, {
    RadioStation? selected,
  }) async {}

  @override
  Future<void> selectStation(
    RadioStation station, {
    bool autoplay = false,
  }) async {}

  @override
  Future<void> tuneStation(
    RadioStation station, {
    List<RadioStation>? queueStations,
    bool autoplay = false,
  }) async {}

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  double get volume => 1.0;

  @override
  Future<void> setVolume(double volume) async {}
}

class _FakeCatalogue extends CatalogueRepository {
  _FakeCatalogue(AppDatabase database)
    : super(
        database: database,
        radioBrowser: RadioBrowserApi(),
        akashvani: AkashvaniApi(),
      );

  @override
  Future<List<RadioStation>> searchLocal(String query) async => [
    const RadioStation(
      id: 'air:darbhanga',
      name: 'Akashvani Darbhanga',
      country: 'India',
      countryCode: 'IN',
      state: 'Bihar',
      city: 'Darbhanga',
      band: RadioBand.am,
      frequency: 1296,
      frequencyUnit: 'kHz',
      streams: [StationStream(url: 'https://example.test/live')],
      directory: RadioDirectory.offlineSeed,
    ),
  ];

  @override
  Future<List<RadioStation>> searchRemote(
    String query, {
    List<RadioStation>? localResults,
  }) async => localResults ?? searchLocal(query);
}

RadioStation _station(String id, String name) => RadioStation(
  id: id,
  name: name,
  country: 'Germany',
  countryCode: 'DE',
  band: RadioBand.net,
  streams: const [StationStream(url: 'https://example.test/live')],
  directory: RadioDirectory.radioBrowser,
);

class _TestSelectedStationController extends SelectedStationController {
  _TestSelectedStationController(this.initialStation);
  final RadioStation initialStation;

  @override
  RadioStation? build() => initialStation;
}
