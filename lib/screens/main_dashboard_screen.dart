import 'dart:async';

import 'package:flutter/material.dart';

import '../core/android_notification_listener_service.dart';
import '../core/api_client.dart';
import '../core/websocket_service.dart';
import '../models/app_notification.dart';
import '../widgets/ai_orb_fab.dart';
import '../widgets/priority_card.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _tapWaveController;
  late final ApiClient _apiClient;
  late final WebsocketService _websocketService;
  StreamSubscription<AppNotification>? _wsSubscription;
  StreamSubscription<AndroidNotificationEvent>? _nativeNotificationSubscription;
  Timer? _pollTimer;
  int? _baselineTotal;

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
    WidgetsBinding.instance.addObserver(this);
    _apiClient = ApiClient();
    _websocketService = WebsocketService();
    _tapWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadFromBackend();
    _connectWebsocket();
    _connectAndroidNotificationListener();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadFromBackend(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wsSubscription?.cancel();
    _nativeNotificationSubscription?.cancel();
    _pollTimer?.cancel();
    unawaited(_websocketService.disconnect());
    _tapWaveController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadFromBackend();
      _connectAndroidNotificationListener();
    }
  }

  Future<void> _loadFromBackend() async {
    try {
      final backendItems = await _apiClient.fetchNotifications();
      if (!mounted) return;

      setState(() {
        for (final key in _notificationsByCategory.keys) {
          _notificationsByCategory[key]!.clear();
        }
        for (final item in backendItems) {
          final category = _categorize(item);
          _notificationsByCategory[category]!.add(item);
        }
      });
    } catch (_) {
      // Keep current state when backend is unavailable.
    }
  }

  void _connectWebsocket() {
    _wsSubscription?.cancel();
    _wsSubscription = _websocketService.connect().listen(
      (notification) {
        if (!mounted) return;
        _insertNotification(notification);
        unawaited(_loadFromBackend());
      },
      onError: (_) {
        if (!mounted) return;
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          _connectWebsocket();
        });
      },
      onDone: () {
        if (!mounted) return;
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          _connectWebsocket();
        });
      },
    );
  }

  Future<void> _connectAndroidNotificationListener() async {
    final enabled = await AndroidNotificationListenerService.isAccessEnabled();
    if (!enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Enable Notification Access for Cortex to capture incoming app notifications.',
          ),
          action: SnackBarAction(
            label: 'Open Settings',
            onPressed: () {
              AndroidNotificationListenerService.openAccessSettings();
            },
          ),
        ),
      );
      return;
    }

    _nativeNotificationSubscription?.cancel();
    _nativeNotificationSubscription =
        AndroidNotificationListenerService.notificationStream().listen((event) {
          unawaited(_ingestAndroidNotification(event));
        });
  }

  Future<void> _ingestAndroidNotification(AndroidNotificationEvent event) async {
    try {
      await _apiClient.ingestNotification(
        appPackage: event.appPackage,
        appName: event.appName,
        senderName: event.title,
        content: event.content,
      );
      await _loadFromBackend();
    } catch (_) {
      // keep UI responsive if backend ingest fails temporarily
    }
  }

  void _insertNotification(AppNotification notification) {
    final category = _categorize(notification);
    final key = _notificationKey(notification);
    final existing = _notificationsByCategory.values.expand((e) => e).any(
      (item) => _notificationKey(item) == key,
    );
    if (existing) return;

    setState(() {
      _notificationsByCategory[category]!.insert(0, notification);
    });
    _showNotificationPopup(notification);
  }

  void _showNotificationPopup(AppNotification notification) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Text('${notification.source}: ${notification.title}'),
      ),
    );
  }

  String _notificationKey(AppNotification n) {
    return '${n.source}|${n.title}|${n.createdAt.toIso8601String()}';
  }

  NotificationCategory _categorize(AppNotification notification) {
    final finalScore = notification.urgencyScore + notification.userRuleBoost;
    if (finalScore >= 90) return NotificationCategory.emergency;
    if (finalScore >= 70) return NotificationCategory.highPriority;
    if (finalScore >= 45) return NotificationCategory.medium;
    return NotificationCategory.low;
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
    _baselineTotal ??= total;
    final baseline = _baselineTotal;
    final sessionDeltaPercent =
      (baseline == null || baseline <= 0) ? 0 : (((total - baseline) * 100) / baseline).round();
    final focusPercent = total == 0
        ? 0.0
        : ((emergencyCount * 1.0 + highCount * 0.75 + mediumCount * 0.45) /
                  total)
              .clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomModeScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F4D52).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Custom',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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
                    highPriority: highCount,
                    medium: mediumCount,
                    low: lowCount,
                    deltaPercent: sessionDeltaPercent,
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
