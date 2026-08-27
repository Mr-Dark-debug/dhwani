import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/custom_station/custom_station_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/location/location_screens.dart';
import '../features/player/car_mode_screen.dart';
import '../features/player/player_screen.dart';
import '../features/player/retro_tuner_screen.dart';
import '../features/recordings/recordings_screen.dart';
import '../features/saved/saved_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../data/models/radio_station.dart';
import 'providers.dart';

final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

final routerProvider = Provider<GoRouter>((ref) {
  final preferences = ref.read(preferencesProvider);
  return GoRouter(
    navigatorKey: ref.read(rootNavigatorKeyProvider),
    initialLocation: preferences.getBool('onboardingComplete') == true
        ? '/radio'
        : '/welcome',
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/countries', builder: (_, _) => const CountryScreen()),
      GoRoute(path: '/states', builder: (_, _) => const StateScreen()),
      GoRoute(
        path: '/cities',
        builder: (_, state) =>
            CityScreen(state: state.uri.queryParameters['state'] ?? 'Bihar'),
      ),
      GoRoute(
        path: '/stations',
        builder: (_, state) => StationListScreen(
          country: state.uri.queryParameters['country'] ?? 'India',
          state: state.uri.queryParameters['state'],
          city: state.uri.queryParameters['city'],
        ),
      ),
      GoRoute(path: '/radio', builder: (_, _) => const PlayerScreen()),
      GoRoute(path: '/discover', builder: (_, _) => const DiscoverScreen()),
      GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
      GoRoute(path: '/recordings', builder: (_, _) => const RecordingsScreen()),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/custom-station',
        builder: (_, state) => CustomStationScreen(
          station: state.extra is RadioStation
              ? state.extra! as RadioStation
              : null,
          duplicate: state.uri.queryParameters['duplicate'] == 'true',
        ),
      ),
      GoRoute(path: '/car', builder: (_, _) => const CarModeScreen()),
      GoRoute(path: '/retro', builder: (_, _) => const RetroTunerScreen()),
      GoRoute(
        path: '/schedules',
        builder: (_, _) => const ScheduleScreen(alarm: false),
      ),
      GoRoute(
        path: '/alarm',
        builder: (_, _) => const ScheduleScreen(alarm: true),
      ),
    ],
  );
});
