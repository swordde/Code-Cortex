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

    static Uri get notificationsIngestUri =>
      Uri.parse('http://$host:$port/api/notifications/ingest');

    static Uri notificationByIdUri(String id) =>
      Uri.parse('http://$host:$port/api/notifications/$id');

    static Uri notificationGenerateReplyUri(String id) =>
      Uri.parse('http://$host:$port/api/notifications/$id/reply');

    static Uri notificationGeneratePreviewReplyUri(String id) =>
      Uri.parse('http://$host:$port/api/notifications/$id/reply/generate');

    static Uri notificationSendReplyUri(String id) =>
      Uri.parse('http://$host:$port/api/notifications/$id/reply/send');

    static Uri get modesUri => Uri.parse('http://$host:$port/api/modes');

    static Uri modeByIdUri(String id) => Uri.parse('http://$host:$port/api/modes/$id');

    static Uri activateModeUri(String id) =>
      Uri.parse('http://$host:$port/api/modes/$id/activate');

    static Uri get rulesUri => Uri.parse('http://$host:$port/api/rules');

    static Uri ruleByIdUri(String id) => Uri.parse('http://$host:$port/api/rules/$id');

    static Uri get reorderRulesUri =>
      Uri.parse('http://$host:$port/api/rules/reorder');

    static Uri get cortexConfigUri =>
      Uri.parse('http://$host:$port/api/cortex/config');

    static Uri get cortexRepliesUri =>
      Uri.parse('http://$host:$port/api/cortex/replies');

    static Uri cortexReplyByIdUri(String id) =>
      Uri.parse('http://$host:$port/api/cortex/replies/$id');

    static Uri get cortexScheduledUri =>
      Uri.parse('http://$host:$port/api/cortex/scheduled');

    static Uri approveScheduledUri(String id) =>
      Uri.parse('http://$host:$port/api/cortex/scheduled/$id/approve');

    static Uri cancelScheduledUri(String id) =>
      Uri.parse('http://$host:$port/api/cortex/scheduled/$id');

    static Uri get cortexActivityUri =>
      Uri.parse('http://$host:$port/api/cortex/activity');

  static Uri get voiceEnrollUri =>
      Uri.parse('http://$host:$port/api/cortex/voice/enroll');

    static Uri get profileUri => Uri.parse('http://$host:$port/api/profile');

  static Uri get websocketUri => Uri.parse('ws://$host:$port/ws');

      static Uri get aiVoiceAssistantStartUri =>
        Uri.parse('http://$host:$port/api/ai/voice-assistant/start');

    static Uri get aiVoiceAssistantStatusUri =>
        Uri.parse('http://$host:$port/api/ai/voice-assistant/status');

    static Uri get aiVoiceAssistantTranscribeUri =>
        Uri.parse('http://$host:$port/api/ai/voice-assistant/transcribe');

    static Uri get aiVoiceAssistantReaderCommandUri =>
      Uri.parse('http://$host:$port/api/ai/voice-assistant/reader/command');

    static Uri get aiVoiceAssistantReaderResetUri =>
      Uri.parse('http://$host:$port/api/ai/voice-assistant/reader/reset');
}
