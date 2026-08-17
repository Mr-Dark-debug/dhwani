import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/dhwani_dropdown.dart';
import '../../core/widgets/dhwani_shell.dart';
import '../../data/datasources/radio_browser_api.dart';
import '../../data/models/radio_station.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landscape = constraints.maxWidth > constraints.maxHeight;
          if (landscape) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
              child: Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: BrandMark(size: 58),
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: const _WelcomeActions(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [BrandMark(size: 58), Spacer(), _WelcomeActions()],
            ),
          );
        },
      ),
    ),
  );
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Real radio,\nback home.',
        style: Theme.of(
          context,
        ).textTheme.headlineLarge?.copyWith(fontSize: 54, letterSpacing: -2.4),
      ),
      const SizedBox(height: 20),
      Text(
        'Listen to live stations from your city and the world—starting with Darbhanga.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
      ),
      const SizedBox(height: 34),
      FilledButton.icon(
        onPressed: () => context.go('/countries'),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Choose country'),
      ),
      const SizedBox(height: 12),
      Text(
        'No account. No ads. Your listening history stays on this device.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class CountryScreen extends ConsumerStatefulWidget {
  const CountryScreen({super.key});

  @override
  ConsumerState<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends ConsumerState<CountryScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Choose '),
              TextSpan(
                text: 'Country',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: .35),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _LocationContent(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search countries',
                  ),
                  onChanged: (value) =>
                      setState(() => query = value.trim().toLowerCase()),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: countries.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => _CountryList(
                      countries: const [
                        CountrySummary(
                          name: 'India',
                          code: 'IN',
                          stationCount: 0,
                        ),
                      ],
                      query: query,
                      recentCodes:
                          ref
                              .read(preferencesProvider)
                              .getStringList('recentCountries') ??
                          const [],
                    ),
                    data: (data) => _CountryList(
                      countries: data,
                      query: query,
                      recentCodes:
                          ref
                              .read(preferencesProvider)
                              .getStringList('recentCountries') ??
                          const [],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryList extends ConsumerWidget {
  const _CountryList({
    required this.countries,
    required this.query,
    required this.recentCodes,
  });
  final List<CountrySummary> countries;
  final String query;
  final List<String> recentCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = countries
        .where(
          (country) =>
              country.name.toLowerCase().contains(query) ||
              country.code.toLowerCase().contains(query),
        )
        .toList();
    if (filtered.isEmpty) {
      return const _EmptyState(
        title: 'No country found',
        action: 'Try a different spelling.',
      );
    }
    Widget row(CountrySummary country) => InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final preferences = ref.read(preferencesProvider);
        await preferences.setString('lastCountry', country.code);
        await preferences.setStringList(
          'recentCountries',
          [
            country.code,
            ...recentCodes.where((code) => code != country.code),
          ].take(5).toList(),
        );
        await ref
            .read(catalogueRepositoryProvider)
            .loadCountry(country.code)
            .catchError((_) {});
        if (!context.mounted) return;
        context.push(
          country.code == 'IN'
              ? '/states?country=IN'
              : '/stations?country=${country.code}',
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                country.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 35),
              ),
            ),
            if (country.stationCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${country.stationCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
    if (query.isNotEmpty) {
      return ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 2),
        itemBuilder: (context, index) => row(filtered[index]),
      );
    }
    final india = filtered.where((country) => country.code == 'IN').firstOrNull;
    final recent = recentCodes
        .map(
          (code) =>
              filtered.where((country) => country.code == code).firstOrNull,
        )
        .whereType<CountrySummary>()
        .where((country) => country.code != 'IN')
        .toList();
    return ListView(
      children: [
        if (india != null) ...[const _ListHeading('Suggested'), row(india)],
        if (recent.isNotEmpty) ...[
          const _ListHeading('Recent'),
          ...recent.map(row),
        ],
        const _ListHeading('All countries'),
        ...filtered.where((country) => country.code != 'IN').map(row),
      ],
    );
  }
}

