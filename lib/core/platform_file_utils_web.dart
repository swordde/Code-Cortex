import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List?> readBytesFromPath(String path) async {
  if (path.isEmpty) return null;
  try {
    final response = await html.HttpRequest.request(
      path,
      method: 'GET',
      responseType: 'arraybuffer',
    );
    final buffer = response.response;
    if (buffer is ByteBuffer) {
      return Uint8List.view(buffer);
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<bool> pathExists(String? path) async {
  if (path == null || path.isEmpty) return false;
  return true;
}
