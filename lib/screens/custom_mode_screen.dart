import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';

class CustomModeScreen extends StatefulWidget {
  const CustomModeScreen({super.key});

  @override
  State<CustomModeScreen> createState() => _CustomModeScreenState();
}

class _CustomModeScreenState extends State<CustomModeScreen> {
  final ApiClient _apiClient = ApiClient();

  String _selectedMode = '';
  final List<String> _modes = [];
  final Map<String, BackendMode> _backendModesByDisplay = {};

  final List<PrioritizableApp> _availableApps = const [
    PrioritizableApp(name: 'WhatsApp', icon: Icons.chat_bubble_outline, package: 'com.whatsapp'),
    PrioritizableApp(name: 'Gmail', icon: Icons.mail_outline, package: 'com.google.android.gm'),
    PrioritizableApp(name: 'Messages', icon: Icons.sms_outlined, package: 'com.google.android.apps.messaging'),
    PrioritizableApp(name: 'Phone', icon: Icons.call_outlined, package: 'com.android.dialer'),
    PrioritizableApp(name: 'Instagram', icon: Icons.camera_alt_outlined, package: 'com.instagram.android'),
    PrioritizableApp(name: 'Slack', icon: Icons.work_outline, package: 'com.Slack'),
    PrioritizableApp(name: 'Teams', icon: Icons.groups_outlined, package: 'com.microsoft.teams'),
    PrioritizableApp(name: 'Calendar', icon: Icons.calendar_month_outlined, package: 'com.google.android.calendar'),
    PrioritizableApp(name: 'Drive', icon: Icons.cloud_outlined, package: 'com.google.android.apps.docs'),
    PrioritizableApp(name: 'Banking', icon: Icons.account_balance_outlined, package: 'com.banking.app'),
    PrioritizableApp(name: 'Telegram', icon: Icons.send_outlined, package: 'org.telegram.messenger'),
    PrioritizableApp(name: 'Discord', icon: Icons.forum_outlined, package: 'com.discord'),
  ];

