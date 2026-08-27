import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/audio/dhwani_audio_handler.dart';
import '../../core/settings/settings_controller.dart';
import '../../data/models/radio_station.dart';

class RetroTunerScreen extends ConsumerStatefulWidget {
  const RetroTunerScreen({super.key});

  @override
  ConsumerState<RetroTunerScreen> createState() => _RetroTunerScreenState();
}

class _RetroTunerScreenState extends ConsumerState<RetroTunerScreen> {
  @override
  Widget build(BuildContext context) {
    final station = ref.watch(selectedStationProvider);
    if (station == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/radio');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final snapshot =
        ref.watch(playerSnapshotProvider).value ??
        DhwaniPlayerSnapshot(
          status: DhwaniPlaybackStatus.ready,
          station: station,
        );
    final all = ref.watch(stationsProvider).value ?? const <RadioStation>[];
    final band = ref.watch(bandFilterProvider);
    final queue = tuningQueue(
      all,
      current: station,
      band: band,
      preferredScope: ref.watch(settingsProvider).defaultScope,
    );
    final favourites =
        ref.watch(favouritesProvider).value ?? const <RadioStation>[];
    final sleepTimer = ref.watch(sleepTimerProvider);
    final playing = snapshot.status == DhwaniPlaybackStatus.playing;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape =
                constraints.maxWidth > 600 &&
                constraints.maxWidth > constraints.maxHeight;
            if (landscape) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(
                          child: _TunerPanel(
                            station: station,
                            snapshot: snapshot,
                            queue: queue,
                            sleepTimer: sleepTimer,
                            playing: playing,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          child: _ControlPanel(
                            station: station,
                            snapshot: snapshot,
                            queue: queue,
                            favourites: favourites,
                            playing: playing,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      _TunerPanel(
                        station: station,
                        snapshot: snapshot,
                        queue: queue,
                        sleepTimer: sleepTimer,
                        playing: playing,
                      ),
                      _ControlPanel(
                        station: station,
                        snapshot: snapshot,
                        queue: queue,
                        favourites: favourites,
                        playing: playing,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LEFT PANEL — Dark tuner section
// ---------------------------------------------------------------------------

class _TunerPanel extends ConsumerWidget {
  const _TunerPanel({
    required this.station,
    required this.snapshot,
    required this.queue,
    required this.sleepTimer,
    required this.playing,
  });
  final RadioStation station;
  final DhwaniPlayerSnapshot snapshot;
  final List<RadioStation> queue;
  final SleepTimerState sleepTimer;
  final bool playing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationIndex = math.max(
      0,
      queue.indexWhere((s) => s.id == station.id),
    );

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top bar: back button + sleep timer
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/radio');
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white70,
                ),
                tooltip: 'Back to player',
              ),
              const Spacer(),
              if (sleepTimer.endAt != null)
                _SleepTimerBadge(remaining: sleepTimer.remaining),
            ],
          ),
          const SizedBox(height: 4),

          // Frequency display card
          _FrequencyDisplay(
            station: station,
            snapshot: snapshot,
            stationIndex: stationIndex,
            totalStations: queue.length,
          ),
          const SizedBox(height: 12),

          // Retro tuner dial
          _RetroTunerDial(
            stations: queue,
            current: station,
            onStation: (next) {
              HapticFeedback.selectionClick();
              ref
                  .read(stationPlaybackControllerProvider)
                  .tune(next, queue: queue, autoplay: playing);
            },
          ),
          const SizedBox(height: 10),

          // Bottom bar: favourite, band toggle, equalizer
          _TunerBottomBar(station: station),
        ],
      ),
    );
  }
}

