import 'package:flutter/material.dart';

import '../models/app_notification.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({
    super.key,
    required this.category,
    required this.notifications,
  });

  final NotificationCategory category;
  final List<AppNotification> notifications;

  String get _title {
    switch (category) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications in this category'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.source} • score ${item.urgencyScore + item.userRuleBoost}',
                    ),
                    trailing: Text(
                      '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
