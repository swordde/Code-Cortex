import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AndroidNotificationEvent {
  AndroidNotificationEvent({
    required this.appPackage,
    required this.appName,
    required this.title,
    required this.text,
    required this.postedAt,
  });

  final String appPackage;
  final String appName;
  final String title;
  final String text;
  final DateTime postedAt;

  String get content {
    if (title.isEmpty) return text;
    if (text.isEmpty) return title;
    return '$title: $text';
  }

  factory AndroidNotificationEvent.fromMap(Map<dynamic, dynamic> map) {
    final postedAtMillis = (map['postedAt'] as num?)?.toInt();
    return AndroidNotificationEvent(
      appPackage: (map['appPackage'] as String?) ?? '',
      appName: (map['appName'] as String?) ?? 'Unknown',
      title: (map['title'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      postedAt: postedAtMillis == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(postedAtMillis),
    );
  }
}

class AndroidNotificationListenerService {
  AndroidNotificationListenerService._();

  static const MethodChannel _methodChannel = MethodChannel(
    'com.example.cortex/notification_listener',
  );

  static const EventChannel _eventChannel = EventChannel(
    'com.example.cortex/notification_events',
  );

  static Stream<AndroidNotificationEvent> notificationStream() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const Stream<AndroidNotificationEvent>.empty();
    }

    return _eventChannel.receiveBroadcastStream().where((event) {
      return event is Map<dynamic, dynamic>;
    }).map((event) {
      return AndroidNotificationEvent.fromMap(event as Map<dynamic, dynamic>);
    });
  }

  static Future<bool> isAccessEnabled() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    final enabled = await _methodChannel.invokeMethod<bool>(
      'isNotificationAccessEnabled',
    );
    return enabled ?? false;
  }

  static Future<void> openAccessSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await _methodChannel.invokeMethod('openNotificationAccessSettings');
  }
}
