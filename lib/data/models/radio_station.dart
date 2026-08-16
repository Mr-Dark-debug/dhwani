import 'dart:convert';

enum RadioBand { am, fm, net }

enum RadioSourceType { internetStream, remoteRfReceiver, localRecording }

enum RadioDirectory { radioBrowser, akashvani, custom, offlineSeed }

enum StationHealth {
  unknown,
  checking,
  online,
  unstable,
  offline,
  geoBlocked,
  unsupported,
}

class StationStream {
  const StationStream({
    required this.url,
    this.codec,
    this.bitrate,
    this.hls = false,
    this.lastSuccess,
    this.failureCount = 0,
  });

  final String url;
  final String? codec;
  final int? bitrate;
  final bool hls;
  final DateTime? lastSuccess;
  final int failureCount;

  bool get isSecure => Uri.tryParse(url)?.scheme == 'https';

  Map<String, Object?> toJson() => {
    'url': url,
    'codec': codec,
    'bitrate': bitrate,
    'hls': hls,
    'lastSuccess': lastSuccess?.toIso8601String(),
    'failureCount': failureCount,
  };

  factory StationStream.fromJson(Map<String, Object?> json) => StationStream(
    url: json['url'] as String? ?? '',
    codec: json['codec'] as String?,
    bitrate: (json['bitrate'] as num?)?.toInt(),
    hls: json['hls'] as bool? ?? false,
    lastSuccess: DateTime.tryParse(json['lastSuccess'] as String? ?? ''),
    failureCount: (json['failureCount'] as num?)?.toInt() ?? 0,
  );

  StationStream copyWith({DateTime? lastSuccess, int? failureCount}) =>
      StationStream(
        url: url,
        codec: codec,
        bitrate: bitrate,
        hls: hls,
        lastSuccess: lastSuccess ?? this.lastSuccess,
        failureCount: failureCount ?? this.failureCount,
      );
}

class RadioStation {
  const RadioStation({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.band,
    required this.streams,
    required this.directory,
    this.state,
    this.region,
    this.city,
    this.latitude,
    this.longitude,
    this.frequency,
    this.frequencyUnit,
    this.homepage,
    this.favicon,
    this.languages = const [],
    this.tags = const [],
    this.sourceId,
    this.verified = false,
    this.health = StationHealth.unknown,
    this.lastChecked,
    this.lastSuccessfulPlayback,
    this.failureCount = 0,
    this.userAdded = false,
    this.notes,
    this.clickCount = 0,
    this.sourceType = RadioSourceType.internetStream,
  });

  final String id;
  final String name;
  final String country;
  final String countryCode;
  final String? state;
  final String? region;
  final String? city;
  final double? latitude;
  final double? longitude;
  final RadioBand band;
  final double? frequency;
  final String? frequencyUnit;
  final List<StationStream> streams;
  final String? homepage;
  final String? favicon;
  final List<String> languages;
  final List<String> tags;
  final RadioDirectory directory;
  final String? sourceId;
  final bool verified;
  final StationHealth health;
  final DateTime? lastChecked;
  final DateTime? lastSuccessfulPlayback;
  final int failureCount;
  final bool userAdded;
  final String? notes;
  final int clickCount;
  final RadioSourceType sourceType;

  bool get canPlay => streams.any((stream) => stream.url.trim().isNotEmpty);
  bool get isDarbhanga =>
      name.toLowerCase().contains('darbhanga') && countryCode == 'IN';
  String get bandLabel => switch (band) {
    RadioBand.am => 'AM',
    RadioBand.fm => 'FM',
    RadioBand.net => 'NET',
  };
  String get frequencyDisplay => frequency == null
      ? 'LIVE'
      : frequency! % 1 == 0
      ? frequency!.toInt().toString()
      : frequency!.toStringAsFixed(1);
  String get frequencySubtitle => frequency == null
      ? 'Internet Radio'
      : '${frequencyUnit ?? (band == RadioBand.am ? 'kHz' : 'MHz')} • ${band == RadioBand.am ? 'Medium Wave' : 'FM'}';

  String get searchableText => [
    name,
    country,
    countryCode,
    state,
    region,
    city,
    frequencyDisplay,
    frequencyUnit,
    bandLabel,
    ...languages,
    ...tags,
  ].whereType<String>().join(' ').toLowerCase();

