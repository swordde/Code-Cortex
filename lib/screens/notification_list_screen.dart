import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/app_notification.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({
    super.key,
    required this.category,
    required this.notifications,
    required this.userId,
    this.onReplySent,
  });

  final NotificationCategory category;
  final List<AppNotification> notifications;
  final String userId;
  final Future<void> Function()? onReplySent;

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final ApiClient _apiClient = ApiClient();
  final Set<String> _sendingIds = <String>{};

  String get _title {
    switch (widget.category) {
      case NotificationCategory.emergency:
        return 'Emergency Notifications';
      case NotificationCategory.highPriority:
        return 'High Priority Notifications';
      case NotificationCategory.medium:
        return 'Medium Notifications';
      case NotificationCategory.low:
        return 'Low Notifications';
    }
  }

  Future<void> _handleGenerateReply(AppNotification item) async {
    final notificationId = item.id.trim();
    if (notificationId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply is unavailable for this notification.')),
      );
      return;
    }

    setState(() {
      _sendingIds.add(notificationId);
    });

    try {
      final result = await _apiClient.generateAndSendNotificationReply(
        notificationId: notificationId,
        userId: widget.userId,
      );
      if (!mounted) return;
      final sent = result.status == 'sent';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? 'Reply sent successfully.'
                : 'Reply generated and saved as draft.',
          ),
        ),
      );
      if (widget.onReplySent != null) {
        await widget.onReplySent!();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate reply: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingIds.remove(notificationId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: widget.notifications.isEmpty
          ? const Center(child: Text('No notifications in this category'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = widget.notifications[index];
                final sending = _sendingIds.contains(item.id);
                return Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.source} • score ${item.urgencyScore + item.userRuleBoost}',
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 32,
                          child: FilledButton(
                            onPressed: sending
                                ? null
                                : () => _handleGenerateReply(item),
                            child: Text(sending ? 'Sending...' : 'Generate Reply'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
