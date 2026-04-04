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
}
