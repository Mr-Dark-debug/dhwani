import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/persistence/app_database.dart';
import '../../core/widgets/dhwani_shell.dart';
import '../../data/models/radio_station.dart';
import 'package:uuid/uuid.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favouritesProvider);
    final history = ref.watch(historySummariesProvider);
    final custom = ref.watch(customStationsProvider);
    final collections = ref.watch(collectionsProvider);
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
        length: 4,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Favourites'),
                Tab(text: 'Recents'),
                Tab(text: 'Collections'),
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
                        : _FavouriteList(stations: data),
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
                              Expanded(child: _HistoryList(entries: data)),
                            ],
                          ),
                  ),
                  collections.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const _SavedEmpty(
                      icon: Icons.folder_off_outlined,
                      title: 'Collections unavailable',
                    ),
                    data: (data) => _CollectionsList(collections: data),
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

enum _FavouriteSort { custom, alphabetical, frequency }

class _FavouriteList extends ConsumerStatefulWidget {
  const _FavouriteList({required this.stations});
  final List<RadioStation> stations;

  @override
  ConsumerState<_FavouriteList> createState() => _FavouriteListState();
}

class _FavouriteListState extends ConsumerState<_FavouriteList> {
  String query = '';
  _FavouriteSort sort = _FavouriteSort.custom;

  @override
  Widget build(BuildContext context) {
    final stations = widget.stations
        .where(
          (station) => station.searchableText.contains(query.toLowerCase()),
        )
        .toList();
    if (sort == _FavouriteSort.alphabetical) {
      stations.sort((a, b) => a.name.compareTo(b.name));
    } else if (sort == _FavouriteSort.frequency) {
      stations.sort((a, b) {
        if (a.frequency == null && b.frequency != null) return 1;
        if (a.frequency != null && b.frequency == null) return -1;
        return (a.frequency ?? double.infinity).compareTo(
          b.frequency ?? double.infinity,
        );
      });
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search favourites',
                  ),
                  onChanged: (value) => setState(() => query = value.trim()),
                ),
              ),
              PopupMenuButton<_FavouriteSort>(
                tooltip: 'Sort favourites',
                initialValue: sort,
                onSelected: (value) => setState(() => sort = value),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _FavouriteSort.custom,
                    child: Text('Custom order'),
                  ),
                  PopupMenuItem(
                    value: _FavouriteSort.alphabetical,
                    child: Text('A–Z'),
                  ),
                  PopupMenuItem(
                    value: _FavouriteSort.frequency,
                    child: Text('Frequency'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (stations.isEmpty)
          const Expanded(
            child: _SavedEmpty(
              icon: Icons.search_off_rounded,
              title: 'No matching favourites',
            ),
          )
        else
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              buildDefaultDragHandles:
                  sort == _FavouriteSort.custom && query.isEmpty,
              itemCount: stations.length,
              onReorder: sort == _FavouriteSort.custom && query.isEmpty
                  ? (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex--;
                      final reordered = [...stations];
                      final moved = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, moved);
                      await ref
                          .read(databaseProvider)
                          .reorderFavourites(
                            reordered.map((item) => item.id).toList(),
                          );
                    }
                  : (_, _) {},
              itemBuilder: (context, index) {
                final station = stations[index];
                return Column(
                  key: ValueKey(station.id),
                  children: [
                    StationTile(
                      station: station,
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'collection') {
                            await _addToCollection(context, station);
                          } else if (action == 'remove') {
                            await ref
                                .read(catalogueRepositoryProvider)
                                .favourite(station, false);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'collection',
                            child: Text('Add to collection'),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove favourite'),
                          ),
                        ],
                      ),
                      onTap: () =>
                          _openStation(context, ref, station, stations),
                    ),
                    if (index < stations.length - 1) const Divider(),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _addToCollection(
    BuildContext context,
    RadioStation station,
  ) async {
    final collections = ref.read(collectionsProvider).value ?? const [];
    if (collections.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create a collection first.')),
        );
      }
      return;
    }
    final selected = await showModalBottomSheet<StationCollectionSummary>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Add to collection')),
            ...collections.map(
              (collection) => ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(collection.name),
                subtitle: Text('${collection.stationCount} stations'),
                onTap: () => Navigator.pop(context, collection),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await ref.read(databaseProvider).addToCollection(selected.id, station);
    }
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.entries});
  final List<HistorySummary> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
    itemCount: entries.length,
    separatorBuilder: (_, _) => const Divider(),
    itemBuilder: (context, index) {
      final entry = entries[index];
      return StationTile(
        station: entry.station,
        subtitle:
            '${entry.playCount} play${entry.playCount == 1 ? '' : 's'} · '
            '${entry.totalDuration.inMinutes} min listened · '
            '${entry.lastPlayedAt.toLocal().toString().split('.').first}',
        trailing: PopupMenuButton<String>(
          onSelected: (_) => ref
              .read(databaseProvider)
              .deleteHistoryForStation(entry.station.id),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'remove', child: Text('Remove from history')),
          ],
        ),
        onTap: () => _openStation(
          context,
          ref,
          entry.station,
          entries.map((item) => item.station).toList(),
        ),
      );
    },
  );
}

