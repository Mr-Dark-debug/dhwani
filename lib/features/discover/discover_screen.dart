import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/widgets/dhwani_shell.dart';
import '../../data/models/radio_station.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations =
        ref.watch(stationsProvider).value ?? const <RadioStation>[];
    final sections = <String, List<RadioStation>>{
      'Around Darbhanga': stations
          .where((station) => station.city == 'Darbhanga')
          .toList(),
      'Bihar': stations
          .where((station) => station.state?.toLowerCase() == 'bihar')
          .toList(),
      'Akashvani': stations
          .where((station) => station.name.toLowerCase().contains('akashvani'))
          .toList(),
      'Maithili': stations
          .where(
            (station) => station.languages.any(
              (language) => language.toLowerCase().contains('maithili'),
            ),
          )
          .toList(),
      'News': stations
          .where(
            (station) =>
                station.tags.any((tag) => tag.toLowerCase().contains('news')),
          )
          .toList(),
      'Popular worldwide': [...stations]
        ..sort((a, b) => b.clickCount.compareTo(a.clickCount)),
    }..removeWhere((_, value) => value.isEmpty);
    return DhwaniShell(
      title: 'Discover',
      actions: [
        IconButton(
          tooltip: 'Search',
          onPressed: () => context.push('/search'),
          icon: const Icon(Icons.search_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: stations.isEmpty
                ? null
                : () => _open(
                    context,
                    ref,
                    stations[Random().nextInt(stations.length)],
                    stations,
                  ),
            child: Ink(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SURPRISE ME',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: .65),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tune somewhere unexpected.',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.surface,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.shuffle_rounded,
                    color: Theme.of(context).colorScheme.surface,
                    size: 34,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          ...sections.entries.map(
            (entry) => _Section(
              title: entry.key,
              stations: entry.value.take(12).toList(),
              onOpen: (station) => _open(context, ref, station, entry.value),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    RadioStation station,
    List<RadioStation> queue,
  ) async {
    ref.read(selectedStationProvider.notifier).select(station);
    await ref
        .read(audioHandlerProvider)
        .setQueueStations(queue, selected: station);
    await ref.read(audioHandlerProvider).selectStation(station);
    await ref.read(catalogueRepositoryProvider).addHistory(station);
    if (context.mounted) context.go('/radio');
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.stations,
    required this.onOpen,
  });
  final String title;
  final List<RadioStation> stations;
  final ValueChanged<RadioStation> onOpen;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final station = stations[index];
              return SizedBox(
                width: 175,
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => onOpen(station),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.frequencyDisplay,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            station.bandLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            station.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
