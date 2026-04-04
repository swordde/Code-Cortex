import 'package:flutter/material.dart';

class CustomModeScreen extends StatefulWidget {
  const CustomModeScreen({super.key});

  @override
  State<CustomModeScreen> createState() => _CustomModeScreenState();
}

class _CustomModeScreenState extends State<CustomModeScreen> {
  String _selectedMode = 'College';
  final List<String> _modes = ['College', 'Office', 'Home'];

  final List<PrioritizableApp> _availableApps = const [
    PrioritizableApp(name: 'WhatsApp', icon: Icons.chat_bubble_outline),
    PrioritizableApp(name: 'Gmail', icon: Icons.mail_outline),
    PrioritizableApp(name: 'Messages', icon: Icons.sms_outlined),
    PrioritizableApp(name: 'Phone', icon: Icons.call_outlined),
    PrioritizableApp(name: 'Instagram', icon: Icons.camera_alt_outlined),
    PrioritizableApp(name: 'Slack', icon: Icons.work_outline),
    PrioritizableApp(name: 'Teams', icon: Icons.groups_outlined),
    PrioritizableApp(name: 'Calendar', icon: Icons.calendar_month_outlined),
    PrioritizableApp(name: 'Drive', icon: Icons.cloud_outlined),
    PrioritizableApp(name: 'Banking', icon: Icons.account_balance_outlined),
    PrioritizableApp(name: 'Telegram', icon: Icons.send_outlined),
    PrioritizableApp(name: 'Discord', icon: Icons.forum_outlined),
  ];

  final Map<String, Set<String>> _prioritizedAppsByMode = {
    'College': {'WhatsApp', 'Messages'},
    'Office': {'Gmail', 'Slack', 'Teams'},
    'Home': {'Phone'},
  };

  final Map<String, List<PriorityContact>> _contactsByMode = {
    'College': [
      PriorityContact(name: 'Mom', priority: 'Emergency'),
      PriorityContact(name: 'Professor', priority: 'High'),
      PriorityContact(name: 'Class Rep', priority: 'Medium'),
      PriorityContact(name: 'Lab Group', priority: 'Low'),
    ],
    'Office': [
      PriorityContact(name: 'Boss', priority: 'Emergency'),
      PriorityContact(name: 'Client', priority: 'High'),
      PriorityContact(name: 'Team Lead', priority: 'Medium'),
      PriorityContact(name: 'Vendor', priority: 'Low'),
    ],
    'Home': [
      PriorityContact(name: 'Family', priority: 'Emergency'),
      PriorityContact(name: 'Neighbor', priority: 'Medium'),
      PriorityContact(name: 'Community Group', priority: 'Low'),
    ],
  };

