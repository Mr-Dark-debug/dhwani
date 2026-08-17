import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../app/providers.dart';
import '../../app/theme/dhwani_theme.dart';
import '../../data/models/radio_station.dart';
import '../audio/dhwani_audio_handler.dart';

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
                if (snapshot?.station != null && location != '/radio')
                  MiniPlayer(snapshot: snapshot!),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16,
                        color: Colors.black.withValues(alpha: .12),
                        offset: const Offset(0, -2),
                      ),
                    ],
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerTheme.color ??
                            Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: .3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: GNav(
                        rippleColor: DhwaniColors.signal.withValues(alpha: .18),
                        hoverColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .06),
                        gap: 8,
                        activeColor: DhwaniColors.signal,
                        iconSize: 22,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: DhwaniColors.signal,
                          letterSpacing: .3,
                        ),
                        tabBorderRadius: 18,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOutCubic,
                        tabBackgroundColor:
                            DhwaniColors.signal.withValues(alpha: .12),
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .55),
                        selectedIndex: selected < 0 ? 0 : selected,
                        onTabChange: (index) {
                          HapticFeedback.selectionClick();
                          context.go(_paths[index]);
                        },
                        tabs: const [
                          GButton(
                            icon: Icons.radio_outlined,
                            text: 'Radio',
                          ),
                          GButton(
                            icon: Icons.explore_outlined,
                            text: 'Discover',
                          ),
                          GButton(
                            icon: Icons.favorite_outline_rounded,
                            text: 'Saved',
                          ),
                          GButton(
                            icon: Icons.library_music_outlined,
                            text: 'Recordings',
                          ),
                        ],
                      ),
                    ),
                  ),
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
                    : playWithMediaNotification(ref),
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
    this.subtitle,
  });
  final RadioStation station;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? subtitle;

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
        subtitle ??
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
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(station.favicon?.trim() ?? '');
    final validArtwork =
        uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .07),
      child: Text(
        station.name.trim().isEmpty
            ? 'D'
            : station.name.trim()[0].toUpperCase(),
        style: TextStyle(fontSize: size * .4, fontWeight: FontWeight.w800),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .32),
      child: validArtwork
          ? CachedNetworkImage(
              imageUrl: uri.toString(),
              width: size,
              height: size,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 160),
              placeholder: (_, _) => fallback,
              errorWidget: (_, _, _) => fallback,
            )
          : fallback,
    );
  }
}
