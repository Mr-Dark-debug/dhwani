import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/radio_station.dart';

class NotificationService {
  NotificationService({void Function(String payload)? onAction})
    : _onAction = onAction,
      _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final void Function(String payload)? _onAction;
  Future<void>? _initialization;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // UTC remains a safe fallback when a platform cannot report an IANA zone.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_dhwani'),
        iOS: DarwinInitializationSettings(),
        windows: WindowsInitializationSettings(
          appName: 'Dhwani',
          appUserModelId: 'Com.Prashant.Dhwani',
          guid: '7f0d6f4d-5ad6-4d15-a58b-9eb23b745629',
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) _onAction?.call(payload);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final initialPayload = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true &&
        initialPayload != null &&
        initialPayload.isNotEmpty) {
      _onAction?.call(initialPayload);
    }
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (!Platform.isAndroid) return true;
    return await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        false;
  }

  Future<void> scheduleReminder({
    required RadioStation station,
    required DateTime at,
    required bool alarm,
    Set<int> repeatWeekdays = const {},
    Duration? recordingDuration,
    double? preparedVolume,
  }) async {
    await initialize();
    if (repeatWeekdays.isEmpty) {
      await _scheduleOne(
        id: at.millisecondsSinceEpoch.remainder(2147483647),
        station: station,
        at: tz.TZDateTime.from(at, tz.local),
        alarm: alarm,
        recordingDuration: recordingDuration,
        preparedVolume: preparedVolume,
      );
      return;
    }
    for (final weekday in repeatWeekdays) {
      var next = tz.TZDateTime(
        tz.local,
        at.year,
        at.month,
        at.day,
        at.hour,
        at.minute,
      );
      while (next.weekday != weekday ||
          !next.isAfter(tz.TZDateTime.now(tz.local))) {
        next = next.add(const Duration(days: 1));
      }
      await _scheduleOne(
        id: Object.hash(station.id, alarm, weekday).abs().remainder(2147483647),
        station: station,
        at: next,
        alarm: alarm,
        recordingDuration: recordingDuration,
        preparedVolume: preparedVolume,
        components: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required RadioStation station,
    required tz.TZDateTime at,
    required bool alarm,
    required Duration? recordingDuration,
    required double? preparedVolume,
    DateTimeComponents? components,
  }) => _plugin.zonedSchedule(
    id: id,
    title: alarm ? 'Dhwani radio alarm' : 'Dhwani recording reminder',
    body: alarm
        ? 'Open ${station.name} and start listening${preparedVolume == null ? '.' : ' at ${(preparedVolume * 100).round()}% player volume.'}'
        : 'Open ${station.name} and start the prepared ${recordingDuration?.inMinutes ?? 30}-minute recording.',
    scheduledDate: at,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'com.prashant.dhwani.reminders',
        'Radio reminders',
        channelDescription: 'Radio alarm and recording reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload:
        '${alarm ? 'alarm' : 'record'}:${station.id}|${preparedVolume ?? ''}',
    matchDateTimeComponents: components,
  );

  Future<void> cancelAllReminders() async {
    await initialize();
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pending() async {
    await initialize();
    return _plugin.pendingNotificationRequests();
  }
}
