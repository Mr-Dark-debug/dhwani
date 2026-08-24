import 'dart:async';

import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';

class RecordingProcessResult {
  const RecordingProcessResult({
    required this.exitCode,
    required this.cancelled,
    required this.output,
  });

  final int? exitCode;
  final bool cancelled;
  final String output;
}

abstract interface class RecordingProcess {
  Future<RecordingProcessResult> get completed;
  Future<void> cancel();
}

abstract interface class RecordingBackend {
  Future<RecordingProcess> start(String command);
}

class FfmpegRecordingBackend implements RecordingBackend {
  const FfmpegRecordingBackend();

  @override
  Future<RecordingProcess> start(String command) async {
    final completion = Completer<RecordingProcessResult>();
    final session = await FFmpegKit.executeAsync(command, (session) async {
      final returnCode = await session.getReturnCode();
      final output = await session.getOutput() ?? '';
      if (!completion.isCompleted) {
        completion.complete(
          RecordingProcessResult(
            exitCode: returnCode?.getValue(),
            cancelled: ReturnCode.isCancel(returnCode),
            output: output,
          ),
        );
      }
    });
    final sessionId = session.getSessionId();
    if (sessionId == null) {
      throw StateError('FFmpeg did not return a recording session id.');
    }
    return _FfmpegRecordingProcess(sessionId, completion.future);
  }
}

class _FfmpegRecordingProcess implements RecordingProcess {
  const _FfmpegRecordingProcess(this.sessionId, this.completed);

  final int sessionId;

  @override
  final Future<RecordingProcessResult> completed;

  @override
  Future<void> cancel() => FFmpegKit.cancel(sessionId);
}