class _SleepTimerBadge extends StatelessWidget {
  const _SleepTimerBadge({required this.remaining});
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final mins = remaining.inMinutes;
    final label = mins >= 60
        ? '${remaining.inHours}h ${mins.remainder(60)}m'
        : '${mins}m';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: .15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white60, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyDisplay extends StatelessWidget {
  const _FrequencyDisplay({
    required this.station,
    required this.snapshot,
    required this.stationIndex,
    required this.totalStations,
  });
  final RadioStation station;
  final DhwaniPlayerSnapshot snapshot;
  final int stationIndex;
  final int totalStations;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        children: [
          // Frequency block with blue tint
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8BB0C4), Color(0xFFA8C8D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FM badge + station index
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          station.bandLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF1A3A50),
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${stationIndex + 1}',
                          style: const TextStyle(
                            color: Color(0xFF1A3A50),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Large frequency
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: station.frequencyDisplay,
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D1B26),
                              height: 1,
                              letterSpacing: -1.5,
                            ),
                          ),
                          TextSpan(
                            text: station.frequency != null
                                ? ' ${station.frequencyUnit ?? 'MHz'}'
                                : '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2A4A5C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Now Playing + station info
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NOW PLAYING',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.icyTitle ?? station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        snapshot.status == DhwaniPlaybackStatus.playing
                            ? Icons.circle
                            : Icons.circle_outlined,
                        size: 8,
                        color: snapshot.status == DhwaniPlaybackStatus.playing
                            ? const Color(0xFF4ADE80)
                            : Colors.white38,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _statusLabel(snapshot.status),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Retro tuner dial
// ---------------------------------------------------------------------------

class _RetroTunerDial extends StatefulWidget {
  const _RetroTunerDial({
    required this.stations,
    required this.current,
    required this.onStation,
  });
  final List<RadioStation> stations;
  final RadioStation current;
  final ValueChanged<RadioStation> onStation;

  @override
  State<_RetroTunerDial> createState() => _RetroTunerDialState();
}

class _RetroTunerDialState extends State<_RetroTunerDial> {
  double _drag = 0;

  int get _currentIndex =>
      math.max(0, widget.stations.indexWhere((s) => s.id == widget.current.id));

  void _step(int amount) {
    if (widget.stations.isEmpty) return;
    final next = (_currentIndex + amount).clamp(0, widget.stations.length - 1);
    if (next != _currentIndex) widget.onStation(widget.stations[next]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tuning arrows + dial
        Row(
          children: [
            _RetroArrowButton(
              icon: Icons.chevron_left_rounded,
              onPressed: () => _step(-1),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) =>
                    setState(() => _drag += d.delta.dx),
                onHorizontalDragEnd: (d) {
                  final delta =
                      (-_drag / 54 - d.velocity.pixelsPerSecond.dx / 1200)
                          .round();
                  setState(() => _drag = 0);
                  if (delta != 0) _step(delta);
                },
                child: SizedBox(
                  height: 80,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _RetroDialPainter(
                      index: _currentIndex,
                      count: math.max(1, widget.stations.length),
                      drag: _drag,
                      band: widget.current.band,
                      frequencies: widget.stations
                          .map((s) => s.frequency)
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
            _RetroArrowButton(
              icon: Icons.chevron_right_rounded,
              onPressed: () => _step(1),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Frequency labels row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: _FrequencyLabelsRow(
            index: _currentIndex,
            stations: widget.stations,
          ),
        ),
      ],
    );
  }
}

class _RetroArrowButton extends StatelessWidget {
  const _RetroArrowButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white60, size: 24),
        splashRadius: 18,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}

class _FrequencyLabelsRow extends StatelessWidget {
  const _FrequencyLabelsRow({required this.index, required this.stations});
  final int index;
  final List<RadioStation> stations;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[];
    for (var i = index - 2; i <= index + 2; i++) {
      if (i < 0 || i >= stations.length) {
        labels.add('');
      } else {
        final f = stations[i].frequency;
        labels.add(f != null ? f.toStringAsFixed(0) : '${i + 1}');
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels.map((label) {
        final isCurrent = label == labels[2];
        return Text(
          label,
          style: TextStyle(
            color: isCurrent ? Colors.white70 : Colors.white24,
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}

class _RetroDialPainter extends CustomPainter {
  const _RetroDialPainter({
    required this.index,
    required this.count,
    required this.drag,
    required this.band,
    required this.frequencies,
  });
  final int index;
  final int count;
  final double drag;
  final RadioBand band;
  final List<double?> frequencies;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.width / 2;
    final cy = size.height / 2;

    // Bezel background
    final bezelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 4, size.width, size.height - 8),
      const Radius.circular(8),
    );
    canvas.drawRRect(bezelRect, Paint()..color = const Color(0xFF2A2A2A));

    // Tick marks
    final tickPaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 0.8;
    final majorPaint = Paint()
      ..color = const Color(0xFF888888)
      ..strokeWidth = 1.2;
    const spacing = 8.0;
    final shift = drag % spacing;

    for (var i = -70; i <= 70; i++) {
      final x = centre + i * spacing + shift;
      if (x < 8 || x > size.width - 8) continue;
      final absolute = i + index * 10;
      final big = absolute % 10 == 0;
      final medium = absolute % 5 == 0;
      final height = big
          ? 34.0
          : medium
          ? 22.0
          : 12.0;
      canvas.drawLine(
        Offset(x, cy - height / 2),
        Offset(x, cy + height / 2),
        big || medium ? majorPaint : tickPaint,
      );

      if (big) {
        final diamondPath = Path()
          ..moveTo(x, cy - height / 2 - 5)
          ..lineTo(x + 2.5, cy - height / 2 - 2.5)
          ..lineTo(x, cy - height / 2)
          ..lineTo(x - 2.5, cy - height / 2 - 2.5)
          ..close();
        canvas.drawPath(diamondPath, Paint()..color = const Color(0xFF777777));
      }
    }

    // Red needle
    final needlePaint = Paint()
      ..color = const Color(0xFFE33B32)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centre, 8),
      Offset(centre, size.height - 8),
      needlePaint,
    );

    // Needle top triangle
    final trianglePath = Path()
      ..moveTo(centre, 4)
      ..lineTo(centre - 4, 11)
      ..lineTo(centre + 4, 11)
      ..close();
    canvas.drawPath(trianglePath, Paint()..color = const Color(0xFFE33B32));
  }

  @override
  bool shouldRepaint(covariant _RetroDialPainter oldDelegate) =>
      oldDelegate.index != index ||
      oldDelegate.drag != drag ||
      oldDelegate.count != count;
}

// ---------------------------------------------------------------------------
// Tuner bottom bar
// ---------------------------------------------------------------------------

class _TunerBottomBar extends ConsumerWidget {
  const _TunerBottomBar({required this.station});
  final RadioStation station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _RetroIconButton(
          icon: Icons.star_rounded,
          label: 'Save',
          onPressed: () async {
            await ref
                .read(catalogueRepositoryProvider)
                .favourite(station, true);
            HapticFeedback.lightImpact();
          },
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: .1)),
          ),
          child: Text(
            'FM · AM · NET',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        _RetroIconButton(
          icon: Icons.graphic_eq_rounded,
          label: 'EQ',
          onPressed: () => _showEqualizer(context, ref),
        ),
      ],
    );
  }
}

