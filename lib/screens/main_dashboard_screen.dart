import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../widgets/ai_orb_fab.dart';
import '../widgets/priority_card.dart';
import '../widgets/quick_filter_dot.dart';
import '../widgets/today_notification_card.dart';
import '../widgets/wellbeing_section.dart';
import 'cortex_screen.dart';
import 'custom_mode_screen.dart';
import 'notification_list_screen.dart';
import 'profile_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  late final Timer _updatesTimer;
  late final AnimationController _tapWaveController;

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
    _tapWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _seedInitialNotifications();
    _updatesTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _addIncomingNotification();
    });
  }

  @override
  void dispose() {
    _updatesTimer.cancel();
    _tapWaveController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emergencyCount =
        _notificationsByCategory[NotificationCategory.emergency]!.length;
    final highCount =
        _notificationsByCategory[NotificationCategory.highPriority]!.length;
    final mediumCount =
        _notificationsByCategory[NotificationCategory.medium]!.length;
    final lowCount = _notificationsByCategory[NotificationCategory.low]!.length;
    final needingAttention = emergencyCount + highCount;
    final total = emergencyCount + highCount + mediumCount + lowCount;
    final focusPercent = total == 0
        ? 0.0
        : ((emergencyCount * 1.0 + highCount * 0.75 + mediumCount * 0.45) /
                  total)
              .clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Cortex Mode',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CortexScreen()),
              );
            },
            icon: const Icon(Icons.psychology_outlined),
          ),
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
        behavior: HitTestBehavior.translucent,
        onLongPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomModeScreen()),
          );
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      QuickFilterDot(icon: Icons.work_outline),
                      SizedBox(width: 10),
                      QuickFilterDot(icon: Icons.favorite_outline),
                      SizedBox(width: 10),
                      QuickFilterDot(icon: Icons.notifications_none),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TodayNotificationCard(
                    needingAttention: needingAttention,
                    focusPercent: focusPercent,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PriorityCard(
                          label: 'Emergency',
                          count: emergencyCount,
                          subtitle: 'Needs attention now',
                          background: isDark
                              ? const Color(0xFF462A2A)
                              : const Color(0xFFF8DFDF),
                          foreground: isDark
                              ? const Color(0xFFFF8E86)
                              : const Color(0xFFBD3124),
                          isLarge: true,
                          onTap: () =>
                              _openCategory(NotificationCategory.emergency),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PriorityCard(
                          label: 'High Priority',
                          count: highCount,
                          subtitle: 'Respond soon',
                          background: isDark
                              ? const Color(0xFF4A3D21)
                              : const Color(0xFFF7ECCC),
                          foreground: isDark
                              ? const Color(0xFFFFC45A)
                              : const Color(0xFFB56D00),
                          isLarge: true,
                          onTap: () =>
                              _openCategory(NotificationCategory.highPriority),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PriorityCard(
                          label: 'Medium',
                          count: mediumCount,
                          subtitle: 'Keep track',
                          background: isDark
                              ? const Color(0xFF203A3A)
                              : const Color(0xFFDCEEEE),
                          foreground: isDark
                              ? const Color(0xFF74D7D7)
                              : const Color(0xFF1A6666),
                          isLarge: false,
                          onTap: () =>
                              _openCategory(NotificationCategory.medium),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PriorityCard(
                          label: 'Low',
                          count: lowCount,
                          subtitle: 'No hurry',
                          background: isDark
                              ? const Color(0xFF2D3033)
                              : const Color(0xFFEDEDED),
                          foreground: isDark
                              ? const Color(0xFFBCC2C7)
                              : const Color(0xFF767676),
                          isLarge: false,
                          onTap: () => _openCategory(NotificationCategory.low),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  WellbeingSection(
                    total: total,
                    urgent: emergencyCount,
                    weeklyDeltaPercent: -23,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _tapWaveController,
                builder: (context, _) {
                  if (_tapWaveController.value == 0) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox.expand(
                    child: CustomPaint(
                      painter: _ScreenWavePainter(
                        progress: _tapWaveController.value,
                        isDark: isDark,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AiOrbFab(
        onTap: () {
          _tapWaveController.forward(from: 0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI assistant quick action')),
          );
        },
      ),
      bottomNavigationBar: SizedBox(height: isDark ? 20 : 14),
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

class _ScreenWavePainter extends CustomPainter {
  _ScreenWavePainter({required this.progress, required this.isDark});

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 72);
    final maxRadius = size.longestSide * 0.95;

    final outer = Paint()
      ..color = (isDark ? const Color(0xFF8A3FFC) : const Color(0xFF6F4EFF))
          .withValues(alpha: (1 - progress) * 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final inner = Paint()
      ..color = const Color(0xFF30D6FF).withValues(alpha: (1 - progress) * 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final glow = Paint()
      ..color = const Color(0xFFD05BFF).withValues(alpha: (1 - progress) * 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius * progress, outer);
    canvas.drawCircle(center, maxRadius * (progress * 0.8), inner);
    canvas.drawCircle(center, maxRadius * (progress * 0.55), glow);
  }

  @override
  bool shouldRepaint(covariant _ScreenWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
