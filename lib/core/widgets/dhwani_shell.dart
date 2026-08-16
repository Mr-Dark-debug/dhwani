import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../audio/dhwani_audio_handler.dart';
import '../../data/models/radio_station.dart';

class DhwaniShell extends ConsumerWidget {
  const DhwaniShell({
    super.key,
    required this.child,
    this.title,
    this.actions = const [],
    this.showNavigation = true,
  });
  final Widget child;
  final String? title;
  final List<Widget> actions;
  final bool showNavigation;

  static const _paths = ['/radio', '/discover', '/saved', '/recordings'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _paths.indexWhere((path) => location.startsWith(path));
    final snapshot = ref.watch(playerSnapshotProvider).value;
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      body: SafeArea(top: title == null, bottom: false, child: child),
      bottomNavigationBar: showNavigation
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (snapshot?.station != null) MiniPlayer(snapshot: snapshot!),
                NavigationBar(
                  selectedIndex: selected < 0 ? 0 : selected,
                  onDestinationSelected: (index) => context.go(_paths[index]),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.radio_outlined),
                      selectedIcon: Icon(Icons.radio),
                      label: 'Radio',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore),
                      label: 'Discover',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_outline),
                      selectedIcon: Icon(Icons.favorite),
                      label: 'Saved',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.library_music_outlined),
                      selectedIcon: Icon(Icons.library_music),
                      label: 'Recordings',
                    ),
                  ],
                ),
              ],
            )
          : null,
    );
  }
}

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, required this.snapshot});
  final DhwaniPlayerSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = snapshot.station!;
    final playing = snapshot.status == DhwaniPlaybackStatus.playing;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () {
          ref.read(selectedStationProvider.notifier).select(station);
          context.go('/radio');
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              _StationMonogram(station: station, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      station.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      playing ? 'LIVE' : snapshot.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: playing ? const Color(0xFF2E7D5B) : null,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: playing ? 'Pause' : 'Play live',
                onPressed: () => playing
                    ? ref.read(audioHandlerProvider).pause()
                    : ref.read(audioHandlerProvider).play(),
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StationTile extends StatelessWidget {
  const StationTile({
    super.key,
    required this.station,
    required this.onTap,
    this.trailing,
  });
  final RadioStation station;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        '${station.name}, ${station.frequencyDisplay} ${station.frequencySubtitle}',
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      leading: _StationMonogram(station: station),
      title: Text(
        station.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          if (station.city != null) station.city,
          station.state,
          station.frequency == null
              ? 'NET'
              : '${station.frequencyDisplay} ${station.frequencyUnit}',
          if (station.languages.isNotEmpty)
            station.languages.take(2).join(', '),
        ].whereType<String>().join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class _StationMonogram extends StatelessWidget {
  const _StationMonogram({required this.station, this.size = 48});
  final RadioStation station;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(size * .32),
    ),
    child: Text(
      station.name.trim().isEmpty ? 'D' : station.name.trim()[0].toUpperCase(),
      style: TextStyle(fontSize: size * .4, fontWeight: FontWeight.w800),
    ),
  );
}
