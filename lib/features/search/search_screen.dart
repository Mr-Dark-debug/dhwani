import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/widgets/dhwani_shell.dart';
import '../../data/models/radio_station.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  Timer? debounce;
  List<RadioStation> results = const [];
  bool loading = false;
  String query = '';

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Search')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          children: [
            TextField(
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Station, city, 1296 AM, language…',
                suffixIcon: loading
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 12),
            if (query.isEmpty)
              const Expanded(child: _Suggestions())
            else if (results.isEmpty && !loading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 44),
                      const SizedBox(height: 12),
                      Text(
                        'No stations found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Text(
                        'Try a city, language, station name, or frequency.',
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) => StationTile(
                    station: results[index],
                    onTap: () => _open(results[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  void _search(String value) {
    query = value.trim();
    debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        loading = false;
        results = const [];
      });
      return;
    }
    setState(() => loading = true);
    debounce = Timer(const Duration(milliseconds: 420), () async {
      final data = await ref.read(catalogueRepositoryProvider).search(query);
      if (mounted) {
        setState(() {
          results = data;
          loading = false;
        });
      }
    });
  }

  Future<void> _open(RadioStation station) async {
    ref.read(selectedStationProvider.notifier).select(station);
    await ref
        .read(audioHandlerProvider)
        .setQueueStations(results, selected: station);
    await ref.read(audioHandlerProvider).selectStation(station);
    await ref.read(catalogueRepositoryProvider).addHistory(station);
    if (mounted) context.go('/radio');
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions();
  @override
  Widget build(BuildContext context) => ListView(
    children:
        const [
              'Darbhanga',
              '1296 AM',
              'Bihar',
              'Maithili',
              'Hindi',
              'Akashvani',
              'BBC',
              'Jazz',
              'News',
              'Germany',
            ]
            .map(
              (text) => ListTile(
                leading: const Icon(Icons.north_west_rounded),
                title: Text(text),
              ),
            )
            .toList(),
  );
}