  List<StationStream> get rankedStreams {
    final result = [...streams];
    result.sort((a, b) {
      final success = (b.lastSuccess?.millisecondsSinceEpoch ?? 0).compareTo(
        a.lastSuccess?.millisecondsSinceEpoch ?? 0,
      );
      if (success != 0) return success;
      final failures = a.failureCount.compareTo(b.failureCount);
      if (failures != 0) return failures;
      return (b.isSecure ? 1 : 0).compareTo(a.isSecure ? 1 : 0);
    });
    return result;
  }

  RadioStation copyWith({
    List<StationStream>? streams,
    StationHealth? health,
    DateTime? lastChecked,
    DateTime? lastSuccessfulPlayback,
    int? failureCount,
    String? name,
    String? state,
    String? city,
    String? notes,
    bool? userAdded,
  }) => RadioStation(
    id: id,
    name: name ?? this.name,
    country: country,
    countryCode: countryCode,
    state: state ?? this.state,
    region: region,
    city: city ?? this.city,
    latitude: latitude,
    longitude: longitude,
    band: band,
    frequency: frequency,
    frequencyUnit: frequencyUnit,
    streams: streams ?? this.streams,
    homepage: homepage,
    favicon: favicon,
    languages: languages,
    tags: tags,
    directory: directory,
    sourceId: sourceId,
    verified: verified,
    health: health ?? this.health,
    lastChecked: lastChecked ?? this.lastChecked,
    lastSuccessfulPlayback:
        lastSuccessfulPlayback ?? this.lastSuccessfulPlayback,
    failureCount: failureCount ?? this.failureCount,
    userAdded: userAdded ?? this.userAdded,
    notes: notes ?? this.notes,
    clickCount: clickCount,
    sourceType: sourceType,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'countryCode': countryCode,
    'state': state,
    'region': region,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'band': band.name,
    'frequency': frequency,
    'frequencyUnit': frequencyUnit,
    'streams': streams.map((stream) => stream.toJson()).toList(),
    'homepage': homepage,
    'favicon': favicon,
    'languages': languages,
    'tags': tags,
    'directory': directory.name,
    'sourceId': sourceId,
    'verified': verified,
    'health': health.name,
    'lastChecked': lastChecked?.toIso8601String(),
    'lastSuccessfulPlayback': lastSuccessfulPlayback?.toIso8601String(),
    'failureCount': failureCount,
    'userAdded': userAdded,
    'notes': notes,
    'clickCount': clickCount,
    'sourceType': sourceType.name,
  };

  String encode() => jsonEncode(toJson());

