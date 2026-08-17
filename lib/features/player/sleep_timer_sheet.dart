import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme/dhwani_theme.dart';

class SleepTimerSheet extends ConsumerStatefulWidget {
  const SleepTimerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SleepTimerSheet(),
    );
  }

  @override
  ConsumerState<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends ConsumerState<SleepTimerSheet> {
  int _selectedMinutes = 30;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    final timerState = ref.read(sleepTimerProvider);
    if (timerState.active) {
      _selectedMinutes =
          (timerState.remaining.inSeconds / 60).ceil().clamp(1, 180);
    }
  }

  void _onMinutesChanged(int minutes) {
    if (_selectedMinutes != minutes) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedMinutes = minutes;
        _touched = true;
      });
    }
  }

  String _formatDigital(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        isDark ? DhwaniColors.darkSurface : theme.colorScheme.surface;
    final timerState = ref.watch(sleepTimerProvider);
    final isRunning = timerState.active;

    final displayDuration = (isRunning && !_touched)
        ? timerState.remaining
        : Duration(minutes: _selectedMinutes);

    final stopTime = DateTime.now().add(displayDuration);
    final timeFormat = DateFormat.jm();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: .25),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sleep Session',
                    style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ) ??
                        const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: .08),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: theme.colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Radial Clock Dial
                    Center(
                      child: _RadialTimerDial(
                        minutes: _selectedMinutes,
                        durationText: _formatDigital(displayDuration),
                        isActive: isRunning,
                        isDark: isDark,
                        onChanged: _onMinutesChanged,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (final mins in const [15, 30, 45, 60, 90, 120])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _onMinutesChanged(mins),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedMinutes == mins
                                          ? DhwaniColors.signal.withValues(
                                              alpha: .14,
                                            )
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: .06),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _selectedMinutes == mins
                                            ? DhwaniColors.signal
                                            : theme.colorScheme.outline
                                                .withValues(alpha: .3),
                                        width:
                                            _selectedMinutes == mins ? 1.4 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      '$mins m',
                                      style: TextStyle(
                                        color: _selectedMinutes == mins
                                            ? DhwaniColors.signal
                                            : theme.colorScheme.onSurface,
                                        fontWeight: _selectedMinutes == mins
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Custom & End At Row
                    Row(
                      children: [
                        Expanded(
                          child: _CustomTimerOptionButton(
                            icon: Icons.edit_calendar_outlined,
                            label: 'Custom mins',
                            onTap: () async {
                              final mins = await showDialog<int>(
                                context: context,
                                builder: (ctx) =>
                                    const _CustomDurationDialog(),
                              );
                              if (mins != null && mins > 0 && mounted) {
                                _onMinutesChanged(mins);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CustomTimerOptionButton(
                            icon: Icons.access_time_rounded,
                            label: 'End at…',
                            onTap: () async {
                              final now = DateTime.now();
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  now.add(const Duration(minutes: 30)),
                                ),
                              );
                              if (time == null || !mounted) return;
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
                              final diff = end.difference(now);
                              _onMinutesChanged(diff.inMinutes.clamp(1, 720));
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Session Info Stats Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: .04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: .25,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRunning ? 'Remaining Time' : 'Set Duration',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: .6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDigital(displayDuration),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: theme.colorScheme.outline.withValues(
                              alpha: .25,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stops Playback At',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: .6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeFormat.format(stopTime),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Action Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: isRunning
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: DhwaniColors.signal,
                              side: const BorderSide(
                                color: DhwaniColors.signal,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: const Text(
                              'Cancel Timer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(context);
                              await ref
                                  .read(sleepTimerProvider.notifier)
                                  .cancel();
                            },
                          ),
                        ),
                        if (_touched) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: DhwaniColors.signal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: const Icon(Icons.update_rounded),
                              label: const Text(
                                'Update',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.heavyImpact();
                                final mins = _selectedMinutes;
                                Navigator.pop(context);
                                ref
                                    .read(sleepTimerProvider.notifier)
                                    .start(Duration(minutes: mins));
                              },
                            ),
                          ),
                        ],
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: DhwaniColors.signal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 24),
                        label: const Text(
                          'Start Sleep Timer',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .3,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          final mins = _selectedMinutes;
                          Navigator.pop(context);
                          ref
                              .read(sleepTimerProvider.notifier)
                              .start(Duration(minutes: mins));
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomDurationDialog extends StatefulWidget {
  const _CustomDurationDialog();

  @override
  State<_CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<_CustomDurationDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom sleep duration'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Minutes',
          hintText: 'e.g. 25',
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
            int.tryParse(_controller.text),
          ),
          child: const Text('Set'),
        ),
      ],
    );
  }
}

