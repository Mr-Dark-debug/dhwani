import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../data/models/radio_station.dart';

class CustomStationScreen extends ConsumerStatefulWidget {
  const CustomStationScreen({super.key, this.station, this.duplicate = false});

  final RadioStation? station;
  final bool duplicate;

  @override
  ConsumerState<CustomStationScreen> createState() =>
      _CustomStationScreenState();
}

class _CustomStationScreenState extends ConsumerState<CustomStationScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final country = TextEditingController();
  final state = TextEditingController();
  final city = TextEditingController();
  final language = TextEditingController();
  final frequency = TextEditingController();
  final url = TextEditingController();
  final homepage = TextEditingController();
  final notes = TextEditingController();
  RadioBand band = RadioBand.net;

  @override
  void initState() {
    super.initState();
    final value = widget.station;
    if (value == null) return;
    name.text = value.name;
    country.text = value.country;
    state.text = value.state ?? '';
    city.text = value.city ?? '';
    language.text = value.languages.join(', ');
    frequency.text = value.frequency?.toString() ?? '';
    url.text = value.streams.firstOrNull?.url ?? '';
    homepage.text = value.homepage ?? '';
    notes.text = value.notes ?? '';
    band = value.band;
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      country,
      state,
      city,
      language,
      frequency,
      url,
      homepage,
      notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.station == null || widget.duplicate
            ? 'Add Station'
            : 'Edit Station',
      ),
      actions: [
        if (widget.station != null && !widget.duplicate)
          IconButton(
            tooltip: 'Delete station',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    ),
    body: SafeArea(
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _field(name, 'Station name', required: true),
            _field(country, 'Country', required: true),
            Row(
              children: [
                Expanded(child: _field(state, 'State')),
                const SizedBox(width: 10),
                Expanded(child: _field(city, 'City')),
              ],
            ),
            _field(language, 'Languages', hint: 'Maithili, Hindi'),
            const SizedBox(height: 8),
            SegmentedButton<RadioBand>(
              segments: const [
                ButtonSegment(value: RadioBand.am, label: Text('AM')),
                ButtonSegment(value: RadioBand.fm, label: Text('FM')),
                ButtonSegment(value: RadioBand.net, label: Text('NET')),
              ],
              selected: {band},
              onSelectionChanged: (value) => setState(() => band = value.first),
            ),
            if (band != RadioBand.net)
              _field(
                frequency,
                band == RadioBand.am ? 'Frequency (kHz)' : 'Frequency (MHz)',
                keyboard: TextInputType.number,
              ),
            _field(
              url,
              'Stream URL',
              hint: 'https://…',
              validator: _urlValidator,
            ),
            _field(homepage, 'Homepage', validator: _optionalUrlValidator),
            _field(notes, 'Notes', lines: 3),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _test,
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Test Stream'),
            ),
            const SizedBox(height: 10),
            FilledButton(onPressed: _save, child: const Text('Save station')),
            const SizedBox(height: 12),
            Text(
              'A frequency without a stream is saved as reference metadata. Dhwani will not pretend the phone can receive remote RF.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool required = false,
    int lines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      maxLines: lines,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator:
          validator ??
          (required
              ? (value) => value == null || value.trim().isEmpty
                    ? '$label is required'
                    : null
              : null),
    ),
  );

  String? _urlValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        !{'http', 'https'}.contains(uri.scheme)) {
      return 'Enter an HTTP or HTTPS stream URL';
    }
    return null;
  }

  String? _optionalUrlValidator(String? value) =>
      value == null || value.trim().isEmpty ? null : _urlValidator(value);

  RadioStation _station() {
    final parsedFrequency = double.tryParse(
      frequency.text.trim().replaceAll(',', '.'),
    );
    return RadioStation(
      id: widget.station != null && !widget.duplicate
          ? widget.station!.id
          : 'custom:${const Uuid().v4()}',
      name: name.text.trim(),
      country: country.text.trim(),
      countryCode: country.text.trim().length == 2
          ? country.text.trim().toUpperCase()
          : 'XX',
      state: state.text.trim().isEmpty ? null : state.text.trim(),
      city: city.text.trim().isEmpty ? null : city.text.trim(),
      band: band,
      frequency: band == RadioBand.net ? null : parsedFrequency,
      frequencyUnit: band == RadioBand.am
          ? 'kHz'
          : band == RadioBand.fm
          ? 'MHz'
          : null,
      streams: url.text.trim().isEmpty
          ? const []
          : [
              StationStream(
                url: url.text.trim(),
                hls: url.text.toLowerCase().contains('.m3u8'),
              ),
            ],
      homepage: homepage.text.trim().isEmpty ? null : homepage.text.trim(),
      languages: language.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
      directory: RadioDirectory.custom,
      userAdded: true,
      notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
    );
  }

  Future<void> _test() async {
    if (_urlValidator(url.text) != null || url.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a valid stream URL first.')),
      );
      return;
    }
    final station = _station();
    await ref
        .read(stationPlaybackControllerProvider)
        .tune(station, queue: [station], autoplay: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Testing stream… listen for playback and check the mini player.',
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final value = _station();
    if (value.band != RadioBand.net && value.frequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid terrestrial frequency.')),
      );
      return;
    }
    if (value.streams.firstOrNull?.url.startsWith('http://') ?? false) {
      final allow = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unencrypted stream'),
          content: const Text(
            'This HTTP stream is not encrypted. Only continue if you trust the station.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save anyway'),
            ),
          ],
        ),
      );
      if (allow != true) return;
    }
    await ref.read(databaseProvider).saveCustomStation(value);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final value = widget.station;
    if (value == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete custom station?'),
        content: Text('${value.name} will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(databaseProvider).deleteCustomStation(value.id);
    if (mounted) Navigator.pop(context);
  }
}
