import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../state/user_profile_store.dart';
import 'landing_screen.dart';

class StartupNameGateScreen extends StatefulWidget {
  const StartupNameGateScreen({super.key});

  @override
  State<StartupNameGateScreen> createState() => _StartupNameGateScreenState();
}

class _StartupNameGateScreenState extends State<StartupNameGateScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _nameController = TextEditingController();

  BackendUserProfile? _profile;
  bool _checking = true;
  bool _needsName = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final profile = await _apiClient.fetchProfile();
      _profile = profile;
      final displayName = profile.displayName.trim();
      if (displayName.isNotEmpty) {
        UserProfileStore.instance.setUserName(displayName);
        if (!mounted) return;
        setState(() {
          _checking = false;
          _needsName = false;
        });
        return;
      }
    } catch (_) {
      // If profile is unavailable, still allow local startup with a prompted name.
    }

    if (!mounted) return;
    setState(() {
      _checking = false;
      _needsName = true;
    });
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }

    setState(() {
      _saving = true;
    });

    UserProfileStore.instance.setUserName(name);

    try {
      final existing = _profile ?? await _apiClient.fetchProfile();
      await _apiClient.updateProfile(existing.copyWith(displayName: name));
    } catch (_) {
      // Keep local progress even when backend is temporarily unreachable.
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      _needsName = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_needsName) {
      return const LandingScreen();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtle = isDark ? const Color(0xFFAFB8BD) : const Color(0xFF6A7278);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 72,
                    color: Color(0xFF0F4D52),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'What should Cortex call you?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is asked once when your profile has no name.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtle),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saving ? null : _saveName(),
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _saving ? null : _saveName,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4D52),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_saving ? 'Saving...' : 'Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}