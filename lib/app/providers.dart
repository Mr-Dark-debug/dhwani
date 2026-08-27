import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/audio/dhwani_audio_handler.dart';
import '../core/logging/dhwani_log.dart';
import '../core/notifications/notification_service.dart';
import '../core/persistence/app_database.dart';
import '../core/recording/recording_service.dart';
import '../core/settings/settings_controller.dart';
import '../core/updater/app_update_service.dart';
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
final appUpdateServiceProvider = Provider<AppUpdateService>(
  (ref) => AppUpdateService(),
);

/// Starts user-requested playback without gating audio on a notification
/// permission dialog. Android media-session notifications are exempt from the
/// Android 13 notification runtime permission, while reminders request that
/// permission contextually when the user schedules one.
Future<void> playWithMediaNotification(
  WidgetRef ref, [
  RadioStation? explicitStation,
]) async {
  final selected = explicitStation ?? ref.read(selectedStationProvider);
  final handler = ref.read(audioHandlerProvider);
  if (selected != null &&
      (handler.currentStation == null ||
          handler.currentStation!.id != selected.id)) {
    final all = ref.read(stationsProvider).value ?? const <RadioStation>[];
    final queue = tuningQueue(
      all,
      current: selected,
      preferredScope: ref.read(settingsProvider).defaultScope,
    );
    await ref
        .read(stationPlaybackControllerProvider)
        .tune(selected, queue: queue, autoplay: true);
  } else {
    await handler.play();
  }
}

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
final historySummariesProvider = StreamProvider<List<HistorySummary>>(
  (ref) => ref.read(databaseProvider).watchHistorySummaries(),
);
final collectionsProvider = StreamProvider<List<StationCollectionSummary>>(
  (ref) => ref.read(databaseProvider).watchCollections(),
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
  RadioStation? build() {
    try {
      final preferences = ref.watch(preferencesProvider);
      final encoded = preferences.getString('lastStation');
      if (encoded != null && encoded.trim().isNotEmpty) {
        return RadioStation.decode(encoded);
      }
    } catch (error, stack) {
      DhwaniLog.player(
        'Failed to restore lastStation from preferences',
        error,
        stack,
      );
    }
    return null;
  }

  void select(RadioStation station) {
    state = station;
    if (station.sourceType != RadioSourceType.localRecording) {
      ref.read(preferencesProvider).setString('lastStation', station.encode());
    }
  }
}

final selectedStationProvider =
    NotifierProvider<SelectedStationController, RadioStation?>(
      SelectedStationController.new,
    );

final stationPlaybackControllerProvider = Provider<StationPlaybackController>(
  StationPlaybackController.new,
);

/// One entry point for station selection across every screen.
///
/// It finalizes an active recording before changing its source, delegates the
/// atomic queue/player transition to [DhwaniAudioHandler], and only then
/// persists the selected station. Listening history is intentionally handled
/// by the audio handler after playback is confirmed.
class StationPlaybackController {
  StationPlaybackController(this.ref);

  final Ref ref;

  Future<void> tune(
    RadioStation station, {
    required List<RadioStation> queue,
    bool autoplay = false,
    bool persistSelection = true,
  }) async {
    await _finishRecordingBeforeSwitch(station);
    await ref
        .read(audioHandlerProvider)
        .tuneStation(station, queueStations: queue, autoplay: autoplay);
    ref.read(selectedStationProvider.notifier).select(station);
    if (persistSelection &&
        station.sourceType != RadioSourceType.localRecording) {
      final preferences = ref.read(preferencesProvider);
      await preferences.setString('lastStation', station.encode());
      await preferences.setBool('onboardingComplete', true);
    }
  }

  Future<RadioStation?> next({bool? autoplay}) => _relative(1, autoplay);

  Future<RadioStation?> previous({bool? autoplay}) => _relative(-1, autoplay);

