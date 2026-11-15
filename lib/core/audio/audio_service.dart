import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../storage/progress_repository.dart';

class AudioService {
  final Ref? _ref;
  FlutterTts? _tts;
  bool _initialized = false;

  AudioService([this._ref]);

  AppSettings get _settings =>
      _ref?.read(progressProvider).settings ?? const AppSettings();

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _tts = FlutterTts();
      await _tts?.setLanguage('de-DE');
      await _tts?.setSpeechRate(_settings.wordRate);
      await _tts?.setPitch(1.05);
    } catch (e) {
      debugPrint('AudioService TTS init skipped: $e');
      _tts = null;
    }
  }

  Future<void> speakPhoneme(String phoneme) async {
    final base = _settings.wordRate;
    await speakWord(phoneme, rate: (base - 0.07).clamp(0.25, 0.60));
  }

  Future<void> speakSyllable(String syllable) async {
    final base = _settings.wordRate;
    await speakWord(syllable, rate: (base - 0.04).clamp(0.28, 0.60));
  }

  Future<void> speakWord(String text, {double? rate}) async {
    if (!_settings.soundEnabled) return;
    await _ensureInitialized();
    try {
      await _tts?.stop();
      await _tts?.setSpeechRate(rate ?? _settings.wordRate);
      await _tts?.speak(text);
    } catch (e) {
      debugPrint('AudioService speak skipped: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService(ref);
});
