import 'package:flutter/material.dart';

import '../core/api_client.dart';

class CortexScreen extends StatefulWidget {
  const CortexScreen({super.key});

  @override
  State<CortexScreen> createState() => _CortexScreenState();
}

class _CortexScreenState extends State<CortexScreen> {
  final ApiClient _apiClient = ApiClient();

  bool _autoReplyEnabled = false;
  bool _cortexEnabled = false;
  bool _loading = true;

  List<BackendReplyTemplate> _savedReplies = [];
  List<BackendScheduledMessage> _scheduledMessages = [];
  List<BackendActivityEntry> _activity = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _refreshData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load Cortex data from backend.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1D2225) : Colors.white;
    final accentColor = const Color(0xFF0F4D52);
    final subtleColor = isDark ? const Color(0xFFAAB4BA) : const Color(0xFF7A8288);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Automatically respond to messages',
                          style: TextStyle(color: subtleColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoReplyEnabled,
                    onChanged: (value) => _updateAutoReply(value),
                    activeThumbColor: accentColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _cortexEnabled
                  ? 'Cortex is enabled on backend'
                  : 'Cortex is disabled on backend',
              style: TextStyle(color: subtleColor, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Text(
              'Saved Replies',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                        child: Icon(Icons.check, size: 14, color: accentColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reply.body,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteReply(reply),
                        icon: Icon(Icons.close, size: 18, color: subtleColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showAddReplyDialog(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.add, color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Add Reply',
                      style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scheduled Messages',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showScheduleDialog(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.add_alarm_outlined, color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Schedule Message',
                      style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._scheduledMessages.map((message) {
              final timeText = message.scheduledAt == null
                  ? '--'
                  : TimeOfDay.fromDateTime(message.scheduledAt!.toLocal()).format(context);
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
                        child: Icon(Icons.schedule, size: 20, color: accentColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.draftBody.isEmpty ? 'Scheduled reply' : message.draftBody,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message.status,
                              style: TextStyle(color: subtleColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        timeText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _approveScheduled(message),
                        icon: const Icon(Icons.check_circle_outline),
                      ),
                      IconButton(
                        onPressed: () => _cancelScheduled(message),
                        icon: const Icon(Icons.cancel_outlined),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Text(
              'Recent Cortex Activity: ${_activity.length}',
              style: TextStyle(color: subtleColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAutoReply(bool value) async {
    final prevAutoReply = _autoReplyEnabled;
    final prevCortexEnabled = _cortexEnabled;
    final next = BackendCortexConfig(
      enabled: value || _cortexEnabled,
      autoReply: value,
      scope: 'global',
    );
    setState(() {
      _autoReplyEnabled = value;
      _cortexEnabled = next.enabled;
    });
    try {
      await _apiClient.updateCortexConfig(next);
      await _refreshData();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _autoReplyEnabled = prevAutoReply;
        _cortexEnabled = prevCortexEnabled;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error, 'Failed to update auto-reply.'))),
      );
    }
  }

  Future<void> _deleteReply(BackendReplyTemplate reply) async {
    try {
      await _apiClient.deleteReplyTemplate(reply.id);
      await _refreshData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete reply.')),
      );
    }
  }

  Future<void> _approveScheduled(BackendScheduledMessage message) async {
    try {
      await _apiClient.approveScheduledMessage(message.id);
      await _refreshData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve scheduled message.')),
      );
    }
  }

  Future<void> _cancelScheduled(BackendScheduledMessage message) async {
    try {
      await _apiClient.cancelScheduledMessage(message.id);
      await _refreshData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel scheduled message.')),
      );
    }
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
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(context);
                try {
                  await _apiClient.createReplyTemplate(body: text);
                  await _refreshData();
                } catch (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(_friendlyError(error, 'Failed to add reply template.'))),
                  );
                }
              },
              child: Text('Add', style: TextStyle(color: accentColor)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showScheduleDialog(BuildContext context) async {
    final bodyController = TextEditingController();
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 1));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Schedule Message'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: bodyController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Write message to send later',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: dialogContext,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: selectedDateTime,
                      );
                      if (pickedDate == null) return;
                      if (!dialogContext.mounted) return;
                      final pickedTime = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (pickedTime == null) return;
                      if (!dialogContext.mounted) return;

                      setDialogState(() {
                        selectedDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    },
                    icon: const Icon(Icons.schedule),
                    label: Text('At: ${selectedDateTime.toLocal()}'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final draft = bodyController.text.trim();
                    if (draft.isEmpty) return;
                    try {
                      await _apiClient.createScheduledMessage(
                        draftBody: draft,
                        scheduledAt: selectedDateTime,
                      );
                      await _refreshData();
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text(_friendlyError(error, 'Failed to schedule message.'))),
                      );
                    }
                  },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );

    bodyController.dispose();
  }

  String _friendlyError(Object error, String fallback) {
    final text = error.toString();
    final lowered = text.toLowerCase();
    if (lowered.contains('connection refused') || lowered.contains('socketexception')) {
      return '$fallback Backend not reachable on localhost:8080. Start backend first.';
    }
    return '$fallback $text';
  }

  Future<void> _refreshData() async {
    final results = await Future.wait([
      _apiClient.fetchCortexConfig(),
      _apiClient.fetchReplyTemplates(),
      _apiClient.fetchScheduledMessages(),
      _apiClient.fetchCortexActivity(),
    ]);
    final cfg = results[0] as BackendCortexConfig;
    final replies = results[1] as List<BackendReplyTemplate>;
    final scheduled = results[2] as List<BackendScheduledMessage>;
    final activity = results[3] as List<BackendActivityEntry>;

    if (!mounted) return;
    setState(() {
      _cortexEnabled = cfg.enabled;
      _autoReplyEnabled = cfg.autoReply;
      _savedReplies = replies;
      _scheduledMessages = scheduled;
      _activity = activity;
    });
  }
}