class _CollectionsList extends ConsumerWidget {
  const _CollectionsList({required this.collections});
  final List<StationCollectionSummary> collections;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
    children: [
      FilledButton.icon(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('New collection'),
      ),
      const SizedBox(height: 12),
      if (collections.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 72),
          child: _SavedEmpty(
            icon: Icons.folder_outlined,
            title: 'No collections yet',
            subtitle: 'Create Home, Bihar, News, Music, Dadaji—or your own.',
          ),
        ),
      ...collections.map(
        (collection) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_outlined),
          title: Text(collection.name),
          subtitle: Text('${collection.stationCount} stations'),
          onTap: () => _open(context, ref, collection),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => value == 'rename'
                ? _rename(context, ref, collection)
                : ref.read(databaseProvider).deleteCollection(collection.id),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    ],
  );

  Future<String?> _nameDialog(
    BuildContext context,
    String title, [
    String value = '',
  ]) {
    final controller = TextEditingController(text: value);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Collection name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await _nameDialog(context, 'New collection');
    if (name == null || name.isEmpty) return;
    await ref.read(databaseProvider).createCollection(const Uuid().v4(), name);
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    StationCollectionSummary collection,
  ) async {
    final name = await _nameDialog(
      context,
      'Rename collection',
      collection.name,
    );
    if (name == null || name.isEmpty) return;
    await ref.read(databaseProvider).renameCollection(collection.id, name);
  }

  void _open(
    BuildContext context,
    WidgetRef ref,
    StationCollectionSummary collection,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        maxChildSize: .95,
        builder: (context, controller) => StreamBuilder<List<RadioStation>>(
          stream: ref
              .read(databaseProvider)
              .watchCollectionStations(collection.id),
          builder: (context, snapshot) {
            final stations = snapshot.data ?? const [];
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                Text(
                  collection.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                if (stations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: _SavedEmpty(
                      icon: Icons.radio_outlined,
                      title: 'No stations here yet',
                      subtitle: 'Use a favourite station’s menu to add it.',
                    ),
                  ),
                ...stations.map(
                  (station) => StationTile(
                    station: station,
                    trailing: IconButton(
                      tooltip: 'Remove from collection',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => ref
                          .read(databaseProvider)
                          .removeFromCollection(collection.id, station.id),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _openStation(context, ref, station, stations);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> _openStation(
  BuildContext context,
  WidgetRef ref,
  RadioStation station,
  List<RadioStation> stations,
) async {
  ref.read(selectedStationProvider.notifier).select(station);
  await ref
      .read(audioHandlerProvider)
      .setQueueStations(stations, selected: station);
  await ref.read(audioHandlerProvider).selectStation(station, autoplay: true);
  await ref.read(catalogueRepositoryProvider).addHistory(station);
  if (context.mounted) context.go('/radio');
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