class _RetroIconButton extends StatelessWidget {
  const _RetroIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white60, size: 16),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RIGHT PANEL — Light controls section
// ---------------------------------------------------------------------------

class _ControlPanel extends ConsumerWidget {
  const _ControlPanel({
    required this.station,
    required this.snapshot,
    required this.queue,
    required this.favourites,
    required this.playing,
  });
  final RadioStation station;
  final DhwaniPlayerSnapshot snapshot;
  final List<RadioStation> queue;
  final List<RadioStation> favourites;
  final bool playing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAE5),
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Radio area + stereo indicator
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/countries'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD0D0CB)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'RADIO AREA',
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            station.country,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: Color(0xFF222222),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right,
                          size: 15,
                          color: Color(0xFF999999),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD0D0CB)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.headphones_rounded,
                      size: 16,
                      color: Color(0xFF444444),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'STEREO',
                      style: TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Favourite stations
          _FavouriteStationsRow(
            favourites: favourites,
            queue: queue,
            playing: playing,
          ),
          const SizedBox(height: 12),

          // Transport controls + volume knob
          Row(
            children: [
              Expanded(
                child: _TransportControls(
                  snapshot: snapshot,
                  station: station,
                  playing: playing,
                  queue: queue,
                ),
              ),
              const SizedBox(width: 8),
              _VolumeKnob(),
            ],
          ),
        ],
      ),
    );
  }
}

