import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';

enum PlaybackFailureReason {
  offline,
  timeout,
  dns,
  unauthorized,
  geoBlocked,
  notFound,
  upstream,
  tls,
  redirect,
  unsupported,
  hlsManifest,
  hlsSegment,
  cleartextPolicy,
  noStream,
  runtimeDisconnect,
  unknown,
}

class PlaybackFailure {
  const PlaybackFailure({
    required this.reason,
    required this.userTitle,
    required this.userMessage,
    required this.diagnostic,
  });

  final PlaybackFailureReason reason;
  final String userTitle;
  final String userMessage;
  final String diagnostic;

  bool get mayRetry => reason != PlaybackFailureReason.noStream;
}

PlaybackFailure classifyPlaybackFailure(Object error, {bool runtime = false}) {
  final raw = switch (error) {
    DioException(:final response, :final message) =>
      '${response?.statusCode ?? ''} ${message ?? ''}',
    PlayerException(:final code, :final message) => '$code $message',
    _ => error.toString(),
  };
  final text = raw.toLowerCase();
  final status = RegExp(r'\b([1-5]\d\d)\b').firstMatch(text)?.group(1);

  PlaybackFailure failure(
    PlaybackFailureReason reason,
    String title,
    String message,
  ) => PlaybackFailure(
    reason: reason,
    userTitle: title,
    userMessage: message,
    diagnostic: _sanitizeDiagnostic(raw),
  );

  if (error is TimeoutException || text.contains('timed out')) {
    return failure(
      PlaybackFailureReason.timeout,
      'Station unavailable right now',
      'This stream did not respond in time. Try again or move to the next station.',
    );
  }
  if (error is SocketException &&
      (text.contains('failed host lookup') ||
          text.contains('name or service not known'))) {
    return failure(
      PlaybackFailureReason.dns,
      'Station address could not be reached',
      'The station host could not be found. Check the network or try another station.',
    );
  }
  if (text.contains('network is unreachable') ||
      text.contains('no route to host') ||
      text.contains('connection offline')) {
    return failure(
      PlaybackFailureReason.offline,
      'Internet connection required',
      'Reconnect to the internet, then retry this station.',
    );
  }
  if (status == '401') {
    return failure(
      PlaybackFailureReason.unauthorized,
      'Station requires authorization',
      'This public stream did not accept the connection.',
    );
  }
  if (status == '403' || text.contains('geo') || text.contains('region')) {
    return failure(
      PlaybackFailureReason.geoBlocked,
      'Unavailable in this region',
      'This station may not be available from your current location.',
    );
  }
  if (status == '404' || status == '410') {
    return failure(
      PlaybackFailureReason.notFound,
      'Station source has moved',
      'This stream address is no longer available. Try an alternative source.',
    );
  }
  if (status != null && status.startsWith('5')) {
    return failure(
      PlaybackFailureReason.upstream,
      'Broadcaster is having trouble',
      'The station server reported a temporary problem. Please retry shortly.',
    );
  }
  if (text.contains('certificate') ||
      text.contains('handshake') ||
      text.contains('ssl') ||
      text.contains('tls')) {
    return failure(
      PlaybackFailureReason.tls,
      'Secure connection failed',
      'Dhwani could not establish a safe connection to this station.',
    );
  }
  if (text.contains('redirect')) {
    return failure(
      PlaybackFailureReason.redirect,
      'Station redirect failed',
      'The station sent Dhwani to an invalid or unavailable address.',
    );
  }
  if (text.contains('cleartext') || text.contains('not permitted')) {
    return failure(
      PlaybackFailureReason.cleartextPolicy,
      'Insecure stream blocked',
      'Android did not allow this unencrypted radio connection.',
    );
  }
  if (text.contains('m3u8') || text.contains('manifest')) {
    return failure(
      PlaybackFailureReason.hlsManifest,
      'Live playlist failed',
      'The station live playlist could not be read. Try again or use an alternative.',
    );
  }
  if (text.contains('segment')) {
    return failure(
      PlaybackFailureReason.hlsSegment,
      'Live broadcast was interrupted',
      'A live audio segment became unavailable.',
    );
  }
  if (text.contains('decoder') ||
      text.contains('codec') ||
      text.contains('format') ||
      text.contains('unrecognizedinputformat')) {
    return failure(
      PlaybackFailureReason.unsupported,
      'Stream format is unsupported',
      'This device could not decode the station audio format.',
    );
  }
  if (runtime || text.contains('connection reset') || text.contains('ended')) {
    return failure(
      PlaybackFailureReason.runtimeDisconnect,
      'Live broadcast disconnected',
      'The station stopped sending audio. Dhwani will retry only a few times.',
    );
  }
  return failure(
    PlaybackFailureReason.unknown,
    'Station unavailable right now',
    'This stream could not start. Try again or move to the next station.',
  );
}

PlaybackFailure noPlayableStreamFailure() => const PlaybackFailure(
  reason: PlaybackFailureReason.noStream,
  userTitle: 'No internet stream mapped',
  userMessage:
      'Add a valid stream URL or find another source for this station.',
  diagnostic: 'Station has no valid token-free HTTP or HTTPS stream URL.',
);

String _sanitizeDiagnostic(String value) => value.replaceAllMapped(
  RegExp(r'https?://[^\s]+', caseSensitive: false),
  (match) {
    final uri = Uri.tryParse(match.group(0)!);
    if (uri == null) return '<invalid-url>';
    return uri.replace(query: uri.hasQuery ? '<redacted>' : null).toString();
  },
);
