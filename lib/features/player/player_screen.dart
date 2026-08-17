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
import '../../core/settings/settings_controller.dart';
import '../../core/widgets/dhwani_dropdown.dart';
import '../../core/widgets/dhwani_shell.dart';
import '../../data/models/radio_station.dart';
import 'sleep_timer_sheet.dart';

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
        final queue = tuningQueue(
          all,
          current: value,
          preferredScope: ref.read(settingsProvider).defaultScope,
        );
        await ref
            .read(audioHandlerProvider)
            .setQueueStations(queue, selected: value);
        await ref
            .read(audioHandlerProvider)
            .selectStation(
              value,
              autoplay: ref.read(settingsProvider).autoPlay,
            );
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
    final queue = tuningQueue(
      all,
      current: station,
      band: band,
      preferredScope: ref.watch(settingsProvider).defaultScope,
    );
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
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.1;
    final tight = compact && largeText;
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
              tooltip: 'More actions',
              onPressed: () => _showMore(context, ref),
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
        ),
        SizedBox(
          height: tight
              ? 4
              : compact
              ? 12
              : 32,
        ),
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
                    fontSize: tight
                        ? 56
                        : compact
                        ? 66
                        : 92,
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
              SizedBox(height: tight ? 5 : 13),
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
        SizedBox(
          height: tight
              ? 6
              : compact
              ? 14
              : 28,
        ),
        TunerScale(
          stations: queue,
          current: station,
          height: tight
              ? 72
              : compact
              ? 98
              : 164,
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
        SizedBox(
          height: tight
              ? 2
              : compact
              ? 8
              : 28,
        ),
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
                height: compact ? 64 : 78,
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
              child: _FavouriteButton(
                station: station,
                height: compact ? 64 : 78,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RecordButton(
                station: station,
                snapshot: snapshot,
                recording: recording,
                height: compact ? 64 : 78,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TransportButton(
                tooltip: 'Next station',
                icon: Icons.skip_next_rounded,
                height: compact ? 64 : 78,
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
        if (recording.status == RecordingStatus.recording) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: DhwaniColors.signal.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DhwaniColors.signal.withValues(alpha: .3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: DhwaniColors.signal,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'REC  ${_duration(recording.elapsed)}',
                  style: const TextStyle(
                    color: DhwaniColors.signal,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: compact ? 10 : 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('player-play-pause'),
            onPressed: busy
                ? null
                : () => playing
                      ? ref.read(audioHandlerProvider).pause()
                      : playWithMediaNotification(ref),
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 66 : 80),
              backgroundColor: playing
                  ? Theme.of(context).colorScheme.onSurface
                  : DhwaniColors.signal,
              foregroundColor: playing
                  ? Theme.of(context).scaffoldBackgroundColor
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              elevation: playing ? 0 : 3,
              shadowColor: DhwaniColors.signal.withValues(alpha: .35),
            ),
            icon: busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 28,
                  ),
            label: Text(
              busy
                  ? _statusLabel(snapshot.status)
                  : playing
                  ? 'Pause'
                  : snapshot.status == DhwaniPlaybackStatus.error
                  ? 'Retry'
                  : 'Play live',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
              ),
            ),
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
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
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
          if (ref.read(audioHandlerProvider).equalizerSupported)
            ListTile(
              leading: const Icon(Icons.equalizer_rounded),
              title: const Text('Equalizer'),
              onTap: () {
                Navigator.pop(context);
                _showEqualizer(context, ref);
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
  ),
);
}

class _BandMenu extends ConsumerWidget {
  const _BandMenu({required this.station});
  final RadioStation station;

  IconData _bandIcon(RadioBand? band) => switch (band) {
    RadioBand.fm => Icons.radio_rounded,
    RadioBand.am => Icons.sensors_rounded,
    RadioBand.net => Icons.wifi_rounded,
    null => Icons.tune_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(bandFilterProvider);
    final displayLabel = selected?.name.toUpperCase() ?? station.bandLabel;
    final currentIcon = _bandIcon(selected ?? station.band);

    return DhwaniDropdown<RadioBand?>(
      tooltip: 'Filter by source / band',
      value: selected,
      label: displayLabel,
      icon: currentIcon,
      onSelected: (value) {
        HapticFeedback.selectionClick();
        ref.read(bandFilterProvider.notifier).set(value);
      },
      items: const [
        DhwaniDropdownItem(
          value: null,
          label: 'All Bands',
          icon: Icons.tune_rounded,
        ),
        DhwaniDropdownItem(
          value: RadioBand.fm,
          label: 'FM Radio',
          icon: Icons.radio_rounded,
        ),
        DhwaniDropdownItem(
          value: RadioBand.am,
          label: 'AM Radio',
          icon: Icons.sensors_rounded,
        ),
        DhwaniDropdownItem(
          value: RadioBand.net,
          label: 'Internet (NET)',
          icon: Icons.wifi_rounded,
        ),
      ],
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
    this.height = 78,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: height,
          child: Center(child: Icon(icon, size: 26)),
        ),
      ),
    ),
  );
}

