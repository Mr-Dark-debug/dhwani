import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/audio/dhwani_audio_handler.dart';
import '../core/persistence/app_database.dart';
import '../core/recording/recording_service.dart';
import '../core/notifications/notification_service.dart';
import '../data/datasources/radio_browser_api.dart';
import '../data/models/radio_station.dart';
import '../data/repositories/catalogue_repository.dart';

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(),
);
final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final audioHandlerProvider = Provider<DhwaniAudioHandler>(
  (ref) => throw UnimplementedError(),
);
final catalogueRepositoryProvider = Provider<CatalogueRepository>(
  (ref) => throw UnimplementedError(),
);
final recordingServiceProvider = Provider<RecordingService>(
  (ref) => throw UnimplementedError(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(),
);

final bootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(catalogueRepositoryProvider).bootstrap();
});
final stationsProvider = StreamProvider<List<RadioStation>>(
  (ref) => ref.read(catalogueRepositoryProvider).watchStations(),
);
final favouritesProvider = StreamProvider<List<RadioStation>>(
  (ref) => ref.read(catalogueRepositoryProvider).watchFavourites(),
);
final customStationsProvider = StreamProvider<List<RadioStation>>(
  (ref) => ref.read(databaseProvider).watchCustomStations(),
);
final historyProvider = StreamProvider<List<RadioStation>>(
  (ref) => ref.read(catalogueRepositoryProvider).watchHistory(),
);
final recordingsProvider = StreamProvider(
  (ref) => ref.read(databaseProvider).watchRecordings(),
);
final countriesProvider = FutureProvider<List<CountrySummary>>(
  (ref) => ref.read(catalogueRepositoryProvider).countries(),
);
final playerSnapshotProvider = StreamProvider<DhwaniPlayerSnapshot>(
  (ref) => ref.read(audioHandlerProvider).snapshot,
);
final recordingSnapshotProvider = StreamProvider<RecordingSnapshot>(
  (ref) => ref.read(recordingServiceProvider).state,
);

class SelectedStationController extends Notifier<RadioStation?> {
  @override
  RadioStation? build() => null;
  void select(RadioStation station) => state = station;
}

final selectedStationProvider =
    NotifierProvider<SelectedStationController, RadioStation?>(
      SelectedStationController.new,
    );

class BandFilterController extends Notifier<RadioBand?> {
  @override
  RadioBand? build() => null;
  void set(RadioBand? band) => state = band;
}

final bandFilterProvider = NotifierProvider<BandFilterController, RadioBand?>(
  BandFilterController.new,
);

class SleepTimerState {
  const SleepTimerState({this.endAt, this.remaining = Duration.zero});
  final DateTime? endAt;
  final Duration remaining;
  bool get active => endAt != null && remaining > Duration.zero;
}

class SleepTimerController extends Notifier<SleepTimerState> {
  Timer? _timer;

  @override
  SleepTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return const SleepTimerState();
  }

  void start(Duration duration) {
    _timer?.cancel();
    final endAt = DateTime.now().add(duration);
    state = SleepTimerState(endAt: endAt, remaining: duration);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final remaining = endAt.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        _timer?.cancel();
        state = const SleepTimerState();
        await ref.read(audioHandlerProvider).stop();
      } else {
        state = SleepTimerState(endAt: endAt, remaining: remaining);
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    state = const SleepTimerState();
  }
}

final sleepTimerProvider =
    NotifierProvider<SleepTimerController, SleepTimerState>(
      SleepTimerController.new,
    );

List<RadioStation> tuningQueue(
  List<RadioStation> stations, {
  required RadioStation current,
  RadioBand? band,
}) {
  Iterable<RadioStation> filter(String? city, String? state, String? country) =>
      stations.where((station) {
        if (band != null && station.band != band) return false;
        if (city != null && station.city != city) return false;
        if (state != null && station.state != state) return false;
        if (country != null && station.countryCode != country) return false;
        return station.canPlay;
      });
  var queue = filter(current.city, current.state, current.countryCode).toList();
  if (queue.length < 2) {
    queue = filter(null, current.state, current.countryCode).toList();
  }
  if (queue.length < 2) {
    queue = filter(null, null, current.countryCode).toList();
  }
  if (queue.length < 2) {
    queue = stations
        .where(
          (station) =>
              station.canPlay && (band == null || station.band == band),
        )
        .toList();
  }
  queue.sort((a, b) {
    if (a.frequency != null && b.frequency != null) {
      return a.frequency!.compareTo(b.frequency!);
    }
    if (a.frequency != null) return -1;
    if (b.frequency != null) return 1;
    return b.clickCount.compareTo(a.clickCount);
  });
  return queue;
}