class _ListHeading extends StatelessWidget {
  const _ListHeading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 6),
    child: Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        letterSpacing: 1.1,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class StateScreen extends StatelessWidget {
  const StateScreen({super.key});

  static const states = [
    'Bihar',
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose State')),
    body: SafeArea(
      child: _LocationContent(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          itemCount: states.length,
          itemBuilder: (context, index) {
            final state = states[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(state, style: Theme.of(context).textTheme.titleLarge),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(
                state == 'Bihar'
                    ? '/cities?country=IN&state=Bihar'
                    : '/stations?country=IN&state=${Uri.encodeQueryComponent(state)}',
              ),
            );
          },
        ),
      ),
    ),
  );
}

class CityScreen extends ConsumerWidget {
  const CityScreen({super.key, required this.state});
  final String state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(stationsProvider).value ?? const [];
    final discovered = stations
        .where((station) => station.state?.toLowerCase() == state.toLowerCase())
        .map((station) => station.city)
        .whereType<String>()
        .toSet();
    final cities = <String>{
      if (state == 'Bihar') ...const [
        'Darbhanga',
        'Patna',
        'Bhagalpur',
        'Purnia',
        'Muzaffarpur',
        'Sasaram',
        'Gaya',
      ],
      ...discovered,
    }.toList();
    cities.sort((a, b) {
      if (a == 'Darbhanga') return -1;
      if (b == 'Darbhanga') return 1;
      return a.compareTo(b);
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Choose City / Region')),
      body: SafeArea(
        child: _LocationContent(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
            children: [
              ...cities.map(
                (city) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    city,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(
                    '/stations?country=IN&state=${Uri.encodeQueryComponent(state)}&city=${Uri.encodeQueryComponent(city)}',
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Other / Statewide',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: const Text('Stations without reliable city metadata'),
                onTap: () => context.push(
                  '/stations?country=IN&state=${Uri.encodeQueryComponent(state)}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StationListScreen extends ConsumerStatefulWidget {
  const StationListScreen({
    super.key,
    required this.country,
    this.state,
    this.city,
  });
  final String country;
  final String? state;
  final String? city;

  @override
  ConsumerState<StationListScreen> createState() => _StationListScreenState();
}

enum StationSortMode {
  recommended('Recommended'),
  frequency('Frequency'),
  popular('Popular'),
  alphabetical('A–Z'),
  bitrate('Bitrate'),
  recentlyPlayed('Recently played'),
  savedFirst('Saved first');

  const StationSortMode(this.label);
  final String label;
}

class _StationListScreenState extends ConsumerState<StationListScreen> {
  String query = '';
  StationSortMode sortMode = StationSortMode.recommended;

  @override
  Widget build(BuildContext context) {
    final stations = ref.watch(stationsProvider);
    final title = widget.city ?? widget.state ?? widget.country;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          DhwaniDropdown<StationSortMode>(
            tooltip: 'Sort stations',
            value: sortMode,
            isPill: false,
            icon: Icons.sort_rounded,
            onSelected: (value) => setState(() => sortMode = value),
            items: StationSortMode.values
                .map(
                  (mode) => DhwaniDropdownItem(
                    value: mode,
                    label: mode.label,
                    icon: switch (mode) {
                      StationSortMode.recommended => Icons.recommend_rounded,
                      StationSortMode.frequency => Icons.sensors_rounded,
                      StationSortMode.popular => Icons.trending_up_rounded,
                      StationSortMode.alphabetical =>
                        Icons.sort_by_alpha_rounded,
                      StationSortMode.bitrate => Icons.speed_rounded,
                      StationSortMode.recentlyPlayed => Icons.history_rounded,
                      StationSortMode.savedFirst => Icons.favorite_rounded,
                    },
                  ),
                )
                .toList(),
          ),
          IconButton(
            tooltip: 'Global search',
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: SafeArea(
        child: _LocationContent(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search these stations',
                  ),
                  onChanged: (value) =>
                      setState(() => query = value.toLowerCase()),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: stations.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const _EmptyState(
                      title: 'Catalogue unavailable',
                      action: 'Cached stations will return when available.',
                    ),
                    data: (data) {
                      final favouriteIds =
                          (ref.watch(favouritesProvider).value ??
                                  const <RadioStation>[])
                              .map((station) => station.id)
                              .toSet();
                      final recentIds =
                          (ref.watch(historyProvider).value ??
                                  const <RadioStation>[])
                              .map((station) => station.id)
                              .toList();
                      final filtered =
                          data.where((station) {
                            if (station.countryCode !=
                                widget.country.toUpperCase()) {
                              return false;
                            }
                            if (widget.state != null &&
                                station.state?.toLowerCase() !=
                                    widget.state!.toLowerCase()) {
                              return false;
                            }
                            if (widget.city != null &&
                                station.city?.toLowerCase() !=
                                    widget.city!.toLowerCase()) {
                              return false;
                            }
                            return station.searchableText.contains(query);
                          }).toList()..sort(
                            (a, b) => _compareStations(
                              a,
                              b,
                              favouriteIds: favouriteIds,
                              recentIds: recentIds,
                            ),
                          );
                      if (filtered.isEmpty) {
                        return _EmptyState(
                          title: 'No stations mapped here',
                          action: widget.city == null
                              ? 'Try global search.'
                              : 'Browse ${widget.state ?? widget.country} instead.',
                        );
                      }
                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) => StationTile(
                          station: filtered[index],
                          onTap: () =>
                              _openStation(context, ref, filtered[index], data),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _compareStations(
    RadioStation a,
    RadioStation b, {
    required Set<String> favouriteIds,
    required List<String> recentIds,
  }) {
    if (sortMode == StationSortMode.recommended) {
      if (a.isDarbhanga != b.isDarbhanga) return a.isDarbhanga ? -1 : 1;
      return b.clickCount.compareTo(a.clickCount);
    }
    if (sortMode == StationSortMode.frequency) {
      final band = a.band.index.compareTo(b.band.index);
      if (band != 0) return band;
      if (a.frequency == null && b.frequency != null) return 1;
      if (a.frequency != null && b.frequency == null) return -1;
      return (a.frequency ?? double.infinity).compareTo(
        b.frequency ?? double.infinity,
      );
    }
    if (sortMode == StationSortMode.popular) {
      return b.clickCount.compareTo(a.clickCount);
    }
    if (sortMode == StationSortMode.alphabetical) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
    if (sortMode == StationSortMode.bitrate) {
      final aRate = a.streams
          .map((stream) => stream.bitrate ?? 0)
          .fold<int>(0, math.max);
      final bRate = b.streams
          .map((stream) => stream.bitrate ?? 0)
          .fold<int>(0, math.max);
      return bRate.compareTo(aRate);
    }
    if (sortMode == StationSortMode.savedFirst) {
      final saved = (favouriteIds.contains(b.id) ? 1 : 0).compareTo(
        favouriteIds.contains(a.id) ? 1 : 0,
      );
      return saved != 0 ? saved : a.name.compareTo(b.name);
    }
    int recentIndex(String id) {
      final value = recentIds.indexOf(id);
      return value < 0 ? 1 << 30 : value;
    }

    return recentIndex(a.id).compareTo(recentIndex(b.id));
  }

  Future<void> _openStation(
    BuildContext context,
    WidgetRef ref,
    RadioStation station,
    List<RadioStation> all,
  ) async {
    ref.read(selectedStationProvider.notifier).select(station);
    final queue = tuningQueue(
      all,
      current: station,
      preferredScope: ref.read(settingsProvider).defaultScope,
    );
    await ref
        .read(audioHandlerProvider)
        .setQueueStations(queue, selected: station);
    await ref.read(audioHandlerProvider).selectStation(station);
    await ref.read(catalogueRepositoryProvider).addHistory(station);
    await ref.read(preferencesProvider).setBool('onboardingComplete', true);
    await ref
        .read(preferencesProvider)
        .setString('lastStation', station.encode());
    if (context.mounted) context.go('/radio');
  }
}

class _LocationContent extends StatelessWidget {
  const _LocationContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.action});
  final String title;
  final String action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.radio_outlined, size: 42),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(action, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