  Future<RadioStation?> _relative(int delta, bool? autoplay) async {
    final handler = ref.read(audioHandlerProvider);
    final current = handler.currentStation;
    if (current == null) return null;
    final queue = handler.queueStations;
    if (queue.isEmpty) return null;
    final index = queue.indexWhere((station) => station.id == current.id);
    final currentIndex = index < 0 ? 0 : index;
    final targetIndex = (currentIndex + delta).remainder(queue.length) < 0
        ? (currentIndex + delta).remainder(queue.length) + queue.length
        : (currentIndex + delta).remainder(queue.length);
    final target = queue[targetIndex];
    await tune(
      target,
      queue: queue,
      autoplay: autoplay ?? handler.intendsPlayback,
    );
    return target;
  }

  Future<void> retry() async {
    await ref.read(audioHandlerProvider).retry();
  }

  Future<void> _finishRecordingBeforeSwitch(RadioStation target) async {
    try {
      final recorder = ref.read(recordingServiceProvider);
      final recording = recorder.state.value;
      if (recording.station?.id == target.id ||
          recording.status == RecordingStatus.idle ||
          recording.status == RecordingStatus.saved ||
          recording.status == RecordingStatus.failed) {
        return;
      }
      if (recording.status == RecordingStatus.starting ||
          recording.status == RecordingStatus.recording) {
        await recorder.stop();
        return;
      }
      await recorder.state
          .firstWhere(
            (item) =>
                item.status == RecordingStatus.idle ||
                item.status == RecordingStatus.saved ||
                item.status == RecordingStatus.failed,
          )
          .timeout(const Duration(milliseconds: 1200));
    } catch (_) {}
  }
}

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
  static const _preferenceKey = 'sleepTimerEndAt';
  Timer? _timer;
  double? _originalVolume;

  @override
  SleepTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    final encoded = ref.read(preferencesProvider).getString(_preferenceKey);
    final endAt = DateTime.tryParse(encoded ?? '');
    if (endAt != null && endAt.isAfter(DateTime.now())) {
      final remaining = endAt.difference(DateTime.now());
      Future.microtask(() => _schedule(endAt));
      return SleepTimerState(endAt: endAt, remaining: remaining);
    }
    if (encoded != null) {
      Future.microtask(
        () => ref.read(preferencesProvider).remove(_preferenceKey),
      );
    }
    return const SleepTimerState();
  }

  void start(Duration duration) {
    final endAt = DateTime.now().add(duration);
    ref
        .read(preferencesProvider)
        .setString(_preferenceKey, endAt.toIso8601String());
    _schedule(endAt);
  }

  void _schedule(DateTime endAt) {
    _timer?.cancel();
    _originalVolume ??= ref.read(audioHandlerProvider).volume;
    state = SleepTimerState(
      endAt: endAt,
      remaining: endAt.difference(DateTime.now()),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final remaining = endAt.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        _timer?.cancel();
        state = const SleepTimerState();
        await ref.read(audioHandlerProvider).stop();
        await _restoreVolume();
        await ref.read(preferencesProvider).remove(_preferenceKey);
      } else {
        if (remaining <= const Duration(seconds: 15) &&
            _originalVolume != null) {
          final fade = remaining.inMilliseconds / 15000;
          await ref
              .read(audioHandlerProvider)
              .setVolume((_originalVolume! * fade).clamp(0, 1));
        }
        state = SleepTimerState(endAt: endAt, remaining: remaining);
      }
    });
  }

  Future<void> cancel() async {
    _timer?.cancel();
    state = const SleepTimerState();
    await _restoreVolume();
    await ref.read(preferencesProvider).remove(_preferenceKey);
  }

  Future<void> _restoreVolume() async {
    final volume = _originalVolume;
    _originalVolume = null;
    if (volume != null) await ref.read(audioHandlerProvider).setVolume(volume);
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
  String preferredScope = 'city',
}) {
  Iterable<RadioStation> filter(String? city, String? state, String? country) =>
      stations.where((station) {
        if (band != null && station.band != band) return false;
        if (city != null && station.city != city) return false;
        if (state != null && station.state != state) return false;
        if (country != null && station.countryCode != country) return false;
        return station.canPlay;
      });
  var queue = switch (preferredScope) {
    'worldwide' => filter(null, null, null).toList(),
    'country' => filter(null, null, current.countryCode).toList(),
    'state' => filter(null, current.state, current.countryCode).toList(),
    _ => filter(current.city, current.state, current.countryCode).toList(),
  };
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