  final Map<String, Set<String>> _prioritizedAppsByMode = {};
  final Map<String, List<PriorityContact>> _contactsByMode = {};
  final Map<String, List<KeywordRule>> _keywordsByMode = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({String? preferredModeDisplay}) async {
    try {
      final modes = await _apiClient.fetchModes();
      final rules = await _apiClient.fetchRules();

      if (!mounted) return;

      _modes.clear();
      _backendModesByDisplay.clear();
      _prioritizedAppsByMode.clear();
      _contactsByMode.clear();
      _keywordsByMode.clear();

      for (final mode in modes) {
        final display = _toDisplayModeName(mode.name);
        _modes.add(display);
        _backendModesByDisplay[display] = mode;

        final contacts = <PriorityContact>[];
        for (final contactId in mode.contactIds) {
          final contactRule = rules.where((r) => r.type == 'contact' && r.contactId == contactId).cast<BackendRule?>().firstWhere(
            (r) => r != null,
            orElse: () => null,
          );
          contacts.add(
            PriorityContact(
              name: contactId,
              priority: _fromBackendPriority(contactRule?.priority ?? 'HIGH'),
              ruleId: contactRule?.id,
            ),
          );
        }

        final keywords = <KeywordRule>[];
        for (final keyword in mode.keywords) {
          final keywordRule = rules.where((r) => r.type == 'keyword' && r.keywords.contains(keyword)).cast<BackendRule?>().firstWhere(
            (r) => r != null,
            orElse: () => null,
          );
          keywords.add(
            KeywordRule(
              keyword: keyword,
              priority: _fromBackendPriority(keywordRule?.priority ?? 'HIGH'),
              ruleId: keywordRule?.id,
            ),
          );
        }

        final appNames = <String>{};
        for (final appCap in mode.appCaps) {
          final app = _availableApps.where((a) => a.package == appCap.appPackage).cast<PrioritizableApp?>().firstWhere(
            (a) => a != null,
            orElse: () => null,
          );
          if (app != null) {
            appNames.add(app.name);
          }
        }

        _contactsByMode[display] = contacts;
        _keywordsByMode[display] = keywords;
        _prioritizedAppsByMode[display] = appNames;
      }

      final fallbackSelected = _toDisplayModeName(
        modes.where((m) => m.isActive).cast<BackendMode?>().firstWhere((m) => m != null, orElse: () => null)?.name ??
            (modes.isNotEmpty ? modes.first.name : 'default'),
      );
      if (preferredModeDisplay != null && _backendModesByDisplay.containsKey(preferredModeDisplay)) {
        _selectedMode = preferredModeDisplay;
      } else {
        _selectedMode = fallbackSelected;
      }
      if (_selectedMode.isEmpty && _modes.isNotEmpty) {
        _selectedMode = _modes.first;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load modes/rules from backend.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = const Color(0xFF0F4D52);
    final subtleColor = isDark ? const Color(0xFFAAB4BA) : const Color(0xFF7A8288);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            Text(
              'Select Context',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                        onTap: () => _showAddModeDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      onTap: () => _selectMode(mode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor : Colors.transparent,
                          border: isSelected ? null : Border.all(color: subtleColor.withValues(alpha: 0.3)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Priority Contacts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                GestureDetector(
                  onTap: () => _showAddContactDialog(context),
                  child: Icon(Icons.add_circle_outline, color: accentColor, size: 20),
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
                    return Padding(
                      padding: EdgeInsets.only(bottom: idx < contacts.length - 1 ? 10 : 0),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _priorityColor(contact.priority),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              contact.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _priorityColor(contact.priority),
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
                            onPressed: () => _removeContact(contact),
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Keywords - Priority',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                GestureDetector(
                  onTap: () => _showAddKeywordDialog(context),
                  child: Icon(Icons.add_circle_outline, color: accentColor, size: 20),
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
                    onLongPress: () => _removeKeyword(keyword),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isEmergency
                            ? const Color(0xFFEF5350).withValues(alpha: 0.15)
                            : const Color(0xFFFFA500).withValues(alpha: 0.15),
                        border: Border.all(
                          color: isEmergency ? const Color(0xFFEF5350) : const Color(0xFFFFA500),
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
                              color: isEmergency ? const Color(0xFFEF5350) : const Color(0xFFFFA500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isEmergency ? const Color(0xFFEF5350) : const Color(0xFFFFA500),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              keyword.priority,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Prioritize Apps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap apps to mark as prioritized for this mode.',
              style: TextStyle(color: subtleColor, fontSize: 12, fontWeight: FontWeight.w500),
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
                      unawaited(_syncSelectedMode());
                    },
                    child: Container(
                      width: 102,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor.withValues(alpha: 0.15) : accentColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? accentColor : subtleColor.withValues(alpha: 0.2),
                          width: isSelected ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(app.icon, color: isSelected ? accentColor : subtleColor, size: 20),
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
                  );
                }),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFA500).withValues(alpha: 0.1),
                border: Border.all(color: const Color(0xFFFFA500), width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(12),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFFFA500), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rules and mode settings are synced with backend instantly.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFFA500)),
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

  Future<void> _selectMode(String modeDisplay) async {
    setState(() {
      _selectedMode = modeDisplay;
    });
    final mode = _backendModesByDisplay[modeDisplay];
    if (mode == null) return;
    try {
      await _apiClient.activateMode(mode.id);
      await _loadData(preferredModeDisplay: modeDisplay);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to activate mode on backend.')),
      );
    }
  }

  Future<void> _syncSelectedMode() async {
    final mode = _backendModesByDisplay[_selectedMode];
    if (mode == null) return;

    final selectedApps = _prioritizedAppsByMode[_selectedMode] ?? <String>{};
    final appCaps = selectedApps
        .map((name) => _availableApps.firstWhere((app) => app.name == name))
        .map((app) => BackendAppCap(appPackage: app.package, maxPriority: 'HIGH'))
        .toList(growable: false);

    final contacts = _contactsByMode[_selectedMode] ?? [];
    final keywords = _keywordsByMode[_selectedMode] ?? [];

    final updated = mode.copyWith(
      contactIds: contacts.map((e) => e.name).toList(growable: false),
      keywords: keywords.map((e) => e.keyword).toList(growable: false),
      appCaps: appCaps,
    );

    try {
      final response = await _apiClient.updateMode(updated);
      _backendModesByDisplay[_selectedMode] = response;
      await _loadData(preferredModeDisplay: _selectedMode);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sync mode changes: $error')),
      );
    }
  }

  Future<void> _removeContact(PriorityContact contact) async {
    final preferred = _selectedMode;
    setState(() {
      _contactsByMode[_selectedMode]?.remove(contact);
    });

    if (contact.ruleId != null && contact.ruleId!.isNotEmpty) {
      try {
        await _apiClient.deleteRule(contact.ruleId!);
      } catch (_) {}
    }

    await _syncSelectedMode();
    await _loadData(preferredModeDisplay: preferred);
  }

  Future<void> _removeKeyword(KeywordRule keyword) async {
    final preferred = _selectedMode;
    setState(() {
      _keywordsByMode[_selectedMode]?.remove(keyword);
    });

    if (keyword.ruleId != null && keyword.ruleId!.isNotEmpty) {
      try {
        await _apiClient.deleteRule(keyword.ruleId!);
      } catch (_) {}
    }

    await _syncSelectedMode();
    await _loadData(preferredModeDisplay: preferred);
  }

  String _toDisplayModeName(String backendName) {
    if (backendName.isEmpty) return backendName;
    final normalized = backendName.toLowerCase();
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _toBackendModeName(String displayName) => displayName.toLowerCase();

  String _fromBackendPriority(String p) {
    switch (p.toUpperCase()) {
      case 'EMERGENCY':
        return 'Emergency';
      case 'HIGH':
        return 'High';
      case 'MEDIUM':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  String _toBackendPriority(String p) {
    switch (p.toLowerCase()) {
      case 'emergency':
        return 'EMERGENCY';
      case 'high':
        return 'HIGH';
      case 'medium':
        return 'MEDIUM';
      default:
        return 'LOW';
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Emergency':
        return const Color(0xFFEF5350);
      case 'High':
        return const Color(0xFFFFA500);
      case 'Medium':
        return const Color(0xFF2E7D7D);
      default:
        return const Color(0xFF7E868C);
    }
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
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(context);
                try {
                  final created = await _apiClient.createMode(name: _toBackendModeName(text));
                  final display = _toDisplayModeName(created.name);
                  if (!mounted) return;
                  setState(() {
                    _modes.add(display);
                    _backendModesByDisplay[display] = created;
                    _contactsByMode[display] = [];
                    _keywordsByMode[display] = [];
                    _prioritizedAppsByMode[display] = <String>{};
                    _selectedMode = display;
                  });
                  await _loadData(preferredModeDisplay: display);
                } catch (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Failed to create mode: $error')),
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
                    initialValue: selectedPriority,
                    items: ['Emergency', 'High', 'Medium', 'Low']
                        .map((priority) => DropdownMenuItem(value: priority, child: Text(priority)))
                        .toList(),
                    onChanged: (value) => setState(() => selectedPriority = value ?? 'High'),
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
                  onPressed: () async {
                    final name = contactController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(context);

                    try {
                      final created = await _apiClient.createRule(
                        BackendRule(
                          id: '',
                          type: 'contact',
                          contactId: name,
                          keywords: const [],
                          appPackage: '',
                          priority: _toBackendPriority(selectedPriority),
                          timeStart: '',
                          timeEnd: '',
                          order: 0,
                          enabled: true,
                        ),
                      );

                      if (!mounted) return;
                      setState(() {
                        _contactsByMode[_selectedMode]?.add(
                          PriorityContact(name: name, priority: selectedPriority, ruleId: created.id),
                        );
                      });
                      await _syncSelectedMode();
                      await _loadData(preferredModeDisplay: _selectedMode);
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text('Failed to add contact rule: $error')),
                      );
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
                    initialValue: selectedPriority,
                    items: ['Emergency', 'High']
                        .map((priority) => DropdownMenuItem(value: priority, child: Text(priority)))
                        .toList(),
                    onChanged: (value) => setState(() => selectedPriority = value ?? 'High'),
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
                  onPressed: () async {
                    final keyword = keywordController.text.trim();
                    if (keyword.isEmpty) return;
                    Navigator.pop(context);

                    try {
                      final created = await _apiClient.createRule(
                        BackendRule(
                          id: '',
                          type: 'keyword',
                          contactId: '',
                          keywords: [keyword],
                          appPackage: '',
                          priority: _toBackendPriority(selectedPriority),
                          timeStart: '',
                          timeEnd: '',
                          order: 0,
                          enabled: true,
                        ),
                      );

                      if (!mounted) return;
                      setState(() {
                        _keywordsByMode[_selectedMode]?.add(
                          KeywordRule(keyword: keyword, priority: selectedPriority, ruleId: created.id),
                        );
                      });
                      await _syncSelectedMode();
                      await _loadData(preferredModeDisplay: _selectedMode);
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text('Failed to add keyword rule: $error')),
                      );
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
  final String? ruleId;

  PriorityContact({required this.name, required this.priority, this.ruleId});
}

class KeywordRule {
  final String keyword;
  final String priority;
  final String? ruleId;

  KeywordRule({required this.keyword, required this.priority, this.ruleId});
}

class PrioritizableApp {
  final String name;
  final IconData icon;
  final String package;

  const PrioritizableApp({required this.name, required this.icon, required this.package});
}
