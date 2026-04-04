import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readBytesFromPath(String path) async {
  try {
    return await File(path).readAsBytes();
  } catch (_) {
    return null;
  }
}

Future<bool> pathExists(String? path) async {
  if (path == null || path.isEmpty) return false;
  try {
    return await File(path).exists();
  } catch (_) {
    return false;
  }
}
