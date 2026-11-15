import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  FlutterTts? _tts;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _tts = FlutterTts();
      await _tts?.setLanguage('de-DE');
      await _tts?.setSpeechRate(0.42);
      await _tts?.setPitch(1.05);
    } catch (e) {
      debugPrint('AudioService TTS init skipped: $e');
      _tts = null;
    }
  }

  Future<void> speakPhoneme(String phoneme) async {
    await speakWord(phoneme, rate: 0.35);
  }

  Future<void> speakSyllable(String syllable) async {
    await speakWord(syllable, rate: 0.38);
  }

  Future<void> speakWord(String text, {double rate = 0.42}) async {
    await _ensureInitialized();
    try {
      await _tts?.stop();
      await _tts?.setSpeechRate(rate);
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
  return AudioService();
});
