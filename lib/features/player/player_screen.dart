import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme/dhwani_theme.dart';
import '../../core/audio/dhwani_audio_handler.dart';
import '../../core/recording/recording_service.dart';
import '../../core/widgets/dhwani_shell.dart';
import '../../data/models/radio_station.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _restored = false;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(stationsProvider).value ?? const <RadioStation>[];
    var station = ref.watch(selectedStationProvider);
    if (!_restored && station == null && all.isNotEmpty) {
      _restored = true;
      final encoded = ref.read(preferencesProvider).getString('lastStation');
      RadioStation? restored;
      if (encoded != null) {
        try {
          restored = RadioStation.decode(encoded);
        } catch (_) {}
      }
      restored ??=
          all.where((item) => item.isDarbhanga).firstOrNull ?? all.first;
      final value = restored;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        ref.read(selectedStationProvider.notifier).select(value);
        final queue = tuningQueue(all, current: value);
        await ref
            .read(audioHandlerProvider)
            .setQueueStations(queue, selected: value);
        await ref.read(audioHandlerProvider).selectStation(value);
      });
      station = restored;
    }
    if (station == null) {
      return DhwaniShell(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.radio_outlined, size: 54),
              const SizedBox(height: 16),
              Text(
                'Choose a station',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/countries'),
                child: const Text('Browse countries'),
              ),
            ],
          ),
        ),
      );
    }
    final snapshot =
        ref.watch(playerSnapshotProvider).value ??
        DhwaniPlayerSnapshot(
          status: DhwaniPlaybackStatus.ready,
          station: station,
        );
    final recording =
        ref.watch(recordingSnapshotProvider).value ??
        const RecordingSnapshot(status: RecordingStatus.idle);
    final band = ref.watch(bandFilterProvider);
    final queue = tuningQueue(all, current: station, band: band);
    return DhwaniShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 680 ||
              constraints.maxWidth > constraints.maxHeight;
          final content = _PlayerContent(
            station: station!,
            snapshot: snapshot,
            recording: recording,
            queue: queue,
            compact: compact,
          );
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, compact ? 10 : 18, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayerContent extends ConsumerWidget {
  const _PlayerContent({
    required this.station,
    required this.snapshot,
    required this.recording,
    required this.queue,
    required this.compact,
  });
  final RadioStation station;
  final DhwaniPlayerSnapshot snapshot;
  final RecordingSnapshot recording;
  final List<RadioStation> queue;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = snapshot.status == DhwaniPlaybackStatus.playing;
    final busy =
        snapshot.status == DhwaniPlaybackStatus.loading ||
        snapshot.status == DhwaniPlaybackStatus.buffering ||
        snapshot.status == DhwaniPlaybackStatus.reconnecting;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Browse stations',
              onPressed: () => context.push('/countries'),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                station.city ?? station.state ?? station.country,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
            _BandMenu(station: station),
            IconButton(
              tooltip: 'Station information',
              onPressed: () => showStationInfo(context, ref, station, snapshot),
              icon: const Icon(Icons.info_outline_rounded),
            ),
          ],
        ),
        SizedBox(height: compact ? 12 : 32),
        Semantics(
          header: true,
          label: '${station.frequencyDisplay} ${station.frequencySubtitle}',
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  station.frequencyDisplay.padLeft(
                    station.frequency == null ? 0 : 4,
                    '0',
                  ),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: compact ? 66 : 92,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                station.frequencySubtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: .45),
                ),
              ),
              const SizedBox(height: 13),
              Text(
                station.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (station.languages.isNotEmpty)
                Text(
                  station.languages.join(', '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              _StatusPill(snapshot: snapshot),
            ],
          ),
        ),
        SizedBox(height: compact ? 14 : 28),
        TunerScale(
          stations: queue,
          current: station,
          height: compact ? 118 : 164,
          onStation: (next) async {
            HapticFeedback.selectionClick();
            ref.read(selectedStationProvider.notifier).select(next);
            await ref
                .read(audioHandlerProvider)
                .setQueueStations(queue, selected: next);
            await ref
                .read(audioHandlerProvider)
                .selectStation(next, autoplay: playing);
            await ref.read(catalogueRepositoryProvider).addHistory(next);
          },
        ),
        SizedBox(height: compact ? 14 : 28),
        if (snapshot.icyTitle != null) ...[
          Text(
            snapshot.icyTitle!,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
        ] else ...[
          Text('Live broadcast', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: _TransportButton(
                tooltip: 'Previous station',
                icon: Icons.skip_previous_rounded,
                onPressed: () async {
                  await ref.read(audioHandlerProvider).skipToPrevious();
                  final current = ref.read(audioHandlerProvider).currentStation;
                  if (current != null) {
                    ref.read(selectedStationProvider.notifier).select(current);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                key: const Key('player-play-pause'),
                onPressed: busy
                    ? null
                    : () => playing
                          ? ref.read(audioHandlerProvider).pause()
                          : ref.read(audioHandlerProvider).play(),
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(compact ? 62 : 74),
                  backgroundColor: playing
                      ? Theme.of(context).colorScheme.onSurface
                      : DhwaniColors.signal,
                  foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                icon: busy
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                label: Text(
                  busy
                      ? _statusLabel(snapshot.status)
                      : playing
                      ? 'Pause'
                      : snapshot.status == DhwaniPlaybackStatus.error
                      ? 'Retry'
                      : 'Play live',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TransportButton(
                tooltip: 'Next station',
                icon: Icons.skip_next_rounded,
                onPressed: () async {
                  await ref.read(audioHandlerProvider).skipToNext();
                  final current = ref.read(audioHandlerProvider).currentStation;
                  if (current != null) {
                    ref.read(selectedStationProvider.notifier).select(current);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FavouriteButton(station: station),
            _RecordButton(
              station: station,
              snapshot: snapshot,
              recording: recording,
            ),
            IconButton(
              tooltip: 'More actions',
              onPressed: () => _showMore(context, ref),
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
        ),
        if (recording.status == RecordingStatus.recording)
          Text(
            '● REC  ${_duration(recording.elapsed)}',
            style: const TextStyle(
              color: DhwaniColors.signal,
              fontWeight: FontWeight.w800,
            ),
          ),
        if (snapshot.status == DhwaniPlaybackStatus.error) ...[
          const SizedBox(height: 12),
          Text(
            snapshot.message ?? 'Station isn’t responding.',
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () => ref.read(audioHandlerProvider).skipToNext(),
            child: const Text('Try next station'),
          ),
        ],
      ],
    );
  }

  Future<void> _showMore(
    BuildContext context,
    WidgetRef ref,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Sleep timer'),
            onTap: () {
              Navigator.pop(context);
              _showSleepTimer(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.volume_up_outlined),
            title: const Text('Player volume'),
            onTap: () {
              Navigator.pop(context);
              _showVolume(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Station info'),
            onTap: () {
              Navigator.pop(context);
              showStationInfo(context, ref, station, snapshot);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share station'),
            onTap: () async {
              Navigator.pop(context);
              await SharePlus.instance.share(
                ShareParams(
                  text:
                      '${station.name}\n${station.city ?? station.state ?? station.country}\n${station.frequencyDisplay} ${station.frequencySubtitle}\n${station.homepage ?? ''}',
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.content_copy),
            title: const Text('Copy stream URL'),
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text:
                      snapshot.stream?.url ??
                      station.streams.firstOrNull?.url ??
                      '',
                ),
              );
              Navigator.pop(context);
            },
          ),
          if (station.homepage != null)
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open station website'),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.tryParse(station.homepage!);
                if (uri != null) await launchUrl(uri);
              },
            ),
          ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: const Text('Car mode'),
            onTap: () {
              Navigator.pop(context);
              context.push('/car');
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_outlined),
            title: const Text('Report broken'),
            onTap: () async {
              await ref.read(databaseProvider).reportBroken(station.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          if (station.userAdded) ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit custom station'),
              onTap: () {
                Navigator.pop(context);
                context.push('/custom-station', extra: station);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: const Text('Duplicate station'),
              onTap: () {
                Navigator.pop(context);
                context.push('/custom-station?duplicate=true', extra: station);
              },
            ),
          ],
        ],
      ),
    ),
  );
}

class _BandMenu extends ConsumerWidget {
  const _BandMenu({required this.station});
  final RadioStation station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(bandFilterProvider);
    return PopupMenuButton<RadioBand?>(
      tooltip: 'Band filter',
      initialValue: selected,
      onSelected: (value) => ref.read(bandFilterProvider.notifier).set(value),
      itemBuilder: (_) => const [
        PopupMenuItem(value: null, child: Text('All')),
        PopupMenuItem(value: RadioBand.am, child: Text('AM')),
        PopupMenuItem(value: RadioBand.fm, child: Text('FM')),
        PopupMenuItem(value: RadioBand.net, child: Text('NET')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          selected?.name.toUpperCase() ?? station.bandLabel,
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.snapshot});
  final DhwaniPlayerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final live = snapshot.status == DhwaniPlaybackStatus.playing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live
                ? DhwaniColors.online
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: .35),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          _statusLabel(snapshot.status).toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
            color: live ? DhwaniColors.online : null,
          ),
        ),
      ],
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(height: 74, child: Icon(icon)),
      ),
    ),
  );
}

