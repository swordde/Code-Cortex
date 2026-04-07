// Cortex AI Layer — Dart Integration Library
// Member 4 usage:
//   1. Add http package to pubspec.yaml: http: ^1.1.0
//   2. Import this file: import 'snp_api.dart';
//   3. Call functions directly: final result = await classify(content: '...', app: 'WhatsApp', mode: 'study', userId: 'user_123');
//   4. Catch SnpApiException for error handling
//   5. Change baseUrl at top of file if server IP changes

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

const String baseUrl = 'https://marisela-tiderode-mollifyingly.ngrok-free.dev';

class SnpApiException implements Exception {
  final int statusCode;
  final String message;

  SnpApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'SnpApiException(statusCode: $statusCode, message: $message)';
}

class ClassifyResponse {
  final String priority;
  final double confidence;
  final String labelReason;

  ClassifyResponse({
    required this.priority,
    required this.confidence,
    required this.labelReason,
  });

  factory ClassifyResponse.fromJson(Map<String, dynamic> json) {
    return ClassifyResponse(
      priority: (json['priority'] ?? '').toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      labelReason: (json['label_reason'] ?? '').toString(),
    );
  }
}

class CortexReplyResponse {
  final String reply;
  final String action;
  final String toneUsed;
  final String modeUsed;
  final String cortexVersion;
  final int latencyMs;

  CortexReplyResponse({
    required this.reply,
    required this.action,
    required this.toneUsed,
    required this.modeUsed,
    required this.cortexVersion,
    required this.latencyMs,
  });

