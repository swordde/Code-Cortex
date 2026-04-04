import 'dart:async';

// import 'package:audioplayers/audioplayers.dart'; // Temporarily disabled
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/voice_recorder_service.dart';
import '../state/user_profile_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _cortexModeEnabled = true;
  bool _isPlayingVoice = false;
  final UserProfileStore _store = UserProfileStore.instance;
  final VoiceRecorderService _recorderService = VoiceRecorderService();
  // final AudioPlayer _audioPlayer = AudioPlayer(); // Temporarily disabled
  final ApiClient _apiClient = ApiClient();
  Timer? _recordTimer;
  BackendUserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBackendState();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    // unawaited(_audioPlayer.dispose()); // Temporarily disabled
    unawaited(_recorderService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1D2225) : Colors.white;
    final subtle = isDark ? const Color(0xFFAAB4BA) : const Color(0xFF7A8288);
    final accent = const Color(0xFF0F4D52);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _store,
          builder: (context, _) {
            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final displayName = (_profile?.displayName.isNotEmpty ?? false)
                ? _profile!.displayName
                : _store.userName;
            final primaryVoice = _store.primaryVoice;
            final extraVoices = _store.voices
                .where((voice) => !voice.isPrimary)
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: accent,
                    child: const Icon(
                      Icons.person,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
                          'Recorded Voice (${_formatDuration(primaryVoice?.durationSeconds ?? 10)})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          primaryVoice == null
                              ? 'No primary voice found. Please create account voice.'
                              : 'Used privately to improve AI response quality for your profile only.',
                          style: TextStyle(color: subtle),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: primaryVoice == null
                                  ? null
                                  : () => _togglePlayback(primaryVoice),
                              icon: Icon(
                                _isPlayingVoice
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  minHeight: 9,
                                  value: _isPlayingVoice ? null : 0.0,
                                  backgroundColor: isDark
                                      ? const Color(0xFF2E3338)
                                      : const Color(0xFFE8ECEE),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    accent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDuration(
                                primaryVoice?.durationSeconds ?? 10,
                              ),
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
                    onPressed: _addVoice,
                    icon: const Icon(Icons.mic),
                    label: const Text('Add Voice'),
                  ),
                  if (extraVoices.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Additional Voices',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          for (final voice in extraVoices)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.record_voice_over, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(voice.label)),
                                  Text(
                                    _formatDuration(voice.durationSeconds),
                                    style: TextStyle(color: subtle),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
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
                          onChanged: _setCortexEnabled,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    return '00:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _addVoice() async {
    final controller = TextEditingController();
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (context) {
        bool isRecording = false;
        int elapsed = 0;
        Timer? timer;
        String? recordedPath;

        Future<void> stopRec(StateSetter setModalState) async {
          timer?.cancel();
          final path = await _recorderService.stopRecording();
          setModalState(() {
            isRecording = false;
            recordedPath = path ?? recordedPath;
            elapsed = elapsed.clamp(1, 10);
          });
        }

        return AlertDialog(
          title: const Text('Add Voice'),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Voice label (e.g., Mom, Teammate)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      if (isRecording) {
                        await stopRec(setModalState);
                        return;
                      }
                      final hasPermission =
                          await _recorderService.hasPermission();
                      if (!hasPermission) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Microphone permission is required.'),
                          ),
                        );
                        return;
                      }
                      recordedPath = await _recorderService.startRecording(
                        filePrefix: 'extra-voice',
                      );
                      setModalState(() {
                        isRecording = true;
                        elapsed = 0;
                      });
                      timer?.cancel();
                      timer = Timer.periodic(const Duration(seconds: 1), (
                        t,
                      ) async {
                        final next = elapsed + 1;
                        setModalState(() => elapsed = next);
                        if (next >= 10) {
                          await stopRec(setModalState);
                        }
                      });
                    },
                    icon: Icon(isRecording ? Icons.stop : Icons.mic),
                    label: Text(
                      isRecording
                          ? 'Stop Recording (${elapsed}s/10s)'
                          : 'Record 10s Voice',
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                timer?.cancel();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                timer?.cancel();
                Navigator.pop(context, (controller.text.trim(), recordedPath));
              },
              child: const Text('Record + Save 10s'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (result == null) return;
    final label = result.$1;
    final filePath = result.$2;

    if (filePath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record voice before saving.')),
      );
      return;
    }
    final recordedPath = filePath;

    final safeLabel = label.isEmpty
        ? 'Extra voice ${_store.voices.length}'
        : label;
    _store.addExtraVoice(
      label: safeLabel,
      durationSeconds: 10,
      filePath: recordedPath,
    );

    unawaited(
      _apiClient.enrollVoiceSample(filePath: recordedPath, label: safeLabel),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$safeLabel voice added.')));
  }

  Future<void> _togglePlayback(VoiceSample? voice) async {
    if (voice == null || voice.filePath == null) return;
    // Audio playback temporarily disabled until audioplayers system packages are installed
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice playback coming soon')),
    );
  }

  Future<void> _loadBackendState() async {
    try {
      final profile = await _apiClient.fetchProfile();
      final cortex = await _apiClient.fetchCortexConfig();
      if (!mounted) return;
      _store.setUserName(profile.displayName.isEmpty ? _store.userName : profile.displayName);
      setState(() {
        _profile = profile;
        _cortexModeEnabled = cortex.enabled;
      });
    } catch (_) {
      // fallback to local store when backend call fails
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _setCortexEnabled(bool value) async {
    setState(() {
      _cortexModeEnabled = value;
    });
    try {
      await _apiClient.updateCortexConfig(
        BackendCortexConfig(enabled: value, autoReply: value, scope: 'global'),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update cortex mode.')),
      );
    }
  }
}
