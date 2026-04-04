import 'package:flutter/material.dart';

class CortexScreen extends StatefulWidget {
  const CortexScreen({super.key});

  @override
  State<CortexScreen> createState() => _CortexScreenState();
}

class _CortexScreenState extends State<CortexScreen> {
  bool _autoReplyEnabled = true;
  List<String> _savedReplies = [
    'I\'ll call you back shortly',
    'In a meeting, will respond later',
    'On my way!',
  ];

  final List<ScheduledMessage> _scheduledMessages = [
    ScheduledMessage(
      title: 'Goodnight - family',
      subtitle: 'Every day',
      time: '9:30 PM',
      icon: Icons.nights_stay,
    ),
    ScheduledMessage(
      title: 'Morning check-in',
      subtitle: 'Weekdays',
      time: '7:00 AM',
      icon: Icons.wb_sunny,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1D2225) : Colors.white;
    final accentColor = const Color(0xFF0F4D52);
    final subtleColor = isDark ? const Color(0xFFAAB4BA) : const Color(0xFF7A8288);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cortex Mode'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header description
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'AI handles the noise for you',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: subtleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Auto Reply Section
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto Reply',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Automatically respond to messages',
                          style: TextStyle(
                            color: subtleColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoReplyEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoReplyEnabled = value;
                      });
                    },
                    activeColor: accentColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Saved Replies Section
            Text(
              'Saved Replies',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._savedReplies.map((reply) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reply,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _savedReplies.remove(reply);
                          });
                        },
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: subtleColor,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                _showAddReplyDialog(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      color: accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Reply',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Scheduled Messages Section
            Text(
              'Scheduled Messages',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._scheduledMessages.map((message) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          message.icon,
                          size: 20,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.title,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message.subtitle,
                              style: TextStyle(
                                color: subtleColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        message.time,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showAddScheduledMessageDialog(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Scheduled Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReplyDialog(BuildContext context) {
    final controller = TextEditingController();
    final accentColor = const Color(0xFF0F4D52);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Reply'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter your reply',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _savedReplies.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Add',
                style: TextStyle(color: accentColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddScheduledMessageDialog(BuildContext context) {
    final titleController = TextEditingController();
    final timeController = TextEditingController();
    final accentColor = const Color(0xFF0F4D52);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Scheduled Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Message title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  hintText: 'Time (e.g., 9:30 PM)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    timeController.text.isNotEmpty) {
                  setState(() {
                    _scheduledMessages.add(
                      ScheduledMessage(
                        title: titleController.text,
                        subtitle: 'Every day',
                        time: timeController.text,
                        icon: Icons.schedule,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Add',
                style: TextStyle(color: accentColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ScheduledMessage {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;

  ScheduledMessage({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
  });
}