class _FavouriteButton extends ConsumerStatefulWidget {
  const _FavouriteButton({required this.station});
  final RadioStation station;

  @override
  ConsumerState<_FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends ConsumerState<_FavouriteButton> {
  bool value = false;

  @override
  void initState() {
    super.initState();
    ref.read(databaseProvider).isFavourite(widget.station.id).then((result) {
      if (mounted) setState(() => value = result);
    });
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: value ? 'Remove favourite' : 'Save favourite',
    onPressed: () async {
      final next = !value;
      await ref
          .read(catalogueRepositoryProvider)
          .favourite(widget.station, next);
      HapticFeedback.lightImpact();
      if (mounted) setState(() => value = next);
    },
    icon: Icon(
      value ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
      color: value ? DhwaniColors.signal : null,
    ),
  );
}

class _RecordButton extends ConsumerWidget {
  const _RecordButton({
    required this.station,
    required this.snapshot,
    required this.recording,
  });
  final RadioStation station;
  final DhwaniPlayerSnapshot snapshot;
  final RecordingSnapshot recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active =
        recording.status == RecordingStatus.recording ||
        recording.status == RecordingStatus.stopping;
    return IconButton(
      tooltip: active ? 'Stop recording' : 'Record live stream',
      onPressed: () async {
        try {
          if (active) {
            await ref.read(recordingServiceProvider).stop();
            HapticFeedback.mediumImpact();
          } else {
            final stream = snapshot.stream ?? station.rankedStreams.firstOrNull;
            if (stream == null) throw StateError('No stream mapped');
            await ref.read(recordingServiceProvider).start(station, stream);
            HapticFeedback.mediumImpact();
          }
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$error')));
          }
        }
      },
      icon: Icon(
        active
            ? Icons.stop_circle_outlined
            : Icons.fiber_manual_record_outlined,
        color: active ? DhwaniColors.signal : null,
      ),
    );
  }
}