class _FavouriteButton extends ConsumerStatefulWidget {
  const _FavouriteButton({required this.station, this.height = 78});
  final RadioStation station;
  final double height;

  @override
  ConsumerState<_FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends ConsumerState<_FavouriteButton> {
  bool value = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void didUpdateWidget(covariant _FavouriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.station.id != widget.station.id) {
      _loadStatus();
    }
  }

  void _loadStatus() {
    ref.read(databaseProvider).isFavourite(widget.station.id).then((result) {
      if (mounted) setState(() => value = result);
    });
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: value ? 'Remove favourite' : 'Save favourite',
    child: Material(
      color: value
          ? DhwaniColors.signal.withValues(alpha: .12)
          : Theme.of(context).colorScheme.onSurface.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () async {
          final next = !value;
          await ref
              .read(catalogueRepositoryProvider)
              .favourite(widget.station, next);
          HapticFeedback.lightImpact();
          if (mounted) setState(() => value = next);
        },
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: widget.height,
          child: Center(
            child: Icon(
              value ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              color: value ? DhwaniColors.signal : null,
              size: 26,
            ),
          ),
        ),
      ),
    ),
  );
}

class _RecordButton extends ConsumerStatefulWidget {
  const _RecordButton({
    required this.station,
    required this.snapshot,
    required this.recording,
    this.height = 78,
  });
  final RadioStation station;
  final DhwaniPlayerSnapshot snapshot;
  final RecordingSnapshot recording;
  final double height;

