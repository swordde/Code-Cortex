import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class InstalledApp {
  const InstalledApp({
    required this.name,
    required this.package,
  });

  final String name;
  final String package;
}

class InstalledAppsService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.cortex/installed_apps',
  );

  Future<List<InstalledApp>> fetchInstalledApps() async {
    if (kIsWeb) return const [];

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final raw = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
        if (raw == null) return const [];
        final apps = raw
            .whereType<Map>()
            .map((item) => InstalledApp(
                  name: (item['name'] as String?) ?? '',
                  package: (item['package'] as String?) ?? '',
                ))
            .where((item) => item.name.isNotEmpty && item.package.isNotEmpty)
            .toList(growable: false);
        apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return apps;
      } catch (_) {
        return const [];
      }
    }

    if (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows) {
      return _desktopApps();
    }

    return const [];
  }

  Future<List<InstalledApp>> _desktopApps() async {
    final files = <File>[];
    final dirs = <Directory>[
      Directory('/usr/share/applications'),
      Directory('/usr/local/share/applications'),
      Directory('${Platform.environment['HOME'] ?? ''}/.local/share/applications'),
    ];

    for (final dir in dirs) {
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File && entity.path.endsWith('.desktop')) {
          files.add(entity);
        }
      }
    }

    final apps = <InstalledApp>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final lines = content.split('\n');
        String? name;
        for (final line in lines) {
          if (line.startsWith('Name=')) {
            name = line.substring(5).trim();
            break;
          }
        }
        if (name == null || name.isEmpty) continue;
        final package = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last.replaceAll('.desktop', '')
            : file.path;
        apps.add(InstalledApp(name: name, package: package));
      } catch (_) {
        continue;
      }
    }

    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return apps;
  }
}