class TunerScale extends StatefulWidget {
  const TunerScale({
    super.key,
    required this.stations,
    required this.current,
    required this.onStation,
    this.height = 164,
  });
  final List<RadioStation> stations;
  final RadioStation current;
  final ValueChanged<RadioStation> onStation;
  final double height;

  @override
  State<TunerScale> createState() => _TunerScaleState();
}

class _TunerScaleState extends State<TunerScale> {
  double drag = 0;

  @override
  Widget build(BuildContext context) {
    final current = math.max(
      0,
      widget.stations.indexWhere((item) => item.id == widget.current.id),
    );
    final next = math.min(widget.stations.length - 1, current + 1);
    final previous = math.max(0, current - 1);
    return Semantics(
      label: 'Radio tuner. Swipe left or right to choose a station.',
      value: widget.current.name,
      increasedValue: widget.stations.isEmpty
          ? widget.current.name
          : widget.stations[next].name,
      decreasedValue: widget.stations.isEmpty
          ? widget.current.name
          : widget.stations[previous].name,
      onIncrease: () => _step(1),
      onDecrease: () => _step(-1),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) =>
            setState(() => drag += details.delta.dx),
        onHorizontalDragEnd: (details) {
          final delta =
              (-drag / 54 - details.velocity.pixelsPerSecond.dx / 1200).round();
          setState(() => drag = 0);
          if (delta != 0) _step(delta);
        },
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            painter: _TunerPainter(
              color: Theme.of(context).colorScheme.onSurface,
              signal: DhwaniColors.signal,
              index: math.max(
                0,
                widget.stations.indexWhere(
                  (item) => item.id == widget.current.id,
                ),
              ),
              count: math.max(1, widget.stations.length),
              drag: drag,
              band: widget.current.band,
              frequencies: widget.stations
                  .map((station) => station.frequency)
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _step(int amount) {
    if (widget.stations.isEmpty) return;
    final current = math.max(
      0,
      widget.stations.indexWhere((item) => item.id == widget.current.id),
    );
    final next = (current + amount).clamp(0, widget.stations.length - 1);
    if (next != current) widget.onStation(widget.stations[next]);
  }
}

class _TunerPainter extends CustomPainter {
  const _TunerPainter({
    required this.color,
    required this.signal,
    required this.index,
    required this.count,
    required this.drag,
    required this.band,
    required this.frequencies,
  });
  final Color color;
  final Color signal;
  final int index;
  final int count;
  final double drag;
  final RadioBand band;
  final List<double?> frequencies;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.width / 2;
    final tick = Paint()
      ..color = color.withValues(alpha: .16)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = color.withValues(alpha: .28)
      ..strokeWidth = 1.5;
    const spacing = 8.0;
    final shift = drag % spacing;
    for (var i = -70; i <= 70; i++) {
      final x = centre + i * spacing + shift;
      if (x < 0 || x > size.width) continue;
      final absolute = i + index * 10;
      final big = absolute % 10 == 0;
      final medium = absolute % 5 == 0;
      final height = big
          ? 46.0
          : medium
          ? 32.0
          : 19.0;
      canvas.drawLine(
        Offset(x, size.height * .43 - height / 2),
        Offset(x, size.height * .43 + height / 2),
        big || medium ? major : tick,
      );
    }
    final needle = Paint()
      ..color = signal
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centre, 10),
      Offset(centre, size.height - 18),
      needle,
    );
    final label = band == RadioBand.net
        ? '${index + 1} / $count'
        : frequencies.elementAtOrNull(index)?.toString() ?? 'STATIONS';
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color.withValues(alpha: .46),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(centre - painter.width / 2, size.height - 14));
  }

  @override
  bool shouldRepaint(covariant _TunerPainter oldDelegate) =>
      oldDelegate.index != index ||
      oldDelegate.drag != drag ||
      oldDelegate.color != color ||
      oldDelegate.count != count;
}

