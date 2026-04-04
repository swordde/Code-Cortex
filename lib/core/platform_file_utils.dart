import 'dart:typed_data';

import 'platform_file_utils_stub.dart'
    if (dart.library.io) 'platform_file_utils_io.dart'
    if (dart.library.html) 'platform_file_utils_web.dart' as impl;

Future<Uint8List?> readBytesFromPath(String path) => impl.readBytesFromPath(path);

Future<bool> pathExists(String? path) => impl.pathExists(path);
