import 'dart:developer' as developer;

abstract final class DhwaniLog {
  static void api(String message, [Object? error, StackTrace? stack]) =>
      _write('API', message, error, stack);
  static void player(String message, [Object? error, StackTrace? stack]) =>
      _write('Player', message, error, stack);
  static void recorder(String message, [Object? error, StackTrace? stack]) =>
      _write('Recorder', message, error, stack);
  static void database(String message, [Object? error, StackTrace? stack]) =>
      _write('Database', message, error, stack);
  static void android(String message, [Object? error, StackTrace? stack]) =>
      _write('Android', message, error, stack);

  static void _write(
    String area,
    String message,
    Object? error,
    StackTrace? stack,
  ) {
    developer.log(
      '[Dhwani/$area] $message',
      name: 'Dhwani',
      error: error,
      stackTrace: stack,
    );
  }
}
