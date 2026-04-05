import 'dart:convert';

import 'package:cortex/core/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient voice assistant', () {
    test('returns false when start endpoint responds with degraded 202 payload', () async {
      var calls = 0;
      final mockClient = MockClient((request) async {
        calls += 1;
        expect(request.method, 'POST');
        expect(request.url.path, '/api/ai/voice-assistant/start');
        return http.Response(
          jsonEncode({
            'ok': false,
            'running': false,
            'started': false,
            'warning': 'voice assistant start unavailable upstream',
          }),
          202,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final started = await apiClient.startVoiceAssistant();

      expect(started, isFalse);
      expect(calls, 1);
    });

    test('retries once on 5xx and succeeds when second attempt is healthy', () async {
      var calls = 0;
      final mockClient = MockClient((request) async {
        calls += 1;
        expect(request.method, 'POST');
        expect(request.url.path, '/api/ai/voice-assistant/start');

        if (calls == 1) {
          return http.Response('Internal Server Error', 500);
        }

        return http.Response(
          jsonEncode({'ok': true, 'running': true, 'started': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final started = await apiClient.startVoiceAssistant();

      expect(started, isTrue);
      expect(calls, 2);
    });

    test('checks running state from status endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/ai/voice-assistant/status');
        return http.Response(
          jsonEncode({'running': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final running = await apiClient.isVoiceAssistantRunning();

      expect(running, isTrue);
    });

    test('sends transcript to reader command endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/ai/voice-assistant/reader/command');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['transcript'], 'hey cortex');

        return http.Response(
          jsonEncode({
            'action': 'wake_detected',
            'wake_active': true,
            'speech_text': 'I am listening',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final response = await apiClient.sendVoiceAssistantReaderCommand(
        transcript: 'hey cortex',
      );

      expect(response['action'], 'wake_detected');
      expect(response['wake_active'], isTrue);
      expect(response['speech_text'], 'I am listening');
    });
  });
}
