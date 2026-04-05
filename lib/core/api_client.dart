import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_notification.dart';
import 'backend_endpoints.dart';
import 'platform_file_utils.dart';

class ApiClient {
  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 8);

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> _get(Uri uri) =>
      _client.get(uri).timeout(_requestTimeout);

  Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      _client
          .post(uri, headers: headers, body: body)
          .timeout(_requestTimeout);

  Future<http.Response> _put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      _client
          .put(uri, headers: headers, body: body)
          .timeout(_requestTimeout);

  Future<http.Response> _delete(Uri uri) =>
      _client.delete(uri).timeout(_requestTimeout);

  Future<List<AppNotification>> fetchNotifications() async {
    final response = await _get(BackendEndpoints.notificationsUri);
    _ensureSuccess(response, 'Failed to load notifications');

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid response format for notifications');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromBackendJson)
        .toList();
  }

  Future<void> ingestNotification({
    required String appPackage,
    required String content,
    String appName = 'Unknown',
    String senderName = '',
  }) async {
    final normalizedContent = content.trim();
    if (appPackage.trim().isEmpty || normalizedContent.isEmpty) {
      return;
    }

    final response = await _post(
      BackendEndpoints.notificationsIngestUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'app_package': appPackage,
        'app_name': appName,
        'sender_name': senderName,
        'content': normalizedContent,
      }),
    );
    _ensureSuccess(response, 'Failed to ingest notification');
  }

  Future<void> enrollVoiceSample({
    required String filePath,
    required String label,
  }) async {
    final bytes = await readBytesFromPath(filePath);
    if (bytes == null || bytes.isEmpty) return;

    final request = http.MultipartRequest('POST', BackendEndpoints.voiceEnrollUri)
      ..fields['label'] = label
      ..fields['format'] = 'm4a'
      ..fields['recorded_at'] = DateTime.now().toUtc().toIso8601String()
      ..files.add(
        http.MultipartFile.fromBytes(
          'audio',
          bytes,
          filename: 'voice-${DateTime.now().millisecondsSinceEpoch}.m4a',
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    _ensureSuccess(response, 'Voice enroll failed');
  }

  Future<bool> startVoiceAssistant() async {
    http.Response? lastResponse;
    for (var attempt = 0; attempt < 2; attempt++) {
      final response = await _post(
        BackendEndpoints.aiVoiceAssistantStartUri,
        headers: {'Content-Type': 'application/json'},
        body: '{}',
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final running = decoded['running'];
            if (running is bool) {
              return running;
            }
            if (decoded['ok'] == false || decoded.containsKey('warning')) {
              return false;
            }
          }
        } catch (_) {
          // Non-JSON success response, consider start accepted.
        }
        return true;
      }

      lastResponse = response;
      final shouldRetry = response.statusCode >= 500 && attempt == 0;
      if (shouldRetry) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        continue;
      }
      break;
    }

    _ensureSuccess(lastResponse!, 'Failed to start AI assistant');
    return false;
  }

  Future<bool> isVoiceAssistantRunning() async {
    final response = await _get(BackendEndpoints.aiVoiceAssistantStatusUri);
    _ensureSuccess(response, 'Failed to fetch AI assistant status');

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid AI assistant status response');
    }
    return decoded['running'] == true;
  }

  Future<String?> transcribeVoiceAssistant({
    required String audioBase64,
    String mimeType = 'audio/webm',
  }) async {
    final response = await _post(
      BackendEndpoints.aiVoiceAssistantTranscribeUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'audio_base64': audioBase64,
        'mime_type': mimeType,
      }),
    );
    _ensureSuccess(response, 'Failed to transcribe audio');

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final transcript = decoded['transcript'];
    if (transcript is String && transcript.trim().isNotEmpty) {
      return transcript;
    }
    return null;
  }

  Future<Map<String, dynamic>> sendVoiceAssistantReaderCommand({
    required String transcript,
  }) async {
    final response = await _post(
      BackendEndpoints.aiVoiceAssistantReaderCommandUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'transcript': transcript}),
    );
    _ensureSuccess(response, 'Failed to send reader command');

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid reader command response');
    }
    return decoded;
  }

  Future<List<BackendMode>> fetchModes() async {
    final response = await _get(BackendEndpoints.modesUri);
    _ensureSuccess(response, 'Failed to load modes');

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(BackendMode.fromJson)
        .toList();
  }

  Future<BackendMode> createMode({required String name}) async {
    final payload = {
      'name': name,
      'is_active': false,
      'is_preset': false,
      'app_caps': <Map<String, dynamic>>[],
      'keywords': <String>[],
      'contact_ids': <String>[],
      'cortex_level': 'off',
      'schedule_start': '',
      'schedule_end': '',
      'schedule_days': <int>[],
    };

    final response = await _post(
      BackendEndpoints.modesUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    _ensureSuccess(response, 'Failed to create mode');
    return BackendMode.fromJson(jsonDecode(response.body));
  }

  Future<BackendMode> updateMode(BackendMode mode) async {
    final response = await _put(
      BackendEndpoints.modeByIdUri(mode.id),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(mode.toJson()),
    );
    _ensureSuccess(response, 'Failed to update mode');
    return BackendMode.fromJson(jsonDecode(response.body));
  }

  Future<void> activateMode(String modeId) async {
    final response = await _put(BackendEndpoints.activateModeUri(modeId));
    _ensureSuccess(response, 'Failed to activate mode');
  }

  Future<void> deleteMode(String modeId) async {
    final response = await _delete(BackendEndpoints.modeByIdUri(modeId));
    if (response.statusCode == 204) return;
    _ensureSuccess(response, 'Failed to delete mode');
  }

  Future<List<BackendRule>> fetchRules() async {
    final response = await _get(BackendEndpoints.rulesUri);
    _ensureSuccess(response, 'Failed to load rules');

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(BackendRule.fromJson)
        .toList();
  }

  Future<BackendRule> createRule(BackendRule rule) async {
    final response = await _post(
      BackendEndpoints.rulesUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(rule.toJson()),
    );
    _ensureSuccess(response, 'Failed to create rule');
    return BackendRule.fromJson(jsonDecode(response.body));
  }

  Future<BackendRule> updateRule(BackendRule rule) async {
    final response = await _put(
      BackendEndpoints.ruleByIdUri(rule.id),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(rule.toJson()),
    );
    _ensureSuccess(response, 'Failed to update rule');
    return BackendRule.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteRule(String id) async {
    final response = await _delete(BackendEndpoints.ruleByIdUri(id));
    if (response.statusCode == 204) return;
    _ensureSuccess(response, 'Failed to delete rule');
  }

  Future<BackendCortexConfig> fetchCortexConfig() async {
    final response = await _get(BackendEndpoints.cortexConfigUri);
    _ensureSuccess(response, 'Failed to load cortex config');
    return BackendCortexConfig.fromJson(jsonDecode(response.body));
  }

  Future<void> updateCortexConfig(BackendCortexConfig config) async {
    final response = await _put(
      BackendEndpoints.cortexConfigUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(config.toJson()),
    );
    _ensureSuccess(response, 'Failed to update cortex config');
  }

  Future<List<BackendReplyTemplate>> fetchReplyTemplates() async {
    final response = await _get(BackendEndpoints.cortexRepliesUri);
    _ensureSuccess(response, 'Failed to load reply templates');

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(BackendReplyTemplate.fromJson)
        .toList();
  }

  Future<BackendReplyTemplate> createReplyTemplate({
    required String body,
    String tone = 'casual',
  }) async {
    final response = await _post(
      BackendEndpoints.cortexRepliesUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'body': body, 'tone': tone, 'is_default': false}),
    );
    _ensureSuccess(response, 'Failed to create reply template');
    return BackendReplyTemplate.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteReplyTemplate(String id) async {
    final response = await _delete(BackendEndpoints.cortexReplyByIdUri(id));
    if (response.statusCode == 204) return;
    _ensureSuccess(response, 'Failed to delete reply template');
  }

  Future<List<BackendScheduledMessage>> fetchScheduledMessages() async {
    final response = await _get(BackendEndpoints.cortexScheduledUri);
    _ensureSuccess(response, 'Failed to load scheduled messages');

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(BackendScheduledMessage.fromJson)
        .toList();
  }

  Future<BackendScheduledMessage> createScheduledMessage({
    required String draftBody,
    required DateTime scheduledAt,
    String notificationId = 'manual',
  }) async {
    final response = await _post(
      BackendEndpoints.cortexScheduledUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'notification_id': notificationId,
        'draft_body': draftBody,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      }),
    );
    _ensureSuccess(response, 'Failed to schedule message');
    return BackendScheduledMessage.fromJson(jsonDecode(response.body));
  }

  Future<void> approveScheduledMessage(String id) async {
    final response = await _put(BackendEndpoints.approveScheduledUri(id));
    _ensureSuccess(response, 'Failed to approve scheduled message');
  }

  Future<void> cancelScheduledMessage(String id) async {
    final response = await _delete(BackendEndpoints.cancelScheduledUri(id));
    if (response.statusCode == 204) return;
    _ensureSuccess(response, 'Failed to cancel scheduled message');
  }

  Future<List<BackendActivityEntry>> fetchCortexActivity() async {
    final response = await _get(BackendEndpoints.cortexActivityUri);
    _ensureSuccess(response, 'Failed to load cortex activity');

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(BackendActivityEntry.fromJson)
        .toList();
  }

  Future<BackendUserProfile> fetchProfile() async {
    final response = await _get(BackendEndpoints.profileUri);
    _ensureSuccess(response, 'Failed to load profile');
    return BackendUserProfile.fromJson(jsonDecode(response.body));
  }

  Future<void> updateProfile(BackendUserProfile profile) async {
    final response = await _put(
      BackendEndpoints.profileUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profile.toJson()),
    );
    _ensureSuccess(response, 'Failed to update profile');
  }

  void _ensureSuccess(http.Response response, String fallbackMessage) {
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return;
    }
    String message = fallbackMessage;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is String) {
        message = decoded['error'] as String;
      }
    } catch (_) {
      // noop
    }
    throw Exception('$message (${response.statusCode})');
  }
}

