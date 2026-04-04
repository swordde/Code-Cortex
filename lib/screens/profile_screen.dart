import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _cortexModeEnabled = true;
  bool _isPlayingVoice = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1D2225) : Colors.white;
    final subtle = isDark ? const Color(0xFFAAB4BA) : const Color(0xFF7A8288);
    final accent = const Color(0xFF1F6F68);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: accent,
                child: const Icon(Icons.person, size: 42, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Arjun Sharma',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recorded Voice (10s)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Used privately to improve AI response quality for your profile only.',
                      style: TextStyle(color: subtle),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            setState(() {
                              _isPlayingVoice = !_isPlayingVoice;
                            });
                          },
                          icon: Icon(
                            _isPlayingVoice ? Icons.pause : Icons.play_arrow,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              minHeight: 9,
                              value: _isPlayingVoice ? 0.55 : 0.0,
                              backgroundColor: isDark
                                  ? const Color(0xFF2E3338)
                                  : const Color(0xFFE8ECEE),
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '00:10',
                          style: TextStyle(
                            color: subtle,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voice recording added/updated.'),
                    ),
                  );
                },
                icon: const Icon(Icons.mic),
                label: const Text('Add Voice'),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cortex Mode',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _cortexModeEnabled
                                ? 'AI service is ON for this account'
                                : 'Turn on to receive AI services',
                            style: TextStyle(color: subtle),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _cortexModeEnabled,
                      onChanged: (value) {
                        setState(() {
                          _cortexModeEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
