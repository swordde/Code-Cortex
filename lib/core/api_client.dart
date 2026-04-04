import 'dart:convert';

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
}
