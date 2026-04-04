import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  Future<String> startRecording({required String filePrefix}) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$filePrefix-${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(),
      path: filePath,
    );

    return filePath;
  }

  Future<String?> stopRecording() async {
    return _recorder.stop();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }

  Future<bool> exists(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return false;
    return File(filePath).exists();
  }
}