  final Map<String, List<KeywordRule>> _keywordsByMode = {
    'College': [
      KeywordRule(keyword: 'urgent', priority: 'Emergency'),
      KeywordRule(keyword: 'call me', priority: 'High'),
      KeywordRule(keyword: 'deadline', priority: 'High'),
      KeywordRule(keyword: 'exam', priority: 'High'),
      KeywordRule(keyword: 'help!', priority: 'Emergency'),
    ],
    'Office': [
      KeywordRule(keyword: 'urgent', priority: 'Emergency'),
      KeywordRule(keyword: 'deadline', priority: 'High'),
      KeywordRule(keyword: 'meeting', priority: 'High'),
    ],
    'Home': [
      KeywordRule(keyword: 'emergency', priority: 'Emergency'),
      KeywordRule(keyword: 'help', priority: 'High'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = const Color(0xFF0F4D52);
    final subtleColor = isDark
        ? const Color(0xFFAAB4BA)
        : const Color(0xFF7A8288);

    final contacts = _contactsByMode[_selectedMode] ?? [];
    final keywords = _keywordsByMode[_selectedMode] ?? [];
    final prioritizedApps = _prioritizedAppsByMode[_selectedMode] ?? <String>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Mode'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selection
            Text(
              'Select Context',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _modes.length + 1,
                itemBuilder: (context, index) {
                  if (index == _modes.length) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () {
                          _showAddModeDialog(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: accentColor, width: 2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(Icons.add, color: accentColor, size: 20),
                        ),
                      ),
                    );
                  }

                  final mode = _modes[index];
                  final isSelected = _selectedMode == mode;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMode = mode;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor : Colors.transparent,
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: subtleColor.withValues(alpha: 0.3),
                                ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          mode,
                          style: TextStyle(
                            color: isSelected ? Colors.white : subtleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Priority Contacts Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Priority Contacts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _showAddContactDialog(context);
                  },
                  child: Icon(
                    Icons.add_circle_outline,
                    color: accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  ...contacts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final contact = entry.value;

                    Color iconColor;
                    Color tagColor;
                    switch (contact.priority) {
                      case 'Emergency':
                        iconColor = const Color(0xFFFF9500);
                        tagColor = const Color(0xFFEF5350);
                        break;
                      case 'High':
                        iconColor = const Color(0xFF34A853);
                        tagColor = const Color(0xFFFFA500);
                        break;
                      case 'Medium':
                        iconColor = const Color(0xFF4F9DA6);
                        tagColor = const Color(0xFF2E7D7D);
                        break;
                      case 'Low':
                      default:
                        iconColor = const Color(0xFF9EA7AD);
                        tagColor = const Color(0xFF7E868C);
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: idx < contacts.length - 1 ? 10 : 0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: iconColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              contact.name,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: tagColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              contact.priority,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                contacts.removeAt(idx);
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Keywords Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Keywords - Priority',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _showAddKeywordDialog(context);
                  },
                  child: Icon(
                    Icons.add_circle_outline,
                    color: accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...keywords.map((keyword) {
                  final isEmergency = keyword.priority == 'Emergency';

                  return GestureDetector(
                    onLongPress: () {
                      setState(() {
                        keywords.remove(keyword);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isEmergency
                            ? const Color(0xFFEF5350).withValues(alpha: 0.15)
                            : const Color(0xFFFFA500).withValues(alpha: 0.15),
                        border: Border.all(
                          color: isEmergency
                              ? const Color(0xFFEF5350)
                              : const Color(0xFFFFA500),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            keyword.keyword,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isEmergency
                                  ? const Color(0xFFEF5350)
                                  : const Color(0xFFFFA500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isEmergency
                                  ? const Color(0xFFEF5350)
                                  : const Color(0xFFFFA500),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              keyword.priority == 'Emergency'
                                  ? 'Emergency'
                                  : 'High',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () {
                    _showAddKeywordDialog(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: accentColor,
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Prioritize Apps Section
            Text(
              'Prioritize Apps',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap apps to mark as prioritized for this mode.',
              style: TextStyle(
                color: subtleColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._availableApps.map((app) {
                  final isSelected = prioritizedApps.contains(app.name);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          prioritizedApps.remove(app.name);
                        } else {
                          prioritizedApps.add(app.name);
                        }
                        _prioritizedAppsByMode[_selectedMode] = prioritizedApps;
                      });
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 102,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withValues(alpha: 0.15)
                                : accentColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? accentColor
                                  : subtleColor.withValues(alpha: 0.2),
                              width: isSelected ? 1.6 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                app.icon,
                                color: isSelected ? accentColor : subtleColor,
                                size: 20,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                app.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? accentColor : subtleColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE4FFF7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.8),
                                ),
                              ),
                              child: Icon(
                                Icons.check,
                                size: 14,
                                color: accentColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 28),

            // Rules Info
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFA500).withValues(alpha: 0.1),
                border: Border.all(color: const Color(0xFFFFA500), width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFFFFA500),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rules override AI classification',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFA500),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Messages from priority contacts or containing keywords will be automatically classified.',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(
                              0xFFFFA500,
                            ).withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddModeDialog(BuildContext context) {
    final controller = TextEditingController();
    final accentColor = const Color(0xFF0F4D52);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Mode'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'e.g., Gym, Library',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
                    _modes.add(controller.text);
                    _contactsByMode[controller.text] = [];
                    _keywordsByMode[controller.text] = [];
                    _prioritizedAppsByMode[controller.text] = <String>{};
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Add', style: TextStyle(color: accentColor)),
            ),
          ],
        );
      },
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final contactController = TextEditingController();
    final accentColor = const Color(0xFF0F4D52);
    String selectedPriority = 'High';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Priority Contact'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: contactController,
                    decoration: InputDecoration(
                      hintText: 'Contact name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    items: ['Emergency', 'High', 'Medium', 'Low'].map((
                      priority,
                    ) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPriority = value ?? 'High';
                      });
                    },
                    decoration: InputDecoration(
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
                    if (contactController.text.isNotEmpty) {
                      this.setState(() {
                        _contactsByMode[_selectedMode]?.add(
                          PriorityContact(
                            name: contactController.text,
                            priority: selectedPriority,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add', style: TextStyle(color: accentColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddKeywordDialog(BuildContext context) {
    final keywordController = TextEditingController();
    final accentColor = const Color(0xFF0F4D52);
    String selectedPriority = 'High';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Keyword Rule'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: keywordController,
                    decoration: InputDecoration(
                      hintText: 'e.g., urgent, call me',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    items: ['Emergency', 'High'].map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPriority = value ?? 'High';
                      });
                    },
                    decoration: InputDecoration(
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
                    if (keywordController.text.isNotEmpty) {
                      this.setState(() {
                        _keywordsByMode[_selectedMode]?.add(
                          KeywordRule(
                            keyword: keywordController.text,
                            priority: selectedPriority,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add', style: TextStyle(color: accentColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class PriorityContact {
  final String name;
  final String priority;

  PriorityContact({required this.name, required this.priority});
}

class KeywordRule {
  final String keyword;
  final String priority;

  KeywordRule({required this.keyword, required this.priority});
}

class PrioritizableApp {
  final String name;
  final IconData icon;

  const PrioritizableApp({required this.name, required this.icon});
}
