import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import '../i18n/app_localizations.dart';
import '../storage/progress_repository.dart';

/// In-memory WAV audio source for 100% offline acoustic feedback chimes via just_audio.
class _SynthesizedWavSource extends StreamAudioSource {
  final Uint8List _wavBytes;

  _SynthesizedWavSource(this._wavBytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final s = start ?? 0;
    final e = end ?? _wavBytes.length;
    return StreamAudioResponse(
      sourceLength: _wavBytes.length,
      contentLength: e - s,
      offset: s,
      stream: Stream.value(_wavBytes.sublist(s, e)),
      contentType: 'audio/wav',
    );
  }
}

class AudioService {
  final Ref? _ref;
  FlutterTts? _tts;
  AudioPlayer? _player;
  bool _initialized = false;

  AudioService([this._ref]);

  AppSettings get _settings =>
      _ref?.read(progressProvider).effectiveSettings ?? const AppSettings();

  /// Maps raw curriculum phoneme strings to lautgetreue German phonetic prompts
  /// so TTS engines pronounce true phonemes rather than letter names ("Be", "Zett").
  static const Map<String, String> _phoneticMap = {
    'mmm': 'mmm',
    'aaa': 'aaa',
    'ooo': 'ooo',
    'iii': 'iii',
    'lll': 'lll',
    'sss': 'sss',
    'eee': 'eee',
    't': 'tə',
    'rrr': 'rrr',
    'nnn': 'nnn',
    'uuu': 'uuu',
    'd': 'də',
    'p': 'pə',
    'b': 'bə',
    'fff': 'fff',
    'k': 'kə',
    'g': 'gə',
    'www': 'www',
    'h': 'hə',
    'ei': 'ei',
    'au': 'au',
    'sch': 'schsch',
    'ch': 'ch',
    'eu': 'eu',
    'st': 'scht',
    'sp': 'schp',
    'z': 'ts',
    'jjj': 'jə',
    'v': 'fff',
    'äää': 'äh',
    'ööö': 'öh',
    'üüü': 'üh',
    'qu': 'kw',
    'x': 'ks',
    'y': 'ü',
    'c': 'kə',
    'pf': 'pf',
  };

  /// Converts a phoneme or phoneme+anchor phrase into a natural lautgetreue string.
  static String normalizePhonemeForSpeech(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    // Handle combined phrases like "Mmm. Wie Maus" or "B. Ball"
    final dotIdx = trimmed.indexOf('.');
    if (dotIdx > 0) {
      final firstPart = trimmed.substring(0, dotIdx).trim();
      final rest = trimmed.substring(dotIdx + 1).trim();
      final mapped =
          _phoneticMap[firstPart.toLowerCase()] ?? firstPart.toLowerCase();
      return rest.isEmpty ? mapped : '$mapped. $rest';
    }

    return _phoneticMap[trimmed.toLowerCase()] ?? trimmed;
  }

  static String _phonemeAssetSlug(String raw) {
    final head = raw.split('.').first.trim().toLowerCase();
    return head
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

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
    try {
      _player = AudioPlayer();
    } catch (e) {
      debugPrint('AudioService AudioPlayer init skipped: $e');
      _player = null;
    }
  }

