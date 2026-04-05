enum NotificationCategory { emergency, highPriority, medium, low }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.source,
    required this.appPackage,
    required this.priority,
    required this.confidence,
    required this.urgencyScore,
    required this.userRuleBoost,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String source;
  final String appPackage;
  final String priority;
  final double confidence;
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
      id: (json['id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? 'default',
      title: (json['content'] as String?) ?? 'Notification',
      source: (json['app_name'] as String?) ?? 'Unknown',
      appPackage: (json['app_package'] as String?) ?? '',
      priority: priority,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      urgencyScore: urgency,
      userRuleBoost: 0,
      createdAt: parsedTime,
    );
  }
}
