import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_service.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/curriculum_repository.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/syllable_text_widget.dart';

class AnlautKeyboardScreen extends ConsumerStatefulWidget {
  const AnlautKeyboardScreen({super.key});

  @override
  ConsumerState<AnlautKeyboardScreen> createState() =>
      _AnlautKeyboardScreenState();
}

class _AnlautKeyboardScreenState extends ConsumerState<AnlautKeyboardScreen> {
  String _typedText = '';
  bool _onlyUnlockedLetters = false;
  int _riddleIdx = 0;
  bool _riddleSolved = false;
  bool _riddleBonusNewlyEarned = false;

  int _dictationIdx = 1;
  bool _dictationSolved = false;
  bool _dictationBonusNewlyEarned = false;
  bool _showDictationHint = false;

  /// Simple heuristic German syllable splitter for free writing preview.
  static List<String> splitIntoSyllables(String word) {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return const [];
    if (trimmed.length <= 3) return [trimmed];

    final vowels = RegExp(r'[aeiouäöüyAEIOUÄÖÜY]');
    final result = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < trimmed.length; i++) {
      buffer.write(trimmed[i]);
      final current = buffer.toString();
      final hasVowel = vowels.hasMatch(current);
      if (hasVowel && i + 2 < trimmed.length) {
        final nextIsConsonant = !vowels.hasMatch(trimmed[i + 1]);
        final afterNextIsVowel = vowels.hasMatch(trimmed[i + 2]);
        if (nextIsConsonant && afterNextIsVowel) {
          result.add(current);
          buffer.clear();
        }
      }
    }
    if (buffer.isNotEmpty) {
      if (result.isNotEmpty && !vowels.hasMatch(buffer.toString())) {
        result[result.length - 1] = result.last + buffer.toString();
      } else {
        result.add(buffer.toString());
      }
    }
    return result;
  }

  void _onKeyTap(
    AnlautEntry entry, {
    SyllableWord? activeRiddle,
    SyllableWord? activeDictation,
  }) {
    ref.read(audioServiceProvider).speakPhoneme(entry.phoneme);
    setState(() {
      if (_typedText.isEmpty || _typedText.endsWith(' ')) {
        _typedText += entry.letter;
      } else {
        _typedText += entry.lowercase;
      }
    });

    if (activeRiddle != null && !_riddleSolved) {
      if (_typedText.trim().toLowerCase() ==
          activeRiddle.fullWord.toLowerCase()) {
        _onRiddleSolved(activeRiddle);
      }
    }

    if (activeDictation != null && !_dictationSolved) {
      if (_typedText.trim().toLowerCase() ==
          activeDictation.fullWord.toLowerCase()) {
        _onDictationSolved(activeDictation);
      }
    }
  }

  Future<void> _onRiddleSolved(SyllableWord target) async {
    await ref.read(audioServiceProvider).playSuccessChime();
    final newly = await ref
        .read(progressProvider.notifier)
        .awardBonusStar('anlaut_riddle:${target.fullWord}');
    await ref
        .read(audioServiceProvider)
        .speakWord('Super geschrieben! ${target.fullWord}');
    if (mounted) {
      setState(() {
        _riddleSolved = true;
        _riddleBonusNewlyEarned = newly;
      });
    }
  }

  Future<void> _onDictationSolved(SyllableWord target) async {
    await ref.read(audioServiceProvider).playSuccessChime();
    final newly = await ref
        .read(progressProvider.notifier)
        .awardBonusStar('anlaut_dictation:${target.fullWord}');
    await ref
        .read(audioServiceProvider)
        .speakWord('Spitzen-Ohren! Du hast ${target.fullWord} richtig gehört!');
    if (mounted) {
      setState(() {
        _dictationSolved = true;
        _dictationBonusNewlyEarned = newly;
      });
    }
  }

  void _backspace() {
    if (_typedText.isEmpty) return;
    setState(() {
      _typedText = _typedText.substring(0, _typedText.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final curriculumAsync = ref.watch(curriculumProvider);
    final progress = ref.watch(progressProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Anlaut-Werkstatt'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.keyboard_alt_rounded),
                text: 'Freies Schreiben',
              ),
              Tab(
                icon: Icon(Icons.lightbulb_rounded),
                text: 'Wort-Rätsel ⭐',
              ),
              Tab(
                icon: Icon(Icons.headphones_rounded),
                text: 'Hör-Diktat 🎧⭐',
              ),
            ],
          ),
        ),
        body: curriculumAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fehler: $e')),
          data: (curriculum) {
            final unlockedStageSet = <int>{1, 2, 3, 4}
                .where((s) => progress.isStageUnlocked(s, curriculum.units))
                .toSet();
            final unlockedLetters = curriculum.units
                .where((u) => unlockedStageSet.contains(u.stage))
                .map((u) => u.letter.toLowerCase())
                .toSet();

            final keys = _onlyUnlockedLetters
                ? curriculum.anlautTable
                    .where(
                      (a) => unlockedLetters.contains(a.letter.toLowerCase()),
                    )
                    .toList()
                : curriculum.anlautTable;

            final riddleWords = curriculum.units
                .where((u) => unlockedStageSet.contains(u.stage))
                .expand((u) => u.words)
                .where((w) => w.emoji.isNotEmpty)
                .toList();

            final activeRiddle = riddleWords.isNotEmpty
                ? riddleWords[_riddleIdx % riddleWords.length]
                : null;
            final activeDictation = riddleWords.isNotEmpty
                ? riddleWords[_dictationIdx % riddleWords.length]
                : null;

            return TabBarView(
              children: [
                _buildWorkspace(
                  keys: keys,
                  progress: progress,
                  riddleTarget: null,
                  dictationTarget: null,
                ),
                _buildWorkspace(
                  keys: keys,
                  progress: progress,
                  riddleTarget: activeRiddle,
                  dictationTarget: null,
                  totalRiddles: riddleWords.length,
                ),
                _buildWorkspace(
                  keys: keys,
                  progress: progress,
                  riddleTarget: null,
                  dictationTarget: activeDictation,
                  totalRiddles: riddleWords.length,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWorkspace({
    required List<AnlautEntry> keys,
    required ChildProgress progress,
    required SyllableWord? riddleTarget,
    required SyllableWord? dictationTarget,
    int totalRiddles = 0,
  }) {
    final words = _typedText
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: riddleTarget != null
              ? _buildRiddleHeader(riddleTarget, totalRiddles)
              : (dictationTarget != null
                  ? _buildDictationHeader(dictationTarget, totalRiddles)
                  : MascotBanner(
                      character: MascotCharacter.fips,
                      message:
                          'Tippe auf die Anlaut-Bilder und schreibe eigene Wörter!',
                      onTap: _typedText.trim().isNotEmpty
                          ? () => ref
                              .read(audioServiceProvider)
                              .speakWord(_typedText.trim())
                          : null,
                    )),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 64),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: words.isEmpty
                          ? Text(
                              riddleTarget != null
                                  ? 'Schreibe das Wort für ${riddleTarget.emoji}…'
                                  : (dictationTarget != null
                                      ? 'Tippe auf „Wort hören“ und schreibe, was du hörst…'
                                      : 'Dein Wort erscheint hier in Silbenfarben…'),
                              style: const TextStyle(color: Color(0xFF6B7280)),
                            )
                          : Wrap(
                              spacing: 14,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: words
                                  .map(
                                    (w) => SyllableTextWidget(
                                      syllables: splitIntoSyllables(w),
                                      fontSize: 32,
                                      showArcs:
                                          progress.settings.showSyllableArcs,
                                      showVowelCrowns:
                                          progress.settings.showVowelCrowns,
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _typedText.trim().isEmpty
                              ? null
                              : () => ref
                                  .read(audioServiceProvider)
                                  .speakWord(_typedText.trim()),
                          icon: const Icon(Icons.volume_up_rounded),
                          label: const Text('Vorlesen'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _typedText += ' ');
                          },
                          icon: const Icon(Icons.space_bar_rounded),
                          label: const Text('Leerzeichen'),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Zeichen löschen',
                          onPressed: _typedText.isEmpty ? null : _backspace,
                          icon: const Icon(Icons.backspace_rounded),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          tooltip: 'Alles löschen',
                          onPressed: _typedText.isEmpty
                              ? null
                              : () => setState(() {
                                    _typedText = '';
                                    _riddleSolved = false;
                                    _dictationSolved = false;
                                  }),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Anlaut-Tastatur:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              FilterChip(
                label: Text(
                  _onlyUnlockedLetters ? 'Nur gelernte Laute' : 'Alle Laute',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                selected: _onlyUnlockedLetters,
                onSelected: (v) => setState(() => _onlyUnlockedLetters = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 92,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.92,
            ),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final entry = keys[index];
              final isVowel = entry.isVowel;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _onKeyTap(
                  entry,
                  activeRiddle: riddleTarget,
                  activeDictation: dictationTarget,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isVowel
                        ? AppColors.starGold.withValues(alpha: 0.14)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isVowel
                          ? AppColors.starGold
                          : AppColors.syllableBlue.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(entry.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.letter} ${entry.lowercase}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRiddleHeader(SyllableWord target, int totalRiddles) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.owlTeal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.owlTeal.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                ref.read(audioServiceProvider).speakWord(target.fullWord),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(target.emoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _riddleSolved
                      ? (_riddleBonusNewlyEarned
                          ? 'Super! „${target.fullWord}“ gelöst! +1 ⭐'
                          : 'Richtig! Das ist „${target.fullWord}“! ⭐')
                      : 'Wort-Rätsel: Tippe auf das Bild zum Hören & schreibe das Wort!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _riddleSolved
                        ? AppColors.successGreen
                        : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => ref
                          .read(audioServiceProvider)
                          .speakWord(target.fullWord),
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      label: const Text('Wort hören'),
                    ),
                    if (totalRiddles > 1)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _riddleIdx = (_riddleIdx + 1) % totalRiddles;
                            _typedText = '';
                            _riddleSolved = false;
                            _riddleBonusNewlyEarned = false;
                          });
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Nächstes Rätsel'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDictationHeader(SyllableWord target, int totalRiddles) {
    final syllableHint =
        '${target.syllables.length} ${target.syllables.length == 1 ? "Silbe" : "Silben"} • ${target.fullWord.length} Buchstaben';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.foxOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.foxOrange.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                ref.read(audioServiceProvider).speakWord(target.fullWord),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _dictationSolved || _showDictationHint ? target.emoji : '🎧',
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dictationSolved
                      ? (_dictationBonusNewlyEarned
                          ? 'Spitzen-Ohren! „${target.fullWord}“ richtig gehört! +1 ⭐'
                          : 'Richtig gehört! Das Wort heißt „${target.fullWord}“! ⭐')
                      : 'Hör-Diktat: Hör genau zu und schreibe das Wort ($syllableHint)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _dictationSolved
                        ? AppColors.successGreen
                        : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () => ref
                          .read(audioServiceProvider)
                          .speakWord(target.fullWord),
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      label: const Text('Wort hören'),
                    ),
                    TextButton.icon(
                      onPressed: () => ref
                          .read(audioServiceProvider)
                          .speakWord(target.syllables.join(' . ')),
                      icon: const Icon(Icons.graphic_eq_rounded, size: 18),
                      label: const Text('Silben hören'),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(
                        () => _showDictationHint = !_showDictationHint,
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Bild-Tipp'),
                    ),
                    if (totalRiddles > 1)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _dictationIdx = (_dictationIdx + 1) % totalRiddles;
                            _typedText = '';
                            _dictationSolved = false;
                            _dictationBonusNewlyEarned = false;
                            _showDictationHint = false;
                          });
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Nächstes'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