void showStationInfo(
  BuildContext context,
  WidgetRef ref,
  RadioStation station,
  DhwaniPlayerSnapshot snapshot,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Text(station.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          ...<String, String>{
            'Country': station.country,
            if (station.state != null) 'State': station.state!,
            if (station.city != null) 'City': station.city!,
            'Languages': station.languages.join(', '),
            'Band': station.bandLabel,
            'Frequency': station.frequency == null
                ? 'Internet-only'
                : '${station.frequencyDisplay} ${station.frequencyUnit}',
            'Codec': snapshot.stream?.codec ?? 'Not reported',
            'Bitrate': snapshot.stream?.bitrate == null
                ? 'Not reported'
                : '${snapshot.stream!.bitrate} kbps',
            'Stream type': snapshot.stream?.hls == true
                ? 'HLS'
                : 'Direct stream',
            'Directory': station.directory.name,
            'Health': station.health.name,
            'Current URL':
                snapshot.stream?.url ??
                station.streams.firstOrNull?.url ??
                'None',
            'Alternative URLs': station.streams.length <= 1
                ? 'None'
                : station.streams.skip(1).map((value) => value.url).join('\n'),
            'Last successful playback':
                station.lastSuccessfulPlayback?.toLocal().toString() ??
                'Not recorded yet',
          }.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(child: SelectableText(entry.value)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(audioHandlerProvider).retry();
            },
            child: const Text('Retry station'),
          ),
        ],
      ),
    ),
  );
}

void _showSleepTimer(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sleep timer',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [15, 30, 45, 60, 90]
                  .map(
                    (minutes) => ActionChip(
                      label: Text('$minutes min'),
                      onPressed: () {
                        ref
                            .read(sleepTimerProvider.notifier)
                            .start(Duration(minutes: minutes));
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final controller = TextEditingController();
                      final minutes = await showDialog<int>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Custom sleep timer'),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Minutes',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(
                                context,
                                int.tryParse(controller.text),
                              ),
                              child: const Text('Set'),
                            ),
                          ],
                        ),
                      );
                      controller.dispose();
                      if (minutes == null || minutes <= 0) return;
                      ref
                          .read(sleepTimerProvider.notifier)
                          .start(Duration(minutes: minutes));
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Custom'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          now.add(const Duration(minutes: 30)),
                        ),
                      );
                      if (time == null) return;
                      var end = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        time.hour,
                        time.minute,
                      );
                      if (!end.isAfter(now)) {
                        end = end.add(const Duration(days: 1));
                      }
                      ref
                          .read(sleepTimerProvider.notifier)
                          .start(end.difference(now));
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('End at…'),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                ref.read(sleepTimerProvider.notifier).cancel();
                Navigator.pop(context);
              },
              child: const Text('Cancel active timer'),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showVolume(BuildContext context, WidgetRef ref) {
  var value = ref.read(audioHandlerProvider).volume;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            children: [
              const Icon(Icons.volume_down),
              Expanded(
                child: Slider(
                  value: value,
                  onChanged: (next) {
                    setState(() => value = next);
                    ref.read(audioHandlerProvider).setVolume(next);
                  },
                ),
              ),
              const Icon(Icons.volume_up),
            ],
          ),
        ),
      ),
    ),
  );
}

String _statusLabel(DhwaniPlaybackStatus status) => switch (status) {
  DhwaniPlaybackStatus.idle => 'Ready',
  DhwaniPlaybackStatus.loading => 'Connecting…',
  DhwaniPlaybackStatus.ready => 'Ready',
  DhwaniPlaybackStatus.buffering => 'Buffering…',
  DhwaniPlaybackStatus.playing => 'Live',
  DhwaniPlaybackStatus.paused => 'Paused',
  DhwaniPlaybackStatus.reconnecting => 'Reconnecting…',
  DhwaniPlaybackStatus.error => 'Unavailable',
};

String _duration(Duration duration) =>
    '${duration.inHours > 0 ? '${duration.inHours.toString().padLeft(2, '0')}:' : ''}${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
