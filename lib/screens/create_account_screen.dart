import 'package:flutter/material.dart';

import '../state/user_profile_store.dart';
import 'main_dashboard_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _voiceRecorded = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtle = isDark ? const Color(0xFFAFB8BD) : const Color(0xFF6A7278);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your name',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Your name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D2225) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record your voice (10s)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'For privacy, AI replies and actions are tied to this recorded voice profile.',
                      style: TextStyle(color: subtle),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _voiceRecorded = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('10-second voice recorded.'),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4D52),
                      ),
                      icon: const Icon(Icons.mic),
                      label: const Text('Record 10s Voice'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _voiceRecorded
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _voiceRecorded
                              ? const Color(0xFF0F4D52)
                              : subtle,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _voiceRecorded
                              ? 'Voice is ready and will be saved to Profile.'
                              : 'Voice not recorded yet',
                          style: TextStyle(color: subtle),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _createAccount,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4D52),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createAccount() {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }
    if (!_voiceRecorded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record your 10-second voice.')),
      );
      return;
    }

    UserProfileStore.instance.createAccount(
      name: trimmedName,
      durationSeconds: 10,
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
      (route) => false,
    );
  }
}