  factory RadioStation.fromJson(Map<String, Object?> json) => RadioStation(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Unnamed station',
    country: json['country'] as String? ?? 'Unknown',
    countryCode: (json['countryCode'] as String? ?? '').toUpperCase(),
    state: json['state'] as String?,
    region: json['region'] as String?,
    city: json['city'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    band: _enumOr(RadioBand.values, json['band'], RadioBand.net),
    frequency: (json['frequency'] as num?)?.toDouble(),
    frequencyUnit: json['frequencyUnit'] as String?,
    streams: (json['streams'] as List<Object?>? ?? const [])
        .whereType<Map>()
        .map((value) => StationStream.fromJson(value.cast<String, Object?>()))
        .where((value) => value.url.isNotEmpty)
        .toList(),
    homepage: json['homepage'] as String?,
    favicon: json['favicon'] as String?,
    languages: _stringList(json['languages']),
    tags: _stringList(json['tags']),
    directory: _enumOr(
      RadioDirectory.values,
      json['directory'],
      RadioDirectory.custom,
    ),
    sourceId: json['sourceId'] as String?,
    verified: json['verified'] as bool? ?? false,
    health: _enumOr(
      StationHealth.values,
      json['health'],
      StationHealth.unknown,
    ),
    lastChecked: DateTime.tryParse(json['lastChecked'] as String? ?? ''),
    lastSuccessfulPlayback: DateTime.tryParse(
      json['lastSuccessfulPlayback'] as String? ?? '',
    ),
    failureCount: (json['failureCount'] as num?)?.toInt() ?? 0,
    userAdded: json['userAdded'] as bool? ?? false,
    notes: json['notes'] as String?,
    clickCount: (json['clickCount'] as num?)?.toInt() ?? 0,
    sourceType: _enumOr(
      RadioSourceType.values,
      json['sourceType'],
      RadioSourceType.internetStream,
    ),
  );

  factory RadioStation.decode(String value) => RadioStation.fromJson(
    (jsonDecode(value) as Map<Object?, Object?>).cast<String, Object?>(),
  );

  factory RadioStation.fromRadioBrowser(Map<String, Object?> json) {
    final name = (json['name'] as String? ?? '').trim();
    final resolved = (json['url_resolved'] as String? ?? '').trim();
    final original = (json['url'] as String? ?? '').trim();
    final urls = <String>{
      if (resolved.isNotEmpty) resolved,
      if (original.isNotEmpty) original,
    };
    final parsed = parseFrequency('$name ${json['tags'] ?? ''}');
    final codec = (json['codec'] as String?)?.trim();
    final bitrate = (json['bitrate'] as num?)?.toInt();
    return RadioStation(
      id: 'rb:${json['stationuuid']}',
      name: name.isEmpty ? 'Unnamed station' : name,
      country: (json['country'] as String? ?? 'Unknown').trim(),
      countryCode: (json['countrycode'] as String? ?? '').toUpperCase(),
      state: _nullIfBlank(json['state'] as String?),
      city: inferCity(name),
      latitude: double.tryParse('${json['geo_lat'] ?? ''}'),
      longitude: double.tryParse('${json['geo_long'] ?? ''}'),
      band: parsed.$1,
      frequency: parsed.$2,
      frequencyUnit: parsed.$3,
      streams: urls
          .map(
            (url) => StationStream(
              url: url,
              codec: codec,
              bitrate: bitrate,
              hls: url.toLowerCase().contains('.m3u8'),
            ),
          )
          .toList(),
      homepage: _nullIfBlank(json['homepage'] as String?),
      favicon: _nullIfBlank(json['favicon'] as String?),
      languages: _csv(json['language'] as String?),
      tags: _csv(json['tags'] as String?),
      directory: RadioDirectory.radioBrowser,
      sourceId: json['stationuuid'] as String?,
      verified: (json['lastcheckok'] as num?) == 1,
      health: (json['lastcheckok'] as num?) == 1
          ? StationHealth.online
          : StationHealth.unknown,
      clickCount: (json['clickcount'] as num?)?.toInt() ?? 0,
    );
  }

  factory RadioStation.fromAkashvani(Map<String, Object?> json) {
    final name = (json['name'] as String? ?? 'Akashvani').trim();
    final url = (json['stream_url'] as String? ?? '').trim();
    final isDarbhanga = name.toLowerCase().contains('darbhanga');
    return RadioStation(
      id: 'air:${json['epg_id'] ?? name.toLowerCase().replaceAll(' ', '-')}',
      name: name,
      country: 'India',
      countryCode: 'IN',
      state: _titleCase(json['state'] as String?),
      city: isDarbhanga ? 'Darbhanga' : inferCity(name),
      band: isDarbhanga ? RadioBand.am : RadioBand.net,
      frequency: isDarbhanga ? 1296 : null,
      frequencyUnit: isDarbhanga ? 'kHz' : null,
      streams: url.isEmpty
          ? const []
          : [StationStream(url: url, hls: url.toLowerCase().contains('.m3u8'))],
      homepage: _nullIfBlank(json['epg_url'] as String?),
      languages: _csv(json['language'] as String?),
      tags: const ['Akashvani', 'public radio'],
      directory: RadioDirectory.akashvani,
      sourceId: json['epg_id']?.toString(),
      verified: isDarbhanga,
    );
  }

  static (RadioBand, double?, String?) parseFrequency(String input) {
    final match = RegExp(
      r'(?<!\d)(\d{2,4}(?:[.,]\d)?)\s*(mhz|khz|fm|am)\b',
    ).firstMatch(input.toLowerCase());
    if (match == null) return (RadioBand.net, null, null);
    final number = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    final unit = match.group(2)!;
    if (unit == 'khz' || unit == 'am') return (RadioBand.am, number, 'kHz');
    return (RadioBand.fm, number, 'MHz');
  }

  static String? inferCity(String name) {
    const known = [
      'Darbhanga',
      'Patna',
      'Bhagalpur',
      'Purnia',
      'Sasaram',
      'Muzaffarpur',
      'Gaya',
    ];
    for (final city in known) {
      if (name.toLowerCase().contains(city.toLowerCase())) return city;
    }
    return null;
  }

  static List<String> _csv(String? value) => (value ?? '')
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();
  static List<String> _stringList(Object? value) =>
      (value as List<Object?>? ?? const [])
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList();
  static String? _nullIfBlank(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
  static String? _titleCase(String? value) => value
      ?.toLowerCase()
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
  static T _enumOr<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
