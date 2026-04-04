import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/app_notification.dart';
import 'backend_endpoints.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<List<AppNotification>> fetchNotifications() async {
    final response = await _client.get(BackendEndpoints.notificationsUri);
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception('Failed to load notifications (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid response format for notifications');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromBackendJson)
        .toList();
  }

  Future<void> enrollVoiceSample({
    required String filePath,
    required String label,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    final payload = {
      'label': label,
      'audio_base64': base64Encode(bytes),
      'format': 'm4a',
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _client.post(
      BackendEndpoints.voiceEnrollUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception('Voice enroll failed (${response.statusCode})');
    }
  }
}
