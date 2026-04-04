import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cortex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6F68)),
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        useMaterial3: true,
      ),
      home: const MainDashboardScreen(),
    );
  }
}

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

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final Random _random = Random();
  late final Timer _updatesTimer;

  final Map<NotificationCategory, List<AppNotification>>
  _notificationsByCategory = {
    NotificationCategory.emergency: [],
    NotificationCategory.highPriority: [],
    NotificationCategory.medium: [],
    NotificationCategory.low: [],
  };

  @override
  void initState() {
    super.initState();
    _seedInitialNotifications();
    _updatesTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _addIncomingNotification();
    });
  }

  @override
  void dispose() {
    _updatesTimer.cancel();
    super.dispose();
  }

  void _seedInitialNotifications() {
    final initialNotifications = [
      _makeNotification('Card transaction alert', 93, 5),
      _makeNotification('Missed medication reminder', 88, 8),
      _makeNotification('Team message: review needed', 74, 3),
      _makeNotification('Calendar task update', 59, 2),
      _makeNotification('App update available', 34, 0),
      _makeNotification('Marketing email summary', 22, 0),
    ];

    for (final item in initialNotifications) {
      final category = _categorize(item);
      _notificationsByCategory[category]!.add(item);
    }
  }

  AppNotification _makeNotification(String title, int urgency, int ruleBoost) {
    final sources = ['Bank', 'Health', 'Work', 'Social', 'System'];
    return AppNotification(
      title: title,
      source: sources[_random.nextInt(sources.length)],
      urgencyScore: urgency,
      userRuleBoost: ruleBoost,
      createdAt: DateTime.now(),
    );
  }

  NotificationCategory _categorize(AppNotification notification) {
    final finalScore = notification.urgencyScore + notification.userRuleBoost;
    if (finalScore >= 90) return NotificationCategory.emergency;
    if (finalScore >= 70) return NotificationCategory.highPriority;
    if (finalScore >= 45) return NotificationCategory.medium;
    return NotificationCategory.low;
  }

  void _addIncomingNotification() {
    if (!mounted) return;

    final templates = [
      'Payment due in 1 hour',
      'Meeting starts in 15 minutes',
      'Sleep goal reminder',
      'Delivery arriving soon',
      'Low battery warning',
      'Family message waiting',
    ];

    final urgency = 20 + _random.nextInt(76);
    final ruleBoost = _random.nextInt(16);
    final created = _makeNotification(
      templates[_random.nextInt(templates.length)],
      urgency,
      ruleBoost,
    );
    final category = _categorize(created);

    setState(() {
      _notificationsByCategory[category]!.insert(0, created);
    });
  }

  @override
  Widget build(BuildContext context) {
    final emergencyCount =
        _notificationsByCategory[NotificationCategory.emergency]!.length;
    final highCount =
        _notificationsByCategory[NotificationCategory.highPriority]!.length;
    final mediumCount =
        _notificationsByCategory[NotificationCategory.medium]!.length;
    final lowCount = _notificationsByCategory[NotificationCategory.low]!.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            icon: const CircleAvatar(
              radius: 14,
              child: Icon(Icons.person, size: 16),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WellbeingScreen()),
            );
          }
        },
        onLongPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomModeScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  _QuickFilterDot(icon: Icons.work_outline),
                  SizedBox(width: 10),
                  _QuickFilterDot(icon: Icons.favorite_outline),
                  SizedBox(width: 10),
                  _QuickFilterDot(icon: Icons.notifications_none),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PriorityCard(
                            label: 'Emergency',
                            count: emergencyCount,
                            subtitle: 'Needs attention now',
                            background: const Color(0xFFF8DFDF),
                            foreground: const Color(0xFFBD3124),
                            isLarge: true,
                            onTap: () =>
                                _openCategory(NotificationCategory.emergency),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PriorityCard(
                            label: 'High Priority',
                            count: highCount,
                            subtitle: 'Respond soon',
                            background: const Color(0xFFF7ECCC),
                            foreground: const Color(0xFFB56D00),
                            isLarge: true,
                            onTap: () => _openCategory(
                              NotificationCategory.highPriority,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PriorityCard(
                            label: 'Medium',
                            count: mediumCount,
                            subtitle: 'Keep track',
                            background: const Color(0xFFDCEEEE),
                            foreground: const Color(0xFF1A6666),
                            isLarge: false,
                            onTap: () =>
                                _openCategory(NotificationCategory.medium),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PriorityCard(
                            label: 'Low',
                            count: lowCount,
                            subtitle: 'No hurry',
                            background: const Color(0xFFEDEDED),
                            foreground: const Color(0xFF767676),
                            isLarge: false,
                            onTap: () =>
                                _openCategory(NotificationCategory.low),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI assistant quick action')),
          );
        },
        child: const Icon(Icons.auto_awesome),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.dashboard_customize),
              SizedBox(width: 48),
              Icon(Icons.menu),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategory(NotificationCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationListScreen(
          category: category,
          notifications: _notificationsByCategory[category]!,
        ),
      ),
    );
  }
}

class _QuickFilterDot extends StatelessWidget {
  const _QuickFilterDot({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.white,
      child: Icon(icon, size: 16, color: const Color(0xFF2C2C2C)),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({
    required this.label,
    required this.count,
    required this.subtitle,
    required this.background,
    required this.foreground,
    required this.isLarge,
    required this.onTap,
  });

  final String label;
  final int count;
  final String subtitle;
  final Color background;
  final Color foreground;
  final bool isLarge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.all(isLarge ? 18 : 14),
        height: isLarge ? 170 : 120,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                color: foreground,
                fontSize: isLarge ? 40 : 32,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const Spacer(),
            Text(
              subtitle,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class WellbeingScreen extends StatelessWidget {
  const WellbeingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics / Digital Wellbeing')),
      body: const Center(child: Text('Screen 2 placeholder')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Screen 3 placeholder')),
    );
  }
}

class CustomModeScreen extends StatelessWidget {
  const CustomModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Mode')),
      body: const Center(child: Text('Screen 4 placeholder')),
    );
  }
}
