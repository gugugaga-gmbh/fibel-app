import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../audio/audio_service.dart';
import '../storage/progress_repository.dart';
import '../theme/app_theme.dart';
import 'mascot_widget.dart';

/// Gentle child-protection screen-time wrapper („Schlafenszeit-Pause“ mit Fips & Fina).
/// Disabled by default (`dailyScreenTimeLimitMinutes == 0`), configurable by parents
/// in `ParentDashboardScreen` (10 / 15 / 20 / 30 minutes).
/// Uses an inline keypad math challenge so it works safely above `GoRouter` without `Overlay`.
class BedtimePauseWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const BedtimePauseWrapper({super.key, required this.child});

  @override
  ConsumerState<BedtimePauseWrapper> createState() =>
      _BedtimePauseWrapperState();
}

class _BedtimePauseWrapperState extends ConsumerState<BedtimePauseWrapper>
    with WidgetsBindingObserver {
  Timer? _usageTimer;
  bool _announcedBedtime = false;
  bool _showParentChallenge = false;
  late int _mathA;
  late int _mathB;
  String _typedAnswer = '';
  String? _mathError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rollMathChallenge();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _usageTimer?.cancel();
    super.dispose();
  }

  void _rollMathChallenge() {
    final rng = Random();
    _mathA = 12 + rng.nextInt(15);
    _mathB = 6 + rng.nextInt(12);
    _typedAnswer = '';
    _mathError = null;
  }

  void _syncTimer(ChildProgress progress) {
    final shouldTick = progress.settings.dailyScreenTimeLimitMinutes > 0 &&
        !progress.isBedtimePauseReached();
    if (shouldTick && _usageTimer == null) {
      _usageTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (!mounted) return;
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
          return;
        }
        ref.read(progressProvider.notifier).recordActiveLearningSeconds(15);
      });
    } else if (!shouldTick && _usageTimer != null) {
      _usageTimer?.cancel();
      _usageTimer = null;
    }
  }

  void _announcePauseIfNeeded() {
    if (_announcedBedtime) return;
    _announcedBedtime = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(audioServiceProvider).playBedtimeLullabyChime();
      ref.read(audioServiceProvider).speakWord(
            'Gähn! Fips und Fina machen jetzt eine kleine Augen-Pause. Du hast heute schon super gelernt!',
          );
    });
  }

  Future<void> _submitParentMath({required bool disableLimit}) async {
    final parsed = int.tryParse(_typedAnswer);
    if (parsed == _mathA + _mathB) {
      final notifier = ref.read(progressProvider.notifier);
      if (disableLimit) {
        await notifier.updateScreenTimeLimitMinutes(0);
      } else {
        await notifier.grantExtraScreenTimeMinutes(5);
      }
      if (!mounted) return;
      setState(() {
        _showParentChallenge = false;
        _announcedBedtime = false;
        _rollMathChallenge();
      });
    } else {
      setState(() {
        _typedAnswer = '';
        _mathError = 'Bitte noch einmal rechnen.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    _syncTimer(progress);

    final paused = progress.isBedtimePauseReached();
    if (!paused) {
      _announcedBedtime = false;
      return widget.child;
    }

    _announcePauseIfNeeded();
    final limitMin = progress.effectiveScreenTimeLimitMinutes();

    return Material(
      color: const Color(0xFF1E293B),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF7),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.starGold, width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🌙 🦊💤🦉 ✨',
                      style: TextStyle(fontSize: 46),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Schlafenszeit-Pause!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    MascotBanner(
                      character: MascotCharacter.fips,
                      message:
                          'Super gemacht, ${progress.childName}! Deine $limitMin Minuten Lernzeit für heute sind um. Fips und Fina ruhen jetzt ihre Augen aus!',
                      onTap: () => ref.read(audioServiceProvider).speakWord(
                            'Super gemacht, ${progress.childName}! Fips und Fina ruhen jetzt ihre Augen aus. Bis morgen!',
                          ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Deine Sterne: ${progress.totalStars} ⭐ • Serie: ${progress.streakDays} 🔥',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foxOrange,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!_showParentChallenge)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _rollMathChallenge();
                          _showParentChallenge = true;
                        }),
                        icon: const Icon(Icons.lock_outline_rounded),
                        label: const Text('Eltern: +5 Minuten freigeben'),
                      )
                    else
                      _buildInlineParentKeypad(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineParentKeypad() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            'Eltern-Aufgabe: $_mathA + $_mathB = ${_typedAnswer.isEmpty ? "?" : _typedAnswer}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_mathError != null) ...[
            const SizedBox(height: 4),
            Text(
              _mathError!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.syllableRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final digit in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'])
                SizedBox(
                  width: 52,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () {
                      if (_typedAnswer.length < 3) {
                        setState(() {
                          _typedAnswer += digit;
                          _mathError = null;
                        });
                      }
                    },
                    child: Text(
                      digit,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: 52,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => setState(() {
                    if (_typedAnswer.isNotEmpty) {
                      _typedAnswer =
                          _typedAnswer.substring(0, _typedAnswer.length - 1);
                    }
                  }),
                  child: const Icon(Icons.backspace_outlined, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () => setState(() => _showParentChallenge = false),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: () => _submitParentMath(disableLimit: false),
                child: const Text('+5 Min. erlauben'),
              ),
              OutlinedButton(
                onPressed: () => _submitParentMath(disableLimit: true),
                child: const Text('Limit ausschalten'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
