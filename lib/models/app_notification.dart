enum NotificationCategory { emergency, highPriority, medium, low }

class AppNotification {
  const AppNotification({
    required this.title,
    required this.source,
    required this.urgencyScore,
    required this.userRuleBoost,
    required this.createdAt,
  });

  final String title;
  final String source;
  final int urgencyScore;
  final int userRuleBoost;
  final DateTime createdAt;

  factory AppNotification.fromBackendJson(Map<String, dynamic> json) {
    final priority = (json['priority'] as String?)?.toUpperCase() ?? 'LOW';
    final urgency = switch (priority) {
      'EMERGENCY' => 95,
      'HIGH' => 75,
      'MEDIUM' => 55,
      _ => 25,
    };

    final timestampRaw = json['timestamp'];
    DateTime parsedTime;
    if (timestampRaw is String) {
      parsedTime = DateTime.tryParse(timestampRaw) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return AppNotification(
      title: (json['content'] as String?) ?? 'Notification',
      source: (json['app_name'] as String?) ?? 'Unknown',
      urgencyScore: urgency,
      userRuleBoost: 0,
      createdAt: parsedTime,
    );
  }
}
