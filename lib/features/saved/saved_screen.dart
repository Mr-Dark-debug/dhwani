import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/widgets/dhwani_shell.dart';
import '../../data/models/radio_station.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favouritesProvider);
    final history = ref.watch(historyProvider);
    final custom = ref.watch(customStationsProvider);
    return DhwaniShell(
      title: 'Saved',
      actions: [
        IconButton(
          tooltip: 'Add custom station',
          onPressed: () => context.push('/custom-station'),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Favourites'),
                Tab(text: 'Recently played'),
                Tab(text: 'Custom'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  favourites.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const _SavedEmpty(
                      icon: Icons.cloud_off,
                      title: 'Saved stations unavailable',
                    ),
                    data: (data) => data.isEmpty
                        ? const _SavedEmpty(
                            icon: Icons.favorite_outline,
                            title: 'No favourites yet',
                            subtitle:
                                'Tap the heart on a station to keep it here.',
                          )
                        : _StationList(stations: data),
                  ),
                  history.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const _SavedEmpty(
                      icon: Icons.history,
                      title: 'History unavailable',
                    ),
                    data: (data) => data.isEmpty
                        ? const _SavedEmpty(
                            icon: Icons.history,
                            title: 'Nothing played yet',
                            subtitle:
                                'Stations you listen to will appear here.',
                          )
                        : Column(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      ref.read(databaseProvider).clearHistory(),
                                  child: const Text('Clear all'),
                                ),
                              ),
                              Expanded(child: _StationList(stations: data)),
                            ],
                          ),
                  ),
                  custom.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const _SavedEmpty(
                      icon: Icons.radio_outlined,
                      title: 'Custom stations unavailable',
                    ),
                    data: (data) => data.isEmpty
                        ? const _SavedEmpty(
                            icon: Icons.add_circle_outline,
                            title: 'No custom stations yet',
                            subtitle: 'Use + to add a stream or RF reference.',
                          )
                        : _StationList(stations: data, custom: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationList extends ConsumerWidget {
  const _StationList({required this.stations, this.custom = false});
  final List<RadioStation> stations;
  final bool custom;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
    itemCount: stations.length,
    separatorBuilder: (_, _) => const Divider(),
    itemBuilder: (context, index) {
      final station = stations[index];
      return StationTile(
        station: station,
        trailing: custom
            ? PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') {
                    context.push('/custom-station', extra: station);
                  } else {
                    context.push(
                      '/custom-station?duplicate=true',
                      extra: station,
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                ],
              )
            : null,
        onTap: () async {
          ref.read(selectedStationProvider.notifier).select(station);
          await ref
              .read(audioHandlerProvider)
              .setQueueStations(stations, selected: station);
          await ref
              .read(audioHandlerProvider)
              .selectStation(station, autoplay: true);
          if (context.mounted) context.go('/radio');
        },
      );
    },
  );
}

class _SavedEmpty extends StatelessWidget {
  const _SavedEmpty({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 50),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, textAlign: TextAlign.center),
          ],
        ],
      ),
    ),
  );
}
