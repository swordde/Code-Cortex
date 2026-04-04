import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/voice_recorder_service.dart';
import '../state/user_profile_store.dart';
import 'main_dashboard_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final VoiceRecorderService _recorderService = VoiceRecorderService();
  final ApiClient _apiClient = ApiClient();
  bool _voiceRecorded = false;
  bool _isRecording = false;
  int _recordedDuration = 0;
  String? _recordedFilePath;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_recorderService.dispose());
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
                      onPressed: _toggleRecording,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4D52),
                      ),
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      label: Text(
                        _isRecording
                            ? 'Stop Recording (${_recordedDuration}s/10s)'
                            : 'Record 10s Voice',
                      ),
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
                              ? 'Voice is ready (${_recordedDuration}s) and will be saved to Profile.'
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

  Future<void> _createAccount() async {
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
      filePath: _recordedFilePath,
    );

    unawaited(
      _apiClient.updateProfile(
        BackendUserProfile(
          displayName: trimmedName,
          avatarPath: '',
          notifPermission: true,
          themeMode: 'system',
          linkedAccounts: const [],
        ),
      ),
    );

    if (_recordedFilePath != null) {
      unawaited(
        _apiClient.enrollVoiceSample(
          filePath: _recordedFilePath!,
          label: 'Primary voice',
        ),
      );
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
      (route) => false,
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
      return;
    }

    final hasPermission = await _recorderService.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required.')),
      );
      return;
    }

    try {
      final filePath = await _recorderService.startRecording(
        filePrefix: 'primary-voice',
      );

      if (!mounted) return;

      _timer?.cancel();
      setState(() {
        _isRecording = true;
        _voiceRecorded = false;
        _recordedDuration = 0;
        _recordedFilePath = filePath;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted) return;
        final next = _recordedDuration + 1;
        setState(() {
          _recordedDuration = next;
        });
        if (next >= 10) {
          await _stopRecording();
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to record: $error')),
      );
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorderService.stopRecording();
    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _voiceRecorded = (path ?? _recordedFilePath) != null;
      _recordedFilePath = path ?? _recordedFilePath;
      _recordedDuration = _recordedDuration.clamp(1, 10);
    });

    if (_voiceRecorded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Voice recording saved.')));
    }
  }
}
