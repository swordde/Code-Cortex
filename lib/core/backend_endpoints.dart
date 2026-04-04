import 'package:flutter/foundation.dart';

class BackendEndpoints {
  const BackendEndpoints._();

  static const String _defaultPort = '8080';

  static String get host {
    const hostOverride = String.fromEnvironment('BACKEND_HOST');
    if (hostOverride.isNotEmpty) {
      return hostOverride;
    }

    if (kIsWeb) {
      return 'localhost';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return 'localhost';
      case TargetPlatform.fuchsia:
        return 'localhost';
    }
  }

  static String get port {
    const portOverride = String.fromEnvironment('BACKEND_PORT');
    return portOverride.isEmpty ? _defaultPort : portOverride;
  }

  static Uri get notificationsUri =>
      Uri.parse('http://$host:$port/api/notifications');

  static Uri get websocketUri => Uri.parse('ws://$host:$port/ws');
}
