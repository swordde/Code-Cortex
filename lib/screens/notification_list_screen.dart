import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
      final generated = await _apiClient.generateNotificationReply(
        notificationId: notificationId,
        userId: widget.userId,
      );
      if (!mounted) return;

      final replyToSend = await _showReplyPreviewDialog(generated.reply);
      if (!mounted) return;
      if (replyToSend == null || replyToSend.trim().isEmpty) {
        return;
      }

      final sendResult = await _apiClient.sendNotificationReply(
        notificationId: notificationId,
        userId: widget.userId,
        reply: replyToSend,
      );
      if (!mounted) return;
      final sent = sendResult.status == 'sent';
      final deliveryNote = sendResult.deliveryNote.trim();
      if (!sent) {
        await Clipboard.setData(ClipboardData(text: replyToSend));
        if (!mounted) return;
        if (_isWhatsAppNotification(item)) {
          await _openWhatsApp(item, replyToSend);
          if (!mounted) return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? 'Reply sent successfully.'
                : deliveryNote.isEmpty
                    ? 'Reply saved as draft and copied to clipboard.'
                    : 'Reply drafted and copied to clipboard: $deliveryNote',
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

  bool _isWhatsAppNotification(AppNotification item) {
    final combined = '${item.appPackage} ${item.source}'.toLowerCase();
    return combined.contains('whatsapp');
  }

  String? _extractPhoneNumber(String raw) {
    if (raw.trim().isEmpty) return null;
    final match = RegExp(r'\+?[0-9][0-9\s\-]{6,17}').firstMatch(raw);
    if (match == null) return null;
    final cleaned = match.group(0)!.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.length < 7) return null;
    return cleaned;
  }

  Future<void> _openWhatsApp(AppNotification item, String replyText) async {
    final phone = _extractPhoneNumber(item.senderName);
    final queryParams = <String, String>{'text': replyText};
    if (phone != null) {
      queryParams['phone'] = phone;
    }
    final deepLink = Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: queryParams,
    );
    try {
      final launched = await launchUrl(
        deepLink,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp automatically.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp automatically.')),
        );
      }
    }
  }

  Future<String?> _showReplyPreviewDialog(String initialReply) async {
    final controller = TextEditingController(text: initialReply);
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Generated Reply'),
            content: TextField(
              controller: controller,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Reply message',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(controller.text.trim()),
                child: const Text('Send'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
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
                            child: Text(sending ? 'Processing...' : 'Generate Reply'),
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
