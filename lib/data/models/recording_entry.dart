import 'radio_station.dart';

class RecordingEntry {
  const RecordingEntry({
    required this.id,
    required this.station,
    required this.path,
    required this.name,
    required this.createdAt,
    required this.duration,
    required this.sizeBytes,
    required this.format,
  });

  final String id;
  final RadioStation station;
  final String path;
  final String name;
  final DateTime createdAt;
  final Duration duration;
  final int sizeBytes;
  final String format;

  String get sizeLabel {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
  }
}
