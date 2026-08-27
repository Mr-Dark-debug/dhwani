import 'dart:async';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/audio/dhwani_audio_handler.dart';
import 'core/logging/dhwani_log.dart';
import 'core/persistence/app_database.dart';
import 'core/recording/recording_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/settings/settings_controller.dart';
import 'data/datasources/akashvani_api.dart';
import 'data/datasources/akashvani_darbhanga_resolver.dart';
import 'data/datasources/radio_browser_api.dart';
import 'data/repositories/catalogue_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    previousFlutterErrorHandler?.call(details);
    DhwaniLog.android(
      'Uncaught Flutter framework error',
      details.exception,
      details.stack,
    );
  };
  final previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    DhwaniLog.android('Uncaught platform callback error', error, stack);
    return previousPlatformErrorHandler?.call(error, stack) ?? true;
  };
  await _startApp();
}

Future<void> _startApp() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  final database = AppDatabase();
  final preferences = await SharedPreferences.getInstance();
  final darbhangaResolver = AkashvaniDarbhangaResolver(
    preferences: preferences,
  );
  final audioHandler = await AudioService.init(
    builder: () => DhwaniAudioHandler(
      onSessionStarted: database.startHistorySession,
      onSessionUpdated: database.updateHistorySession,
      darbhangaResolver: darbhangaResolver,
      onStreamResult: (station, stream, success, failure, startupTime) async {
        await database.recordStreamResult(
          station,
          stream.url,
          success: success,
          failureReason: failure?.reason.name,
          startupTime: startupTime,
        );
        if (station.isDarbhanga) {
          await darbhangaResolver.recordPlaybackResult(
            stream.url,
            success: success,
            failureReason: failure?.reason.name,
          );
        }
      },
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
    akashvani: AkashvaniApi(darbhangaResolver: darbhangaResolver),
  );
  final recorder = RecordingService(database: database);
  final notifications = NotificationService(
    onAction: (payload) {
      unawaited(() async {
        try {
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
          final activeRecording = recorder.state.value;
          if (activeRecording.station?.id != station.id &&
              (activeRecording.status == RecordingStatus.starting ||
                  activeRecording.status == RecordingStatus.recording)) {
            await recorder.stop();
          }
          final alarm = payload.startsWith('alarm:');
          await audioHandler.tuneStation(
            station,
            queueStations: [station],
            autoplay: alarm,
          );
          if (alarm && details.length > 1) {
            final volume = double.tryParse(details[1]);
            if (volume != null) await audioHandler.setVolume(volume);
          }
        } catch (error, stack) {
          DhwaniLog.android('Notification action failed safely', error, stack);
        }
      }());
    },
  );
  unawaited(
    notifications.initialize().catchError((Object error, StackTrace stack) {
      DhwaniLog.android('Notification initialization failed', error, stack);
    }),
  );

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
