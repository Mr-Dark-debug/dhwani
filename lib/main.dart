import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/audio/dhwani_audio_handler.dart';
import 'core/persistence/app_database.dart';
import 'core/recording/recording_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/settings/settings_controller.dart';
import 'data/datasources/akashvani_api.dart';
import 'data/datasources/radio_browser_api.dart';
import 'data/repositories/catalogue_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  final database = AppDatabase();
  final preferences = await SharedPreferences.getInstance();
  final audioHandler = await AudioService.init(
    builder: () => DhwaniAudioHandler(
      onSessionEnded: (station, duration) =>
          database.addHistory(station, duration: duration),
      onStreamResult: (station, stream, success) =>
          database.recordStreamResult(station, stream.url, success: success),
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.prashant.dhwani.playback',
      androidNotificationChannelName: 'Live radio playback',
      androidNotificationIcon: 'drawable/ic_stat_dhwani',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFFE33B32),
    ),
  );
  final catalogue = CatalogueRepository(
    database: database,
    radioBrowser: RadioBrowserApi(),
    akashvani: AkashvaniApi(),
  );
  final recorder = RecordingService(database: database);
  final notifications = NotificationService(
    onAction: (payload) {
      unawaited(() async {
        final separator = payload.indexOf(':');
        if (separator < 0) return;
        final details = payload.substring(separator + 1).split('|');
        final stationId = details.first;
        final station = (await database.allStations())
            .where((item) => item.id == stationId)
            .firstOrNull;
        if (station == null) return;
        await preferences.setString('lastStation', station.encode());
        await preferences.setBool('onboardingComplete', true);
        await audioHandler.setQueueStations([station], selected: station);
        await audioHandler.selectStation(station);
        if (payload.startsWith('alarm:') && details.length > 1) {
          final volume = double.tryParse(details[1]);
          if (volume != null) await audioHandler.setVolume(volume);
        }
      }());
    },
  );
  unawaited(notifications.initialize());

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        preferencesProvider.overrideWithValue(preferences),
        sharedPreferencesForSettingsProvider.overrideWithValue(preferences),
        audioHandlerProvider.overrideWithValue(audioHandler),
        catalogueRepositoryProvider.overrideWithValue(catalogue),
        recordingServiceProvider.overrideWithValue(recorder),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const DhwaniApp(),
    ),
  );
}