class _CustomTimerOptionButton extends StatelessWidget {
  const _CustomTimerOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: .3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadialTimerDial extends StatelessWidget {
  const _RadialTimerDial({
    required this.minutes,
    required this.durationText,
    required this.isActive,
    required this.isDark,
    required this.onChanged,
  });

  final int minutes;
  final String durationText;
  final bool isActive;
  final bool isDark;
  final ValueChanged<int> onChanged;

  void _handlePan(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    var angle = math.atan2(dy, dx) + (math.pi / 2);
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    var mappedMinutes = ((angle / (2 * math.pi)) * 60).round();
    if (mappedMinutes <= 0) mappedMinutes = 60;

    if (minutes > 60 && mappedMinutes < 30) {
      mappedMinutes += 60;
    }

    onChanged(mappedMinutes.clamp(1, 180));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const dialSize = 270.0;

    return GestureDetector(
      onPanStart: (details) =>
          _handlePan(details.localPosition, const Size(dialSize, dialSize)),
      onPanUpdate: (details) =>
          _handlePan(details.localPosition, const Size(dialSize, dialSize)),
      child: SizedBox(
        width: dialSize,
        height: dialSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(dialSize, dialSize),
              painter: _TimerDialPainter(
                minutes: minutes,
                isActive: isActive,
                isDark: isDark,
                onSurfaceColor: theme.colorScheme.onSurface,
                outlineColor: theme.colorScheme.outline,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  durationText,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive ? 'LIVE COUNTDOWN' : 'DRAG TO SET',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: .6),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerDialPainter extends CustomPainter {
  _TimerDialPainter({
    required this.minutes,
    required this.isActive,
    required this.isDark,
    required this.onSurfaceColor,
    required this.outlineColor,
  });

  final int minutes;
  final bool isActive;
  final bool isDark;
  final Color onSurfaceColor;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 4;
    final trackRadius = outerRadius - 16;
    final ticksRadius = trackRadius - 20;
    final innerRadius = ticksRadius - 18;

    final sweepFraction = (minutes % 60) / 60.0;
    final sweepAngle =
        (sweepFraction == 0 && minutes > 0 ? 1.0 : sweepFraction) *
        2 *
        math.pi;

    const hourLabels = [
      '12',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
    ];
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (var i = 0; i < 12; i++) {
      final hourAngle = (i * 30 - 90) * (math.pi / 180);
      final x = center.dx + (outerRadius - 8) * math.cos(hourAngle);
      final y = center.dy + (outerRadius - 8) * math.sin(hourAngle);

      textPainter.text = TextSpan(
        text: hourLabels[i],
        style: TextStyle(
          color: onSurfaceColor.withValues(alpha: .75),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // 1. Outer Track Ring
    final trackPaint = Paint()
      ..color = onSurfaceColor.withValues(alpha: isDark ? .12 : .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, trackRadius, trackPaint);

    // 2. Active Filled Arc
    final activeArcPaint = Paint()
      ..color = DhwaniColors.signal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: trackRadius),
      -math.pi / 2,
      sweepAngle,
      false,
      activeArcPaint,
    );

    // 3. Inner Tick Marks Ring (60 minute ticks)
    final majorTickPaint = Paint()
      ..color = onSurfaceColor.withValues(alpha: .65)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final minorTickPaint = Paint()
      ..color = onSurfaceColor.withValues(alpha: .22)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 60; i++) {
      final isMajor = i % 5 == 0;
      final tickAngle = (i * 6 - 90) * (math.pi / 180);
      final length = isMajor ? 8.0 : 4.5;

      final startX = center.dx + (ticksRadius - length) * math.cos(tickAngle);
      final startY = center.dy + (ticksRadius - length) * math.sin(tickAngle);
      final endX = center.dx + ticksRadius * math.cos(tickAngle);
      final endY = center.dy + ticksRadius * math.sin(tickAngle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        isMajor ? majorTickPaint : minorTickPaint,
      );
    }

    // 4. Indicator Needle
    final needleAngle = sweepAngle - math.pi / 2;
    final needleStartX =
        center.dx + (ticksRadius - 14) * math.cos(needleAngle);
    final needleStartY =
        center.dy + (ticksRadius - 14) * math.sin(needleAngle);
    final needleEndX = center.dx + (ticksRadius + 2) * math.cos(needleAngle);
    final needleEndY = center.dy + (ticksRadius + 2) * math.sin(needleAngle);

    final needlePaint = Paint()
      ..color = DhwaniColors.signal
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(needleStartX, needleStartY),
      Offset(needleEndX, needleEndY),
      needlePaint,
    );

    // 5. Center Cutout Circle Fill (surface card)
    final innerCenterPaint = Paint()
      ..color = isDark
          ? const Color(0xFF22221F)
          : const Color(0xFFEFEFEA)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, innerRadius, innerCenterPaint);

    final innerCenterBorderPaint = Paint()
      ..color = outlineColor.withValues(alpha: .25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, innerRadius, innerCenterBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _TimerDialPainter oldDelegate) => true;
}
