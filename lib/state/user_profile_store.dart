import 'package:flutter/foundation.dart';

class VoiceSample {
  const VoiceSample({
    required this.label,
    required this.durationSeconds,
    required this.isPrimary,
  });

  final String label;
  final int durationSeconds;
  final bool isPrimary;
}

class UserProfileStore extends ChangeNotifier {
  UserProfileStore._();

  static final UserProfileStore instance = UserProfileStore._();

  String _userName = 'User';
  final List<VoiceSample> _voices = [];

  String get userName => _userName;
  List<VoiceSample> get voices => List.unmodifiable(_voices);
  bool get hasAccount => _voices.any((voice) => voice.isPrimary);

  VoiceSample? get primaryVoice {
    for (final voice in _voices) {
      if (voice.isPrimary) return voice;
    }
    return null;
  }

  void createAccount({required String name, required int durationSeconds}) {
    _userName = name;
    _voices
      ..clear()
      ..add(
        VoiceSample(
          label: 'Primary voice',
          durationSeconds: durationSeconds,
          isPrimary: true,
        ),
      );
    notifyListeners();
  }

  void addExtraVoice({required String label, required int durationSeconds}) {
    _voices.add(
      VoiceSample(
        label: label,
        durationSeconds: durationSeconds,
        isPrimary: false,
      ),
    );
    notifyListeners();
  }
}
