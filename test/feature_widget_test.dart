import 'package:dhwani/app/providers.dart';
import 'package:dhwani/core/persistence/app_database.dart';
import 'package:dhwani/core/settings/settings_controller.dart';
import 'package:dhwani/data/datasources/akashvani_api.dart';
import 'package:dhwani/data/datasources/radio_browser_api.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:dhwani/data/repositories/catalogue_repository.dart';
import 'package:dhwani/features/location/location_screens.dart';
import 'package:dhwani/features/search/search_screen.dart';
import 'package:dhwani/features/settings/settings_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
      find.widgetWithText(CheckedPopupMenuItem<StationSortMode>, 'A–Z'),
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
