import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const _historyKey = 'recentSearches';
  Timer? debounce;
  final controller = TextEditingController();
  List<RadioStation> results = const [];
  List<String> recent = const [];
  bool loading = false;
  String query = '';
  int requestId = 0;

  @override
  void initState() {
    super.initState();
    recent =
        ref.read(preferencesProvider).getStringList(_historyKey) ?? const [];
  }

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
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
              controller: controller,
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
              Expanded(
                child: _Suggestions(
                  recent: recent,
                  onSearch: _submitSuggestion,
                  onClear: recent.isEmpty ? null : _clearRecent,
                ),
              )
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
    final currentRequest = ++requestId;
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
      final repository = ref.read(catalogueRepositoryProvider);
      final local = await repository.searchLocal(query);
      if (mounted && currentRequest == requestId) {
        setState(() {
          results = local;
        });
      }
      if (query.length < 3) {
        if (mounted && currentRequest == requestId) {
          setState(() => loading = false);
        }
        return;
      }
      final data = await repository.searchRemote(query, localResults: local);
      if (mounted && currentRequest == requestId) {
        setState(() {
          results = data;
          loading = false;
        });
      }
    });
  }

  void _submitSuggestion(String value) {
    controller.text = value;
    controller.selection = TextSelection.collapsed(offset: value.length);
    _search(value);
  }

  Future<void> _remember(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    final updated = [
      normalized,
      ...recent.where((item) => item.toLowerCase() != normalized.toLowerCase()),
    ].take(10).toList();
    await ref.read(preferencesProvider).setStringList(_historyKey, updated);
    if (mounted) setState(() => recent = updated);
  }

  Future<void> _clearRecent() async {
    await ref.read(preferencesProvider).remove(_historyKey);
    if (mounted) setState(() => recent = const []);
  }

  Future<void> _open(RadioStation station) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await _remember(query);
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
  const _Suggestions({
    required this.recent,
    required this.onSearch,
    required this.onClear,
  });

  final List<String> recent;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    const suggestions = [
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
    ];
    return ListView(
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Text('Recent', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(onPressed: onClear, child: const Text('Clear')),
            ],
          ),
          ...recent.map(
            (text) => ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(text),
              trailing: const Icon(Icons.north_west_rounded, size: 18),
              onTap: () => onSearch(text),
            ),
          ),
          const Divider(),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Try searching',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...suggestions.map(
          (text) => ListTile(
            leading: const Icon(Icons.search_rounded),
            title: Text(text),
            trailing: const Icon(Icons.north_west_rounded, size: 18),
            onTap: () => onSearch(text),
          ),
        ),
      ],
    );
  }
}
