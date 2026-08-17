import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/audio/dhwani_audio_handler.dart';

class CarModeScreen extends ConsumerWidget {
  const CarModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(playerSnapshotProvider).value;
    final playing = snapshot?.status == DhwaniPlaybackStatus.playing;
    return Scaffold(
      appBar: AppBar(title: const Text('Car Mode')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                snapshot?.station?.name ?? 'No station selected',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                snapshot?.station?.frequencyDisplay ?? '—',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _BigButton(
                      icon: Icons.skip_previous,
                      label: 'Previous',
                      onTap: () =>
                          ref.read(audioHandlerProvider).skipToPrevious(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigButton(
                      icon: playing ? Icons.pause : Icons.play_arrow,
                      label: playing ? 'Pause' : 'Play',
                      onTap: () => playing
                          ? ref.read(audioHandlerProvider).pause()
                          : playWithMediaNotification(ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigButton(
                      icon: Icons.skip_next,
                      label: 'Next',
                      onTap: () => ref.read(audioHandlerProvider).skipToNext(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.onSurface,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 118,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.surface),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.surface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