class _FavouriteStationsRow extends ConsumerWidget {
  const _FavouriteStationsRow({
    required this.favourites,
    required this.queue,
    required this.playing,
  });
  final List<RadioStation> favourites;
  final List<RadioStation> queue;
  final bool playing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Favourite stations · ${favourites.length}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => context.push('/search'),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Search',
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.search, size: 15, color: Color(0xFF777777)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: favourites.isEmpty
              ? const Center(
                  child: Text(
                    'No favourites yet',
                    style: TextStyle(color: Color(0xFF999999), fontSize: 12),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: favourites.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final fav = favourites[index];
                    return _FavouriteChip(
                      station: fav,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(selectedStationProvider.notifier).select(fav);
                        ref
                            .read(stationPlaybackControllerProvider)
                            .tune(fav, queue: queue, autoplay: playing);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FavouriteChip extends StatelessWidget {
  const _FavouriteChip({required this.station, required this.onTap});
  final RadioStation station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD0D0CB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                station.name.length > 12
                    ? '${station.name.substring(0, 12)}…'
                    : station.name,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (station.frequency != null) ...[
                const SizedBox(width: 6),
                Text(
                  station.frequencyDisplay,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transport controls
// ---------------------------------------------------------------------------

class _TransportControls extends ConsumerWidget {
  const _TransportControls({
    required this.snapshot,
    required this.station,
    required this.playing,
    required this.queue,
  });
  final DhwaniPlayerSnapshot snapshot;
  final RadioStation station;
  final bool playing;
  final List<RadioStation> queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () => _showEqualizer(context, ref),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Equalizer',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 13,
                      color: Color(0xFF666666),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TransportIcon(
                icon: Icons.skip_previous_rounded,
                onPressed: () => ref
                    .read(stationPlaybackControllerProvider)
                    .previous(autoplay: playing),
              ),
              _TransportIcon(
                icon: Icons.fast_rewind_rounded,
                onPressed: () {
                  final index = math.max(
                    0,
                    queue.indexWhere((s) => s.id == station.id),
                  );
                  final target = math.max(0, index - 5);
                  if (target != index && queue.isNotEmpty) {
                    ref
                        .read(stationPlaybackControllerProvider)
                        .tune(queue[target], queue: queue, autoplay: playing);
                  }
                },
              ),
              const SizedBox(width: 4),
              Material(
                color: const Color(0xFF222222),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => playing
                      ? ref.read(audioHandlerProvider).pause()
                      : playWithMediaNotification(ref, station),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _TransportIcon(
                icon: Icons.fast_forward_rounded,
                onPressed: () {
                  final index = math.max(
                    0,
                    queue.indexWhere((s) => s.id == station.id),
                  );
                  final target = math.min(queue.length - 1, index + 5);
                  if (target != index && queue.isNotEmpty) {
                    ref
                        .read(stationPlaybackControllerProvider)
                        .tune(queue[target], queue: queue, autoplay: playing);
                  }
                },
              ),
              _TransportIcon(
                icon: Icons.skip_next_rounded,
                onPressed: () => ref
                    .read(stationPlaybackControllerProvider)
                    .next(autoplay: playing),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransportIcon extends StatelessWidget {
  const _TransportIcon({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xFF333333), size: 22),
      splashRadius: 18,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
    );
  }
}

// ---------------------------------------------------------------------------
// Circular volume knob
// ---------------------------------------------------------------------------

class _VolumeKnob extends ConsumerStatefulWidget {
  @override
  ConsumerState<_VolumeKnob> createState() => _VolumeKnobState();
}

class _VolumeKnobState extends ConsumerState<_VolumeKnob> {
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _volume = ref.read(audioHandlerProvider).volume;
  }

  void _updateVolume(Offset localPosition, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final angle = math.atan2(
      localPosition.dy - centre.dy,
      localPosition.dx - centre.dx,
    );
    const startAngle = 3 * math.pi / 4;
    var normalized = (angle - startAngle) / (1.5 * math.pi);
    if (normalized < 0) normalized += (2 * math.pi) / (1.5 * math.pi);
    normalized = normalized.clamp(0.0, 1.0);
    setState(() => _volume = normalized);
    ref.read(audioHandlerProvider).setVolume(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        _updateVolume(details.localPosition, box.size);
      },
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        _updateVolume(details.localPosition, box.size);
      },
      child: SizedBox(
        width: 72,
        height: 72,
        child: CustomPaint(
          painter: _VolumeKnobPainter(volume: _volume),
          child: const Center(
            child: Icon(
              Icons.volume_up_rounded,
              color: Color(0xFF333333),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _VolumeKnobPainter extends CustomPainter {
  const _VolumeKnobPainter({required this.volume});
  final double volume;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Outer ring shadow
    canvas.drawCircle(
      centre.translate(0, 1),
      radius + 2,
      Paint()
        ..color = const Color(0xFFBBBBB5)
        ..style = PaintingStyle.fill,
    );

    // Outer ring
    canvas.drawCircle(
      centre,
      radius + 1,
      Paint()
        ..color = const Color(0xFF333333)
        ..style = PaintingStyle.fill,
    );

    // Inner circle
    canvas.drawCircle(
      centre,
      radius - 3,
      Paint()
        ..color = const Color(0xFF444444)
        ..style = PaintingStyle.fill,
    );

    // Volume arc track
    const startAngle = 3 * math.pi / 4;
    const sweepTotal = 1.5 * math.pi;
    final arcRect = Rect.fromCircle(center: centre, radius: radius - 7);

    canvas.drawArc(
      arcRect,
      startAngle,
      sweepTotal,
      false,
      Paint()
        ..color = const Color(0xFF555555)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      arcRect,
      startAngle,
      sweepTotal * volume,
      false,
      Paint()
        ..color = const Color(0xFF8BB0C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Notch indicator
    final notchAngle = startAngle + sweepTotal * volume;
    final notchX = centre.dx + (radius - 7) * math.cos(notchAngle);
    final notchY = centre.dy + (radius - 7) * math.sin(notchAngle);
    canvas.drawCircle(
      Offset(notchX, notchY),
      3.5,
      Paint()..color = Colors.white,
    );

    // − label
    final minusPainter = TextPainter(
      text: const TextSpan(
        text: '−',
        style: TextStyle(
          color: Color(0xFF888888),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    minusPainter.paint(
      canvas,
      Offset(centre.dx - radius - 1, centre.dy + radius * 0.55),
    );

    // + label
    final plusPainter = TextPainter(
      text: const TextSpan(
        text: '+',
        style: TextStyle(
          color: Color(0xFF888888),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    plusPainter.paint(
      canvas,
      Offset(centre.dx + radius - 3, centre.dy + radius * 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _VolumeKnobPainter oldDelegate) =>
      oldDelegate.volume != volume;
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

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
  DhwaniPlaybackStatus.selected => 'Ready',
  DhwaniPlaybackStatus.switching => 'Switching…',
  DhwaniPlaybackStatus.connecting => 'Connecting…',
  DhwaniPlaybackStatus.loading => 'Connecting…',
  DhwaniPlaybackStatus.ready => 'Ready',
  DhwaniPlaybackStatus.buffering => 'Buffering…',
  DhwaniPlaybackStatus.playing => 'Live',
  DhwaniPlaybackStatus.paused => 'Paused',
  DhwaniPlaybackStatus.reconnecting => 'Reconnecting…',
  DhwaniPlaybackStatus.offAir => 'Currently off air',
  DhwaniPlaybackStatus.offline => 'Offline',
  DhwaniPlaybackStatus.geoBlocked => 'Unavailable here',
  DhwaniPlaybackStatus.unsupported => 'Unsupported stream',
  DhwaniPlaybackStatus.unavailable => 'Unavailable',
  DhwaniPlaybackStatus.error => 'Unavailable',
};
