import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/updater/app_update_sheet.dart';
import '../../core/updater/app_update_service.dart';
import '../../core/widgets/brand_mark.dart';
import '../../data/models/radio_station.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            const _Heading('Appearance'),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (value) =>
                  controller.update(settings.copyWith(themeMode: value.first)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reduced motion'),
              value: settings.reducedMotion,
              onChanged: (value) =>
                  controller.update(settings.copyWith(reducedMotion: value)),
            ),
            const _Heading('Playback'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto play last station'),
              value: settings.autoPlay,
              onChanged: (value) =>
                  controller.update(settings.copyWith(autoPlay: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto reconnect'),
              value: settings.autoReconnect,
              onChanged: (value) =>
                  controller.update(settings.copyWith(autoReconnect: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Background playback'),
              value: settings.backgroundPlayback,
              onChanged: (value) => controller.update(
                settings.copyWith(backgroundPlayback: value),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Default station scope'),
              subtitle: const Text('Used by the tuner and Previous / Next'),
              trailing: DropdownButton<String>(
                value: settings.defaultScope,
                items: const [
                  DropdownMenuItem(value: 'city', child: Text('City')),
                  DropdownMenuItem(value: 'state', child: Text('State')),
                  DropdownMenuItem(value: 'country', child: Text('Country')),
                  DropdownMenuItem(
                    value: 'worldwide',
                    child: Text('Worldwide'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.update(settings.copyWith(defaultScope: value));
                  }
                },
              ),
            ),
            const _Heading('Network'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Wi-Fi only'),
              subtitle: const Text(
                'Live streams are blocked on mobile data when enabled.',
              ),
              value: settings.wifiOnly,
              onChanged: (value) =>
                  controller.update(settings.copyWith(wifiOnly: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Prefer lower bitrate on mobile'),
              subtitle: const Text(
                'Chooses a real lower-bitrate alternative on mobile; Wi-Fi keeps the best-ranked stream.',
              ),
              value: settings.preferLowerBitrate,
              onChanged: (value) => controller.update(
                settings.copyWith(preferLowerBitrate: value),
              ),
            ),
            const _Heading('Recording'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Default recording format'),
              subtitle: const Text(
                'Original avoids quality loss; MP3/M4A transcode only when required.',
              ),
              trailing: DropdownButton<String>(
                value: settings.recordingFormat,
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('Original')),
                  DropdownMenuItem(value: 'mp3', child: Text('MP3')),
                  DropdownMenuItem(value: 'm4a', child: Text('M4A')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.update(
                      settings.copyWith(recordingFormat: value),
                    );
                  }
                },
              ),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Default recording directory'),
              subtitle: Text(
                'Private app storage. Use Export / Save to Downloads to choose a public location.',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Scheduled recordings'),
              subtitle: const Text(
                'Policy-aware reminders and prepared recording actions',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/schedules'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Radio alarm'),
              subtitle: const Text('Wake with a station action'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/alarm'),
            ),
            const _Heading('History & storage'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Clear listening history'),
              onTap: () async {
                await ref.read(databaseProvider).clearHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Listening history cleared.')),
                  );
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Clear recent searches'),
              onTap: () async {
                await ref.read(preferencesProvider).remove('recentSearches');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recent searches cleared.')),
                  );
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Refresh catalogue cache'),
              onTap: () async {
                await ref.read(catalogueRepositoryProvider).refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Catalogue refreshed.')),
                  );
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Clear catalogue cache'),
              subtitle: const Text('Keeps favourites and custom stations'),
              onTap: () async {
                await ref.read(databaseProvider).clearCatalogueCache();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Catalogue cache cleared.')),
                  );
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Clear recording temp files'),
              onTap: () async {
                final count = await ref
                    .read(recordingServiceProvider)
                    .clearTemporaryFiles();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$count temporary files removed.')),
                  );
                }
              },
            ),
            const _Heading('Data'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Export backup'),
              subtitle: const Text(
                'Favourites, custom stations, and history as JSON',
              ),
              onTap: () => _export(context, ref),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Import backup'),
              subtitle: const Text('Validates Dhwani JSON before importing'),
              onTap: () => _import(context, ref),
            ),
            const _Heading('About'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const BrandMark(size: 42),
              title: const Text('Dhwani'),
              subtitle: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) => Text(
                  'Version ${snapshot.data?.version ?? '…'} · Real radio from your city and the world.',
                ),
              ),
              onTap: () => _about(context),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.system_update_rounded),
              title: const Text('Check for updates'),
              subtitle: const Text('Check GitHub Releases for new version'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Checking for updates…'),
                    duration: Duration(seconds: 1),
                  ),
                );
                final updater = ref.read(appUpdateServiceProvider);
                final result = await updater.checkForUpdate();
                if (!context.mounted) return;
                if (result case UpdateAvailable(:final release)) {
                  AppUpdateSheet.show(
                    context,
                    release: release,
                    updateService: updater,
                  );
                } else if (result is UpdateUpToDate) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('You are on the latest version of Dhwani!'),
                    ),
                  );
                } else {
                  final message = switch (result) {
                    UpdateCheckFailed(:final message) => message,
                    UpdateCheckSkipped(:final message) => message,
                    _ => 'The update check could not be completed.',
                  };
                  messenger.showSnackBar(SnackBar(content: Text(message)));
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open-source licences'),
              onTap: () async {
                final info = await PackageInfo.fromPlatform();
                if (!context.mounted) return;
                showLicensePage(
                  context: context,
                  applicationName: 'Dhwani',
                  applicationVersion: '${info.version}+${info.buildNumber}',
                  applicationIcon: const BrandMark(size: 52),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final decoded =
        jsonDecode(await ref.read(databaseProvider).exportUserData())
            as Map<String, Object?>;
    decoded['settings'] = ref.read(settingsProvider).toJson();
    final data = const JsonEncoder.withIndent('  ').convert(decoded);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(data),
            mimeType: 'application/json',
            name: 'dhwani-backup.json',
          ),
        ],
        fileNameOverrides: const ['dhwani-backup.json'],
        text: 'Dhwani local data backup',
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    const types = XTypeGroup(
      label: 'Dhwani backup',
      extensions: ['json'],
      mimeTypes: ['application/json'],
    );
    final file = await openFile(acceptedTypeGroups: const [types]);
    if (file == null) return;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map ||
          decoded['format'] != 'dhwani-backup' ||
          decoded['version'] != 1 ||
          decoded['stations'] is! List) {
        throw const FormatException('Not a supported Dhwani backup');
      }
      for (final item in (decoded['stations'] as List).whereType<Map>()) {
        final payload = item['payload'];
        if (payload is! Map) continue;
        final station = RadioStation.fromJson(payload.cast<String, Object?>());
        if (station.id.isEmpty || station.name.trim().isEmpty) continue;
        if (item['custom'] == true) {
          await ref.read(databaseProvider).saveCustomStation(station);
        }
        if (item['favourite'] == true) {
          await ref.read(databaseProvider).setFavourite(station, true);
        }
      }
      for (final item
          in (decoded['history'] as List? ?? const []).whereType<Map>()) {
        final stationJson = item['station'];
        final playedAt = DateTime.tryParse('${item['playedAt'] ?? ''}');
        if (stationJson is! Map || playedAt == null) continue;
        final station = RadioStation.fromJson(
          stationJson.cast<String, Object?>(),
        );
        await ref
            .read(databaseProvider)
            .importHistory(
              station,
              playedAt,
              duration: Duration(
                seconds: (item['durationSeconds'] as num?)?.toInt() ?? 0,
              ),
            );
      }
      for (final item
          in (decoded['collections'] as List? ?? const []).whereType<Map>()) {
        final id = '${item['id'] ?? ''}'.trim();
        final name = '${item['name'] ?? ''}'.trim();
        if (id.isEmpty || name.isEmpty) continue;
        await ref.read(databaseProvider).createCollection(id, name);
        for (final stationJson in (item['stations'] as List? ?? const [])) {
          if (stationJson is! Map) continue;
          final station = RadioStation.fromJson(
            stationJson.cast<String, Object?>(),
          );
          if (station.id.isNotEmpty) {
            await ref.read(databaseProvider).addToCollection(id, station);
          }
        }
      }
      final settingsJson = decoded['settings'];
      if (settingsJson is Map) {
        final current = ref.read(settingsProvider);
        await ref
            .read(settingsProvider.notifier)
            .update(
              DhwaniSettings.fromJson(
                settingsJson.cast<String, Object?>(),
                fallback: current,
              ),
            );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup imported.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import rejected: $error')));
      }
    }
  }

  Future<void> _about(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'Dhwani',
      applicationVersion: '${info.version}+${info.buildNumber}',
      applicationIcon: const BrandMark(size: 56),
      children: const [
        Text(
          'Live playback uses internet streams. A displayed AM/FM frequency is terrestrial metadata; your phone does not receive distant RF.',
        ),
        SizedBox(height: 12),
        Text(
          'Sources: Radio Browser community directory and Akashvani discovery metadata. Personal usage data stays on this device.',
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key, required this.alarm});
  final bool alarm;

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final repeatWeekdays = <int>{};
  int recordingMinutes = 30;
  double alarmVolume = .65;

  @override
  Widget build(BuildContext context) {
    final station = ref.watch(selectedStationProvider);
    final alarm = widget.alarm;
    return Scaffold(
      appBar: AppBar(
        title: Text(alarm ? 'Radio Alarm' : 'Scheduled Recording'),
        actions: [
          IconButton(
            tooltip: 'Cancel all reminders',
            onPressed: () async {
              await ref.read(notificationServiceProvider).cancelAllReminders();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All reminders cancelled.')),
                );
              }
            },
            icon: const Icon(Icons.notifications_off_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              alarm ? 'Wake with radio' : 'Prepare a recording',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Text(
              station == null
                  ? 'Choose a station in the player first.'
                  : 'Station: ${station.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text('Repeat', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final weekday = index + 1;
                return FilterChip(
                  label: Text(_dayLabels[index]),
                  selected: repeatWeekdays.contains(weekday),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      repeatWeekdays.add(weekday);
                    } else {
                      repeatWeekdays.remove(weekday);
                    }
                  }),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              repeatWeekdays.isEmpty ? 'One time' : 'Repeats on selected days',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!alarm) ...[
              const SizedBox(height: 20),
              Text(
                'Planned duration',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 15, label: Text('15m')),
                  ButtonSegment(value: 30, label: Text('30m')),
                  ButtonSegment(value: 60, label: Text('60m')),
                ],
                selected: {recordingMinutes},
                onSelectionChanged: (value) =>
                    setState(() => recordingMinutes = value.first),
              ),
            ] else ...[
              const SizedBox(height: 20),
              Text(
                'Prepared player volume',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: alarmVolume,
                divisions: 10,
                label: '${(alarmVolume * 100).round()}%',
                onChanged: (value) => setState(() => alarmVolume = value),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Android delivers a visible reminder. Tap it to open the prepared station action. This avoids promising a silent background launch that battery policy or foreground-service rules may block.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: station == null ? null : () => _schedule(station),
              icon: Icon(alarm ? Icons.alarm_add : Icons.event_available),
              label: Text(alarm ? 'Set alarm reminder' : 'Schedule reminder'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _schedule(RadioStation station) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final notifications = ref.read(notificationServiceProvider);
    final permission = await notifications.requestPermission();
    if (!permission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission is required for reminders.'),
          ),
        );
      }
      return;
    }
    await notifications.scheduleReminder(
      station: station,
      at: scheduled,
      alarm: widget.alarm,
      repeatWeekdays: repeatWeekdays,
      recordingDuration: widget.alarm
          ? null
          : Duration(minutes: recordingMinutes),
      preparedVolume: widget.alarm ? alarmVolume : null,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.alarm ? 'Alarm' : 'Recording'} reminder scheduled for ${time.format(context)}${repeatWeekdays.isEmpty ? '' : ' on ${repeatWeekdays.length} selected day(s)'}.',
        ),
      ),
    );
  }
}