  @override
  ConsumerState<_RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends ConsumerState<_RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _pulseAnimation = CurvedAnimation(
    parent: _pulseController,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();
    if (widget.recording.status == RecordingStatus.recording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recording.status == RecordingStatus.recording) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.recording.status;
    final isRecording = status == RecordingStatus.recording;
    final isBusy =
        status == RecordingStatus.starting ||
        status == RecordingStatus.stopping;
    final active = isRecording || isBusy;

    return Tooltip(
      message: active
          ? (isBusy ? 'Processing recording…' : 'Stop recording')
          : 'Record live broadcast',
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final pulseVal = isRecording ? _pulseAnimation.value : 0.0;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: isRecording
                  ? [
                      BoxShadow(
                        color: DhwaniColors.signal.withValues(
                          alpha: 0.25 + 0.25 * pulseVal,
                        ),
                        blurRadius: 10 + 6 * pulseVal,
                        spreadRadius: 1 + 2 * pulseVal,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: isRecording
                  ? DhwaniColors.signal.withValues(
                      alpha: 0.14 + 0.10 * pulseVal,
                    )
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: .08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isRecording
                    ? BorderSide(
                        color: DhwaniColors.signal.withValues(
                          alpha: 0.4 + 0.4 * pulseVal,
                        ),
                        width: 1.5,
                      )
                    : BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .04),
                        width: 1,
                      ),
              ),
              child: InkWell(
                onTap: isBusy
                    ? null
                    : () async {
                        try {
                          if (isRecording) {
                            HapticFeedback.heavyImpact();
                            await ref.read(recordingServiceProvider).stop();
                          } else {
                            final stream =
                                widget.snapshot.stream ??
                                widget.station.rankedStreams.firstOrNull;
                            if (stream == null) {
                              throw StateError('No stream mapped');
                            }
                            HapticFeedback.mediumImpact();
                            await ref
                                .read(recordingServiceProvider)
                                .start(widget.station, stream);
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$error')),
                            );
                          }
                        }
                      },
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: widget.height,
                  child: Center(
                    child: isBusy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: DhwaniColors.signal,
                            ),
                          )
                        : isRecording
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: DhwaniColors.signal.withValues(
                                    alpha: 0.15 + 0.15 * pulseVal,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.stop_rounded,
                                color: DhwaniColors.signal,
                                size: 26,
                              ),
                            ],
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.circle_outlined,
                                size: 26,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: .65),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: DhwaniColors.signal,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          );
        },
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
            'Last checked':
                station.lastChecked?.toLocal().toString() ?? 'Not checked yet',
            'Homepage': station.homepage ?? 'Not reported',
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: station.streams.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text:
                                snapshot.stream?.url ??
                                station.streams.first.url,
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Stream URL copied.')),
                          );
                        }
                      },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy URL'),
              ),
              if (station.streams.length > 1)
                OutlinedButton.icon(
                  onPressed: () async {
                    final current = snapshot.stream?.url;
                    final alternatives = [
                      ...station.streams.where(
                        (stream) => stream.url != current,
                      ),
                      ...station.streams.where(
                        (stream) => stream.url == current,
                      ),
                    ];
                    final alternate = station.copyWith(streams: alternatives);
                    await ref
                        .read(audioHandlerProvider)
                        .selectStation(alternate, autoplay: true);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Try alternative'),
                ),
              if (station.homepage != null)
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(station.homepage!);
                    if (uri != null) await launchUrl(uri);
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Website'),
                ),
              OutlinedButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${station.name}\n${station.country}\n${station.frequencyDisplay} ${station.frequencySubtitle}\n${station.homepage ?? ''}',
                  ),
                ),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(databaseProvider).reportBroken(station.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Broken report saved locally.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.report_outlined),
                label: const Text('Report broken'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void _showSleepTimer(BuildContext context, WidgetRef ref) {
  SleepTimerSheet.show(context);
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

void _showEqualizer(BuildContext context, WidgetRef ref) {
  var selectedPreset = ref.read(settingsProvider).equalizerPreset;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: FutureBuilder(
          future: ref.read(audioHandlerProvider).equalizerParameters(),
          builder: (context, snapshot) {
            final parameters = snapshot.data;
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (parameters == null) {
              return const SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    'Equalizer is not available for this audio session.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return StatefulBuilder(
              builder: (context, setSheetState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Equalizer',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children:
                        const {
                          'flat': 'Flat',
                          'voice': 'Voice',
                          'bass': 'Bass',
                          'treble': 'Treble',
                          'custom': 'Custom',
                        }.entries.map((entry) {
                          final selected = selectedPreset == entry.key;
                          return ChoiceChip(
                            label: Text(entry.value),
                            selected: selected,
                            onSelected: (_) async {
                              if (entry.key == 'custom') return;
                              final settings = ref.read(settingsProvider);
                              await ref
                                  .read(settingsProvider.notifier)
                                  .update(
                                    settings.copyWith(
                                      equalizerPreset: entry.key,
                                    ),
                                  );
                              ref
                                  .read(audioHandlerProvider)
                                  .configureEqualizer(entry.key);
                              setSheetState(() => selectedPreset = entry.key);
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: ListView(
                      children: parameters.bands.map((band) {
                        return Row(
                          children: [
                            SizedBox(
                              width: 58,
                              child: Text(
                                band.centerFrequency >= 1000
                                    ? '${(band.centerFrequency / 1000).toStringAsFixed(1)}k'
                                    : '${band.centerFrequency.round()}Hz',
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: band.gain
                                    .clamp(
                                      parameters.minDecibels,
                                      parameters.maxDecibels,
                                    )
                                    .toDouble(),
                                min: parameters.minDecibels,
                                max: parameters.maxDecibels,
                                onChanged: (value) async {
                                  await ref
                                      .read(audioHandlerProvider)
                                      .setEqualizerBand(band.index, value);
                                  final settings = ref.read(settingsProvider);
                                  await ref
                                      .read(settingsProvider.notifier)
                                      .update(
                                        settings.copyWith(
                                          equalizerPreset: 'custom',
                                          equalizerGains: parameters.bands
                                              .map((item) => item.gain)
                                              .toList(),
                                        ),
                                      );
                                  setSheetState(
                                    () => selectedPreset = 'custom',
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              width: 44,
                              child: Text('${band.gain.toStringAsFixed(1)} dB'),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
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
