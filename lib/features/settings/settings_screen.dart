import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/settings/settings_controller.dart';
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
                'Used only when a station exposes real alternatives.',
              ),
              value: settings.preferLowerBitrate,
              onChanged: (value) => controller.update(
                settings.copyWith(preferLowerBitrate: value),
              ),
            ),
            const _Heading('Recording'),
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
              subtitle: const Text(
                'Version 1.0.0 · Real radio from your city and the world.',
              ),
              onTap: () => _about(context),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open-source licences'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Dhwani',
                applicationVersion: '1.0.0',
                applicationIcon: const BrandMark(size: 52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final data = await ref.read(databaseProvider).exportUserData();
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

  void _about(BuildContext context) => showAboutDialog(
    context: context,
    applicationName: 'Dhwani',
    applicationVersion: '1.0.0',
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

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key, required this.alarm});
  final bool alarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(selectedStationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(alarm ? 'Radio Alarm' : 'Scheduled Recording'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              const Text(
                'Modern Android may require a notification tap before playback or recording can start. Dhwani uses a visible, policy-compliant reminder instead of promising a silent background launch that the OS may block.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: station == null
                    ? null
                    : () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null && context.mounted) {
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
                          final notifications = ref.read(
                            notificationServiceProvider,
                          );
                          final permission = await notifications
                              .requestPermission();
                          if (!permission) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Notification permission is required for reminders.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          await notifications.scheduleReminder(
                            station: station,
                            at: scheduled,
                            alarm: alarm,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${alarm ? 'Alarm' : 'Recording reminder'} scheduled for ${time.format(context)}.',
                              ),
                            ),
                          );
                        }
                      },
                icon: Icon(alarm ? Icons.alarm_add : Icons.event_available),
                label: Text(alarm ? 'Set alarm reminder' : 'Schedule reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