class BackendMode {
  BackendMode({
    required this.id,
    required this.name,
    required this.isActive,
    required this.isPreset,
    required this.appCaps,
    required this.keywords,
    required this.contactIds,
    required this.cortexLevel,
    required this.scheduleStart,
    required this.scheduleEnd,
    required this.scheduleDays,
  });

  final String id;
  final String name;
  final bool isActive;
  final bool isPreset;
  final List<BackendAppCap> appCaps;
  final List<String> keywords;
  final List<String> contactIds;
  final String cortexLevel;
  final String scheduleStart;
  final String scheduleEnd;
  final List<int> scheduleDays;

  factory BackendMode.fromJson(Map<String, dynamic> json) => BackendMode(
    id: (json['id'] as String?) ?? '',
    name: (json['name'] as String?) ?? 'default',
    isActive: (json['is_active'] as bool?) ?? false,
    isPreset: (json['is_preset'] as bool?) ?? false,
    appCaps:
        (json['app_caps'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(BackendAppCap.fromJson)
            .toList() ??
        [],
    keywords:
        (json['keywords'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        [],
    contactIds:
        (json['contact_ids'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        [],
    cortexLevel: (json['cortex_level'] as String?) ?? 'off',
    scheduleStart: (json['schedule_start'] as String?) ?? '',
    scheduleEnd: (json['schedule_end'] as String?) ?? '',
    scheduleDays:
        (json['schedule_days'] as List?)
            ?.whereType<num>()
            .map((e) => e.toInt())
            .toList(growable: false) ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_active': isActive,
    'is_preset': isPreset,
    'app_caps': appCaps.map((e) => e.toJson()).toList(growable: false),
    'keywords': keywords,
    'contact_ids': contactIds,
    'cortex_level': cortexLevel,
    'schedule_start': scheduleStart,
    'schedule_end': scheduleEnd,
    'schedule_days': scheduleDays,
  };

  BackendMode copyWith({
    String? id,
    String? name,
    bool? isActive,
    bool? isPreset,
    List<BackendAppCap>? appCaps,
    List<String>? keywords,
    List<String>? contactIds,
    String? cortexLevel,
    String? scheduleStart,
    String? scheduleEnd,
    List<int>? scheduleDays,
  }) => BackendMode(
    id: id ?? this.id,
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
    isPreset: isPreset ?? this.isPreset,
    appCaps: appCaps ?? this.appCaps,
    keywords: keywords ?? this.keywords,
    contactIds: contactIds ?? this.contactIds,
    cortexLevel: cortexLevel ?? this.cortexLevel,
    scheduleStart: scheduleStart ?? this.scheduleStart,
    scheduleEnd: scheduleEnd ?? this.scheduleEnd,
    scheduleDays: scheduleDays ?? this.scheduleDays,
  );
}

class BackendAppCap {
  BackendAppCap({required this.appPackage, required this.maxPriority});

  final String appPackage;
  final String maxPriority;

  factory BackendAppCap.fromJson(Map<String, dynamic> json) => BackendAppCap(
    appPackage: (json['app_package'] as String?) ?? '',
    maxPriority: (json['max_priority'] as String?) ?? 'HIGH',
  );

  Map<String, dynamic> toJson() => {
    'app_package': appPackage,
    'max_priority': maxPriority,
  };
}

class BackendRule {
  BackendRule({
    required this.id,
    required this.type,
    required this.contactId,
    required this.keywords,
    required this.appPackage,
    required this.priority,
    required this.timeStart,
    required this.timeEnd,
    required this.order,
    required this.enabled,
  });

  final String id;
  final String type;
  final String contactId;
  final List<String> keywords;
  final String appPackage;
  final String priority;
  final String timeStart;
  final String timeEnd;
  final int order;
  final bool enabled;

  factory BackendRule.fromJson(Map<String, dynamic> json) => BackendRule(
    id: (json['id'] as String?) ?? '',
    type: (json['type'] as String?) ?? 'keyword',
    contactId: (json['contact_id'] as String?) ?? '',
    keywords:
        (json['keywords'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        [],
    appPackage: (json['app_package'] as String?) ?? '',
    priority: (json['priority'] as String?) ?? 'HIGH',
    timeStart: (json['time_start'] as String?) ?? '',
    timeEnd: (json['time_end'] as String?) ?? '',
    order: (json['order'] as num?)?.toInt() ?? 0,
    enabled: (json['enabled'] as bool?) ?? true,
  );

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'type': type,
    if (contactId.isNotEmpty) 'contact_id': contactId,
    if (keywords.isNotEmpty) 'keywords': keywords,
    if (appPackage.isNotEmpty) 'app_package': appPackage,
    'priority': priority,
    if (timeStart.isNotEmpty) 'time_start': timeStart,
    if (timeEnd.isNotEmpty) 'time_end': timeEnd,
    'order': order,
    'enabled': enabled,
  };

  BackendRule copyWith({
    String? id,
    String? type,
    String? contactId,
    List<String>? keywords,
    String? appPackage,
    String? priority,
    String? timeStart,
    String? timeEnd,
    int? order,
    bool? enabled,
  }) => BackendRule(
    id: id ?? this.id,
    type: type ?? this.type,
    contactId: contactId ?? this.contactId,
    keywords: keywords ?? this.keywords,
    appPackage: appPackage ?? this.appPackage,
    priority: priority ?? this.priority,
    timeStart: timeStart ?? this.timeStart,
    timeEnd: timeEnd ?? this.timeEnd,
    order: order ?? this.order,
    enabled: enabled ?? this.enabled,
  );
}

class BackendCortexConfig {
  BackendCortexConfig({
    required this.enabled,
    required this.autoReply,
    required this.scope,
  });

  final bool enabled;
  final bool autoReply;
  final String scope;

  factory BackendCortexConfig.fromJson(Map<String, dynamic> json) =>
      BackendCortexConfig(
        enabled: (json['enabled'] as bool?) ?? false,
        autoReply: (json['auto_reply'] as bool?) ?? false,
        scope: (json['scope'] as String?) ?? 'global',
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'auto_reply': autoReply,
    'scope': scope,
  };
}

class BackendReplyTemplate {
  BackendReplyTemplate({
    required this.id,
    required this.body,
    required this.tone,
    required this.isDefault,
  });

  final String id;
  final String body;
  final String tone;
  final bool isDefault;

  factory BackendReplyTemplate.fromJson(Map<String, dynamic> json) =>
      BackendReplyTemplate(
        id: (json['id'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        tone: (json['tone'] as String?) ?? 'casual',
        isDefault: (json['is_default'] as bool?) ?? false,
      );
}

class BackendScheduledMessage {
  BackendScheduledMessage({
    required this.id,
    required this.notificationId,
    required this.draftBody,
    required this.scheduledAt,
    required this.status,
  });

  final String id;
  final String notificationId;
  final String draftBody;
  final DateTime? scheduledAt;
  final String status;

  factory BackendScheduledMessage.fromJson(Map<String, dynamic> json) =>
      BackendScheduledMessage(
        id: (json['id'] as String?) ?? '',
        notificationId: (json['notification_id'] as String?) ?? '',
        draftBody: (json['draft_body'] as String?) ?? '',
        scheduledAt: DateTime.tryParse((json['scheduled_at'] as String?) ?? ''),
        status: (json['status'] as String?) ?? 'pending',
      );
}

class BackendActivityEntry {
  BackendActivityEntry({
    required this.id,
    required this.notificationId,
    required this.action,
    required this.body,
    required this.timestamp,
  });

  final String id;
  final String notificationId;
  final String action;
  final String body;
  final DateTime? timestamp;

  factory BackendActivityEntry.fromJson(Map<String, dynamic> json) =>
      BackendActivityEntry(
        id: (json['id'] as String?) ?? '',
        notificationId: (json['notification_id'] as String?) ?? '',
        action: (json['action'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? ''),
      );
}

class BackendUserProfile {
  BackendUserProfile({
    required this.displayName,
    required this.avatarPath,
    required this.notifPermission,
    required this.themeMode,
    required this.linkedAccounts,
  });

  final String displayName;
  final String avatarPath;
  final bool notifPermission;
  final String themeMode;
  final List<String> linkedAccounts;

  factory BackendUserProfile.fromJson(Map<String, dynamic> json) =>
      BackendUserProfile(
        displayName: (json['display_name'] as String?) ?? '',
        avatarPath: (json['avatar_path'] as String?) ?? '',
        notifPermission: (json['notif_permission'] as bool?) ?? false,
        themeMode: (json['theme_mode'] as String?) ?? 'system',
        linkedAccounts:
            (json['linked_accounts'] as List?)
                ?.whereType<String>()
                .toList(growable: false) ??
            [],
      );

  Map<String, dynamic> toJson() => {
    'display_name': displayName,
    'avatar_path': avatarPath,
    'notif_permission': notifPermission,
    'theme_mode': themeMode,
    'linked_accounts': linkedAccounts,
  };

  BackendUserProfile copyWith({
    String? displayName,
    String? avatarPath,
    bool? notifPermission,
    String? themeMode,
    List<String>? linkedAccounts,
  }) => BackendUserProfile(
    displayName: displayName ?? this.displayName,
    avatarPath: avatarPath ?? this.avatarPath,
    notifPermission: notifPermission ?? this.notifPermission,
    themeMode: themeMode ?? this.themeMode,
    linkedAccounts: linkedAccounts ?? this.linkedAccounts,
  );
}
