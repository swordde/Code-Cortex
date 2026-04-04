import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/app_notification.dart';
import 'backend_endpoints.dart';

class WebsocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  Stream<AppNotification> connect() {
    _channel = WebSocketChannel.connect(BackendEndpoints.websocketUri);

    return Stream<AppNotification>.multi((controller) {
      _subscription = _channel!.stream.listen(
        (event) {
          final parsed = jsonDecode(event as String);
          if (parsed is! Map<String, dynamic>) return;

          final type = parsed['type'];
          if (type != 'NEW_NOTIFICATION') return;

          final payload = parsed['payload'];
          if (payload is! Map<String, dynamic>) return;

          controller.add(AppNotification.fromBackendJson(payload));
        },
        onError: controller.addError,
        onDone: controller.close,
      );
    });
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }
}