  /// Attempts to play a pre-recorded offline phoneme asset from `assets/audio/phonemes/`
  /// via `just_audio`, falling back to lautgetreue TTS when no recording is bundled.
  Future<void> speakPhoneme(String phoneme) async {
    if (!_settings.soundEnabled) return;
    await _ensureInitialized();

    final slug = _phonemeAssetSlug(phoneme);
    final hasTrailingPhrase = phoneme.contains('.');

    if (!hasTrailingPhrase && slug.isNotEmpty && _player != null) {
      for (final ext in const ['mp3', 'wav']) {
        final assetPath = 'assets/audio/phonemes/$slug.$ext';
        if (await _assetExists(assetPath)) {
          try {
            await _tts?.stop();
            await _player!.setAsset(assetPath);
            await _player!.play();
            return;
          } catch (_) {
            // Fall through to phonetic TTS
          }
        }
      }
    }

    final base = _settings.wordRate;
    final spoken = normalizePhonemeForSpeech(phoneme);
    await speakWord(spoken, rate: (base - 0.07).clamp(0.25, 0.60));
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
      await _tts?.setLanguage('de-DE');
      await _tts?.setSpeechRate(rate ?? _settings.wordRate);
      await _tts?.speak(text);
    } catch (e) {
      debugPrint('AudioService speak skipped: $e');
    }
  }

  /// Speaks a translated word in the child's heritage/bridge language (DaZ-Wort-Brücke).
  Future<void> speakBridgeWord(
    String translatedText,
    BridgeLanguage bridgeLanguage,
  ) async {
    if (!_settings.soundEnabled || !bridgeLanguage.isEnabled) return;
    await _ensureInitialized();
    try {
      await _tts?.stop();
      await _tts?.setLanguage(bridgeLanguage.ttsLocale);
      await _tts?.setSpeechRate(_settings.wordRate);
      await _tts?.speak(translatedText);
    } catch (e) {
      debugPrint('AudioService speakBridgeWord skipped: $e');
    }
  }

  /// Plays a cheerful offline major-triad chime via just_audio when a child succeeds.
  Future<void> playSuccessChime() async {
    if (!_settings.soundEnabled) return;
    await _ensureInitialized();
    if (_player == null) return;
    try {
      final wav = buildChimeWav(
        frequencies: const [523.25, 659.25, 783.99], // C5 - E5 - G5
        noteDurationMs: 75,
      );
      await _player!.setAudioSource(_SynthesizedWavSource(wav));
      await _player!.play();
    } catch (_) {}
  }

  /// Plays a gentle two-tone hint sound when a child needs another try.
  Future<void> playGentleHintChime() async {
    if (!_settings.soundEnabled) return;
    await _ensureInitialized();
    if (_player == null) return;
    try {
      final wav = buildChimeWav(
        frequencies: const [392.00, 349.23], // G4 - F4 (soft & non-frustrating)
        noteDurationMs: 80,
      );
      await _player!.setAudioSource(_SynthesizedWavSource(wav));
      await _player!.play();
    } catch (_) {}
  }

  /// Plays a festive 4-note major fanfare (C5 - E5 - G5 - C6) for stage certificates.
  Future<void> playCelebrationFanfare() async {
    if (!_settings.soundEnabled) return;
    await _ensureInitialized();
    if (_player == null) return;
    try {
      final wav = buildChimeWav(
        frequencies: const [523.25, 659.25, 783.99, 1046.50],
        noteDurationMs: 95,
      );
      await _player!.setAudioSource(_SynthesizedWavSource(wav));
      await _player!.play();
    } catch (_) {}
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Generates a valid 16-bit mono PCM WAV buffer for offline chimes.
  @visibleForTesting
  static Uint8List buildChimeWav({
    required List<double> frequencies,
    int sampleRate = 22050,
    int noteDurationMs = 80,
  }) {
    final samplesPerNote = (sampleRate * noteDurationMs) ~/ 1000;
    final totalSamples = samplesPerNote * frequencies.length;
    final dataSize = totalSamples * 2;
    final buffer = ByteData(44 + dataSize);

    void writeAscii(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        buffer.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    // RIFF header
    writeAscii(0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little); // PCM chunk size
    buffer.setUint16(20, 1, Endian.little); // PCM format
    buffer.setUint16(22, 1, Endian.little); // 1 channel (mono)
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    buffer.setUint16(32, 2, Endian.little); // block align
    buffer.setUint16(34, 16, Endian.little); // bits per sample
    writeAscii(36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    int sampleIdx = 0;
    for (final freq in frequencies) {
      for (int i = 0; i < samplesPerNote; i++) {
        final t = i / sampleRate;
        final envelope = math.sin((i / samplesPerNote) * math.pi);
        final sample =
            (math.sin(2 * math.pi * freq * t) * envelope * 9000).round();
        buffer.setInt16(
          44 + sampleIdx * 2,
          sample.clamp(-32768, 32767),
          Endian.little,
        );
        sampleIdx++;
      }
    }

    return buffer.buffer.asUint8List();
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
      await _player?.stop();
    } catch (_) {}
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService(ref);
});
