import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/platform/platform_files.dart';
import '../../core/widgets/dhwani_shell.dart';
import '../../data/models/radio_station.dart';
import '../../data/models/recording_entry.dart';

class RecordingsScreen extends ConsumerWidget {
  const RecordingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordings = ref.watch(recordingsProvider);
    return DhwaniShell(
      title: 'Recordings',
      child: recordings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Recordings could not be loaded.')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fiber_manual_record_outlined, size: 50),
                    const SizedBox(height: 14),
                    Text(
                      'No recordings yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          }
          final total = items.fold<int>(0, (sum, item) => sum + item.sizeBytes);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Recording storage used: ${_size(total)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return _RecordingTile(entry: items[index - 1]);
            },
          );
        },
      ),
    );
  }
}

class _RecordingTile extends ConsumerWidget {
  const _RecordingTile({required this.entry});
  final RecordingEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    leading: IconButton(
      tooltip: 'Play recording',
      icon: const Icon(Icons.play_arrow_rounded),
      onPressed: () async {
        if (!await File(entry.path).exists()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recording file is missing.')),
            );
          }
          return;
        }
        final station = RadioStation(
          id: 'recording:${entry.id}',
          name: entry.name,
          country: entry.station.country,
          countryCode: entry.station.countryCode,
          band: RadioBand.net,
          streams: [StationStream(url: Uri.file(entry.path).toString())],
          directory: RadioDirectory.custom,
          sourceType: RadioSourceType.localRecording,
        );
        await ref.read(audioHandlerProvider).setQueueStations([
          station,
        ], selected: station);
        await ref
            .read(audioHandlerProvider)
            .selectStation(station, autoplay: true);
        if (context.mounted) {
          _showRecordingPlayer(context, ref, entry);
        }
      },
    ),
    title: Text(
      entry.station.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      '${entry.createdAt.toLocal()} · ${_duration(entry.duration)} · ${entry.sizeLabel} · ${entry.format.toUpperCase()}',
    ),
    trailing: PopupMenuButton<String>(
      onSelected: (action) => _action(context, ref, action),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'share', child: Text('Share')),
        PopupMenuItem(
          value: 'export',
          child: Text('Export / Save to Downloads'),
        ),
        PopupMenuItem(value: 'details', child: Text('Details')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    ),
  );

  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final mime = switch (entry.format) {
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'ogg' => 'audio/ogg',
      _ => 'audio/x-matroska',
    };
    switch (action) {
      case 'share':
        await PlatformFiles.share(entry.path, entry.name, mime);
      case 'export':
        final saved = await PlatformFiles.export(entry.path, entry.name, mime);
        if (context.mounted && saved) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Recording exported.')));
        }
      case 'rename':
        final controller = TextEditingController(text: entry.name);
        final name = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Rename recording'),
            content: TextField(controller: controller, autofocus: true),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Rename'),
              ),
            ],
          ),
        );
        if (name != null && name.trim().isNotEmpty) {
          await ref.read(databaseProvider).renameRecording(entry.id, name);
        }
      case 'details':
        if (context.mounted) {
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (context) => Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    'Path: ${entry.path}\nDuration: ${_duration(entry.duration)}\nSize: ${entry.sizeLabel}\nFormat: ${entry.format.toUpperCase()}',
                  ),
                ],
              ),
            ),
          );
        }
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete recording?'),
            content: const Text(
              'This removes the audio file from this device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          final file = File(entry.path);
          if (await file.exists()) await file.delete();
          await ref.read(databaseProvider).deleteRecording(entry.id);
        }
    }
  }
}

void _showRecordingPlayer(
  BuildContext context,
  WidgetRef ref,
  RecordingEntry entry,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _RecordingPlayer(entry: entry),
  );
}

class _RecordingPlayer extends ConsumerWidget {
  const _RecordingPlayer({required this.entry});
  final RecordingEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(playerSnapshotProvider).value;
    final playing = snapshot?.status.name == 'playing';
    final handler = ref.read(audioHandlerProvider);
    final maximum = entry.duration.inMilliseconds
        .toDouble()
        .clamp(1, double.infinity)
        .toDouble();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: StreamBuilder<PlaybackState>(
          stream: handler.playbackState,
          builder: (context, state) {
            final position = (state.data?.updatePosition.inMilliseconds ?? 0)
                .toDouble()
                .clamp(0, maximum)
                .toDouble();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.graphic_eq_rounded, size: 48),
                const SizedBox(height: 12),
                Text(
                  entry.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(entry.station.name),
                const SizedBox(height: 18),
                Slider(
                  value: position,
                  max: maximum,
                  label: _duration(Duration(milliseconds: position.round())),
                  onChanged: (value) =>
                      handler.seek(Duration(milliseconds: value.round())),
                ),
                Row(
                  children: [
                    Text(_duration(Duration(milliseconds: position.round()))),
                    const Spacer(),
                    Text(_duration(entry.duration)),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => playing ? handler.pause() : handler.play(),
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(playing ? 'Pause' : 'Play'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _size(int bytes) => bytes >= 1024 * 1024
    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
    : '${(bytes / 1024).toStringAsFixed(0)} KB';
String _duration(Duration value) =>
    '${value.inMinutes.toString().padLeft(2, '0')}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';