  factory CortexReplyResponse.fromJson(Map<String, dynamic> json) {
    return CortexReplyResponse(
      reply: (json['reply'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      toneUsed: (json['tone_used'] ?? '').toString(),
      modeUsed: (json['mode_used'] ?? '').toString(),
      cortexVersion: (json['cortex_version'] ?? '').toString(),
      latencyMs: (json['latency_ms'] as num?)?.toInt() ?? 0,
    );
  }
}

class ModelStatusResponse {
  final int version;
  final double accuracy;
  final String lastFinetuneTimestamp;
  final int sampleCount;
  final bool modelLoaded;

  ModelStatusResponse({
    required this.version,
    required this.accuracy,
    required this.lastFinetuneTimestamp,
    required this.sampleCount,
    required this.modelLoaded,
  });

  factory ModelStatusResponse.fromJson(Map<String, dynamic> json) {
    return ModelStatusResponse(
      version: (json['version'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      lastFinetuneTimestamp: (json['last_finetune_timestamp'] ?? '').toString(),
      sampleCount: (json['sample_count'] as num?)?.toInt() ?? 0,
      modelLoaded: (json['model_loaded'] as bool?) ?? false,
    );
  }
}

class VoiceVerifyResponse {
  final bool match;
  final double confidence;
  final String userId;
  final bool locked;

  VoiceVerifyResponse({
    required this.match,
    required this.confidence,
    required this.userId,
    required this.locked,
  });

  factory VoiceVerifyResponse.fromJson(Map<String, dynamic> json) {
    return VoiceVerifyResponse(
      match: (json['match'] as bool?) ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      userId: (json['user_id'] ?? '').toString(),
      locked: (json['locked'] as bool?) ?? false,
    );
  }
}

class VoiceEnrollResponse {
  final String status;
  final String userId;
  final String enrolledAt;

  VoiceEnrollResponse({
    required this.status,
    required this.userId,
    required this.enrolledAt,
  });

  factory VoiceEnrollResponse.fromJson(Map<String, dynamic> json) {
    return VoiceEnrollResponse(
      status: (json['status'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      enrolledAt: (json['enrolled_at'] ?? '').toString(),
    );
  }
}

class FeedbackResponse {
  final String status;
  final int totalFeedbackCount;

  FeedbackResponse({required this.status, required this.totalFeedbackCount});

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      status: (json['status'] ?? '').toString(),
      totalFeedbackCount: (json['total_feedback_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class FinetuneResponse {
  final String status;
  final double newAccuracy;
  final int version;
  final double durationSeconds;

  FinetuneResponse({
    required this.status,
    required this.newAccuracy,
    required this.version,
    required this.durationSeconds,
  });

  factory FinetuneResponse.fromJson(Map<String, dynamic> json) {
    return FinetuneResponse(
      status: (json['status'] ?? '').toString(),
      newAccuracy: (json['new_accuracy'] as num?)?.toDouble() ?? 0.0,
      version: (json['version'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CortexLogEntry {
  final String timestamp;
  final String userId;
  final String app;
  final String mode;
  final String priority;
  final String action;
  final String tone;
  final String reply;
  final int latencyMs;
  final String modelVersion;

  CortexLogEntry({
    required this.timestamp,
    required this.userId,
    required this.app,
    required this.mode,
    required this.priority,
    required this.action,
    required this.tone,
    required this.reply,
    required this.latencyMs,
    required this.modelVersion,
  });

  factory CortexLogEntry.fromJson(Map<String, dynamic> json) {
    return CortexLogEntry(
      timestamp: (json['timestamp'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      app: (json['app'] ?? '').toString(),
      mode: (json['mode'] ?? '').toString(),
      priority: (json['priority'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      tone: (json['tone'] ?? '').toString(),
      reply: (json['reply'] ?? '').toString(),
      latencyMs: (json['latency_ms'] as num?)?.toInt() ?? 0,
      modelVersion: (json['model_version'] ?? '').toString(),
    );
  }
}

class VoiceAssistantStatus {
  final bool running;
  final String state;
  final String wakeWord;
  final int totalActivationsToday;

  VoiceAssistantStatus({
    required this.running,
    required this.state,
    required this.wakeWord,
    required this.totalActivationsToday,
  });

  factory VoiceAssistantStatus.fromJson(Map<String, dynamic> json) {
    return VoiceAssistantStatus(
      running: (json['running'] as bool?) ?? false,
      state: (json['state'] ?? '').toString(),
      wakeWord: (json['wake_word'] ?? '').toString(),
      totalActivationsToday: (json['total_activations_today'] as num?)?.toInt() ?? 0,
    );
  }
}

Future<http.Response> _safeGet(String path) async {
  try {
    return await http.get(Uri.parse('$baseUrl$path'));
  } on SocketException {
    throw SnpApiException(statusCode: 0, message: 'Server unreachable — is the AI server running?');
  } catch (e) {
    throw SnpApiException(statusCode: 0, message: e.toString());
  }
}

Future<http.Response> _safePost(String path, Map<String, dynamic> body) async {
  try {
    return await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  } on SocketException {
    throw SnpApiException(statusCode: 0, message: 'Server unreachable — is the AI server running?');
  } catch (e) {
    throw SnpApiException(statusCode: 0, message: e.toString());
  }
}

Map<String, dynamic> _decodeObjectOrThrow(http.Response response) {
  dynamic decoded;
  try {
    decoded = jsonDecode(response.body);
  } catch (_) {
    decoded = {'detail': 'Unknown error'};
  }

  if (response.statusCode != 200) {
    final message = decoded is Map<String, dynamic>
        ? (decoded['detail'] ?? 'Unknown error').toString()
        : 'Unknown error';
    throw SnpApiException(statusCode: response.statusCode, message: message);
  }

  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  throw SnpApiException(statusCode: response.statusCode, message: 'Unknown error');
}

List<dynamic> _decodeListOrThrow(http.Response response) {
  dynamic decoded;
  try {
    decoded = jsonDecode(response.body);
  } catch (_) {
    decoded = {'detail': 'Unknown error'};
  }

  if (response.statusCode != 200) {
    final message = decoded is Map<String, dynamic>
        ? (decoded['detail'] ?? 'Unknown error').toString()
        : 'Unknown error';
    throw SnpApiException(statusCode: response.statusCode, message: message);
  }

  if (decoded is List<dynamic>) {
    return decoded;
  }

  throw SnpApiException(statusCode: response.statusCode, message: 'Unknown error');
}

Future<ClassifyResponse> classify({
  required String content,
  required String app,
  required String mode,
  required String userId,
}) async {
  final response = await _safePost('/classify', {
    'content': content,
    'app': app,
    'mode': mode,
    'user_id': userId,
  });
  return ClassifyResponse.fromJson(_decodeObjectOrThrow(response));
}

Future<CortexReplyResponse> cortexReply({
  required String content,
  required String app,
  required String mode,
  required String priority,
  required String tone,
  required String userId,
}) async {
  final response = await _safePost('/cortex/reply', {
    'content': content,
    'app': app,
    'mode': mode,
    'priority': priority,
    'tone': tone,
    'user_id': userId,
  });
  return CortexReplyResponse.fromJson(_decodeObjectOrThrow(response));
}

Future<ModelStatusResponse> getModelStatus() async {
  final response = await _safeGet('/model/status');
  return ModelStatusResponse.fromJson(_decodeObjectOrThrow(response));
}

Future<FeedbackResponse> submitFeedback({
  required String content,
  required String app,
  required String mode,
  required String label,
  required String userId,
}) async {
  final response = await _safePost('/feedback', {
    'content': content,
    'app': app,
    'mode': mode,
    'label': label,
    'user_id': userId,
  });
  return FeedbackResponse.fromJson(_decodeObjectOrThrow(response));
}

Future<FinetuneResponse> triggerFinetune() async {
  final response = await _safePost('/finetune', {});
  return FinetuneResponse.fromJson(_decodeObjectOrThrow(response));
}

Future<VoiceEnrollResponse> voiceEnroll({
  required String userId,
  required List<String> audioSamplesBase64,
}) async {
  final response = await _safePost('/voice/enroll', {
    'user_id': userId,
    'audio_samples': audioSamplesBase64,
  });
  return VoiceEnrollResponse.fromJson(_decodeObjectOrThrow(response));
}

Future<VoiceVerifyResponse> voiceVerify({
  required String userId,
  required String audioBase64,
}) async {
  final response = await _safePost('/voice/verify', {
    'user_id': userId,
    'audio': audioBase64,
  });
  return VoiceVerifyResponse.fromJson(_decodeObjectOrThrow(response));
}

Future<List<CortexLogEntry>> getCortexLog() async {
  final response = await _safeGet('/cortex/log');
  final decoded = _decodeListOrThrow(response);
  return decoded
      .whereType<Map<String, dynamic>>()
      .map(CortexLogEntry.fromJson)
      .toList();
}

Future<VoiceAssistantStatus> getVoiceAssistantStatus() async {
  final response = await _safeGet('/voice-assistant/status');
  return VoiceAssistantStatus.fromJson(_decodeObjectOrThrow(response));
}

Future<void> startVoiceAssistant() async {
  final response = await _safePost('/voice-assistant/start', {});
  _decodeObjectOrThrow(response);
}

Future<void> stopVoiceAssistant() async {
  final response = await _safePost('/voice-assistant/stop', {});
  _decodeObjectOrThrow(response);
}

Future<String> transcribeAudio({
  required String audioBase64,
  required String mimeType,
}) async {
  final response = await _safePost('/voice-assistant/transcribe', {
    'audio_base64': audioBase64,
    'mime_type': mimeType,
  });
  final decoded = _decodeObjectOrThrow(response);
  return (decoded['transcript'] ?? '').toString();
}

Future<Map<String, dynamic>> sendReaderCommand({
  required String transcript,
}) async {
  final response = await _safePost('/voice-assistant/reader/command', {
    'transcript': transcript,
  });
  return _decodeObjectOrThrow(response);
}

Future<void> resetReader() async {
  final response = await _safePost('/voice-assistant/reader/reset', {});
  _decodeObjectOrThrow(response);
}
