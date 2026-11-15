import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_service.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/syllable_text_widget.dart';

class WordSentenceBuilderScreen extends ConsumerStatefulWidget {
  final LessonUnit unit;

  const WordSentenceBuilderScreen({super.key, required this.unit});

  @override
  ConsumerState<WordSentenceBuilderScreen> createState() =>
      _WordSentenceBuilderScreenState();
}

class _WordSentenceBuilderScreenState
    extends ConsumerState<WordSentenceBuilderScreen> {
  int _wordIdx = 0;
  late List<String> _shuffledPool;
  final List<String> _chosenSyllables = [];
  bool _wordSolved = false;

  int _sentenceIdx = 0;
  int? _tappedSentenceWordIdx;

  // Satz-Rätsel (Satzbau + Sinn-Check) state
  late List<String> _shuffledSentenceWords;
  final List<String> _chosenSentenceWords = [];
  bool _sentenceOrderSolved = false;
  late List<String> _emojiChoices;
  bool? _comprehensionCorrect;
  bool _bonusAwarded = false;

  @override
  void initState() {
    super.initState();
    _setupPuzzle();
    _setupSentenceQuiz();
  }

  void _setupPuzzle() {
    final words = widget.unit.words;
    if (words.isEmpty) {
      _shuffledPool = [];
      return;
    }
    final target = words[_wordIdx];
    _shuffledPool =
        List<String>.from(target.syllables)..shuffle(Random(42 + _wordIdx));
    _chosenSyllables.clear();
    _wordSolved = false;
  }

  void _setupSentenceQuiz() {
    final sentences = widget.unit.sentences;
    if (sentences.isEmpty) {
      _shuffledSentenceWords = [];
      _emojiChoices = [];
      return;
    }
    final target = sentences[_sentenceIdx % sentences.length];
    _shuffledSentenceWords =
        target.words.map((w) => w.fullWord).toList()
          ..shuffle(Random(99 + _sentenceIdx));
    _chosenSentenceWords.clear();
    _sentenceOrderSolved = false;
    _comprehensionCorrect = null;
    _emojiChoices = [target.emoji, ...target.distractorEmojis]
      ..shuffle(Random(77 + _sentenceIdx));
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    final progress = ref.watch(progressProvider);
    final targetWord = unit.words.isNotEmpty ? unit.words[_wordIdx] : null;
    final bonusDone = progress.isBonusCompleted('sentence_quiz:${unit.id}');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Wörter & Sätze: ${unit.letter}'),
          bottom: TabBar(
            tabs: [
              const Tab(
                icon: Icon(Icons.extension_rounded),
                text: 'Silben-Puzzle',
              ),
              const Tab(
                icon: Icon(Icons.menu_book_rounded),
                text: 'Erste Sätze',
              ),
              Tab(
                icon: Icon(
                  bonusDone ? Icons.stars_rounded : Icons.quiz_rounded,
                  color: bonusDone ? AppColors.starGold : null,
                ),
                text: 'Satz-Rätsel ⭐',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPuzzleTab(unit, targetWord, progress.settings),
            _buildSentencesTab(unit, progress.settings),
            _buildSentenceQuizTab(unit, bonusDone),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleTab(
    LessonUnit unit,
    SyllableWord? targetWord,
    AppSettings settings,
  ) {
    if (targetWord == null) {
      return const Center(child: Text('Keine Wörter vorhanden.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          MascotBanner(
            character: MascotCharacter.fips,
            message: 'Baue das Wort aus den Silben zusammen!',
            onTap: () => ref
                .read(audioServiceProvider)
                .speakWord(targetWord.fullWord),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                children: [
                  Text(targetWord.emoji, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(minHeight: 60),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _chosenSyllables.isEmpty
                          ? const Text(
                              'Tippe auf die Silben unten...',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            )
                          : SyllableTextWidget(
                              syllables: _chosenSyllables,
                              fontSize: 34,
                              showArcs: settings.showSyllableArcs,
                              showVowelCrowns: settings.showVowelCrowns,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _shuffledPool.map((syllable) {
              return ElevatedButton(
                onPressed: _wordSolved
                    ? null
                    : () => _onSelectSyllable(unit, targetWord, syllable),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.syllableBlue,
                  side: const BorderSide(
                    color: AppColors.syllableBlue,
                    width: 2,
                  ),
                ),
                child: Text(
                  syllable,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (_wordSolved) ...[
            const Text(
              'Richtig gebaut! ⭐',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.successGreen,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _wordIdx = (_wordIdx + 1) % unit.words.length;
                  _setupPuzzle();
                });
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Nächstes Wort'),
            ),
          ] else if (_chosenSyllables.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _chosenSyllables.clear()),
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Zurücksetzen'),
            ),
        ],
      ),
    );
  }

  Future<void> _onSelectSyllable(
    LessonUnit unit,
    SyllableWord target,
    String syllable,
  ) async {
    await ref.read(audioServiceProvider).speakSyllable(syllable);
    setState(() {
      _chosenSyllables.add(syllable);
    });

    if (_chosenSyllables.length == target.syllables.length) {
      final matches = _chosenSyllables.join() == target.fullWord;
      if (matches) {
        setState(() => _wordSolved = true);
        await ref
            .read(audioServiceProvider)
            .speakWord('Super! ${target.fullWord}');
        await ref
            .read(progressProvider.notifier)
            .completeModule(unit.id, ModuleType.reading);
      } else {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() => _chosenSyllables.clear());
        });
      }
    }
  }

  Widget _buildSentencesTab(LessonUnit unit, AppSettings settings) {
    if (unit.sentences.isEmpty) {
      return const Center(child: Text('Noch keine Sätze für diese Lektion.'));
    }
    final sentence = unit.sentences[_sentenceIdx % unit.sentences.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          MascotBanner(
            character: MascotCharacter.fina,
            message: 'Tippe auf ein Wort, um es dir vorlesen zu lassen!',
            onTap: () =>
                ref.read(audioServiceProvider).speakWord(sentence.text),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(sentence.emoji, style: const TextStyle(fontSize: 54)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: List.generate(sentence.words.length, (i) {
                      final word = sentence.words[i];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _tappedSentenceWordIdx = i);
                          ref
                              .read(audioServiceProvider)
                              .speakWord(word.fullWord);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _tappedSentenceWordIdx == i
                                ? AppColors.starGold.withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: SyllableTextWidget(
                            syllables: word.syllables,
                            fontSize: 32,
                            showArcs: settings.showSyllableArcs,
                            showVowelCrowns: settings.showVowelCrowns,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await ref
                      .read(audioServiceProvider)
                      .speakWord(sentence.text);
                  await ref
                      .read(progressProvider.notifier)
                      .completeModule(unit.id, ModuleType.reading);
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Ganzen Satz vorlesen'),
              ),
              if (unit.sentences.length > 1)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _sentenceIdx = (_sentenceIdx + 1) % unit.sentences.length;
                      _tappedSentenceWordIdx = null;
                      _setupSentenceQuiz();
                    });
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Nächster Satz'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceQuizTab(LessonUnit unit, bool bonusDone) {
    if (unit.sentences.isEmpty) {
      return const Center(child: Text('Noch kein Satz-Rätsel vorhanden.'));
    }
    final sentence = unit.sentences[_sentenceIdx % unit.sentences.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          MascotBanner(
            character: MascotCharacter.fips,
            message: !_sentenceOrderSolved
                ? 'Schritt 1: Tippe die Wörter in der richtigen Satz-Reihenfolge an!'
                : 'Schritt 2: Welches Bild passt zum gelesenen Satz?',
            onTap: () =>
                ref.read(audioServiceProvider).speakWord(sentence.text),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 68),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _chosenSentenceWords.isEmpty
                          ? const Text(
                              'Tippe unten auf das erste Wort des Satzes…',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            )
                          : Text(
                              _chosenSentenceWords.join(' '),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.syllableBlue,
                              ),
                            ),
                    ),
                  ),
                  if (!_sentenceOrderSolved) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _shuffledSentenceWords.map((wordText) {
                        return ElevatedButton(
                          onPressed: () =>
                              _onSelectSentenceWord(sentence, wordText),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1F2937),
                            side: const BorderSide(
                              color: AppColors.syllableBlue,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            wordText,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_chosenSentenceWords.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _chosenSentenceWords.clear()),
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Satz zurücksetzen'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          if (_sentenceOrderSolved) ...[
            const SizedBox(height: 20),
            const Text(
              'Welches Bild passt zum Satz?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              children: _emojiChoices.map((emoji) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ElevatedButton(
                      onPressed: () =>
                          _onSelectComprehensionEmoji(unit, sentence, emoji),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        side: const BorderSide(
                          color: AppColors.foxOrange,
                          width: 2.5,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 44)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (_comprehensionCorrect != null) ...[
            const SizedBox(height: 20),
            Text(
              _comprehensionCorrect!
                  ? (_bonusAwarded
                      ? 'Satz-Rätsel gelöst! +1 Bonus-Stern! 🌟'
                      : 'Richtig verstanden! Super gelesen! ⭐')
                  : 'Lies den Satz noch einmal genau!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _comprehensionCorrect!
                    ? AppColors.successGreen
                    : AppColors.syllableRed,
              ),
            ),
            if (_comprehensionCorrect! && unit.sentences.length > 1) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _sentenceIdx = (_sentenceIdx + 1) % unit.sentences.length;
                    _setupSentenceQuiz();
                  });
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Nächstes Satz-Rätsel'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _onSelectSentenceWord(
    SentenceItem sentence,
    String wordText,
  ) async {
    await ref.read(audioServiceProvider).speakWord(wordText);
    setState(() {
      _chosenSentenceWords.add(wordText);
    });

    if (_chosenSentenceWords.length == sentence.words.length) {
      final built = _chosenSentenceWords.join(' ');
      if (built == sentence.text) {
        setState(() => _sentenceOrderSolved = true);
        await ref.read(audioServiceProvider).speakWord(sentence.text);
      } else {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() => _chosenSentenceWords.clear());
        });
      }
    }
  }

  Future<void> _onSelectComprehensionEmoji(
    LessonUnit unit,
    SentenceItem sentence,
    String chosenEmoji,
  ) async {
    final isRight = chosenEmoji == sentence.emoji;
    if (isRight) {
      final newlyAwarded = await ref
          .read(progressProvider.notifier)
          .awardBonusStar('sentence_quiz:${unit.id}');
      await ref
          .read(progressProvider.notifier)
          .completeModule(unit.id, ModuleType.reading);
      await ref
          .read(audioServiceProvider)
          .speakWord('Klasse! Du hast den Satz verstanden!');
      if (mounted) {
        setState(() {
          _comprehensionCorrect = true;
          _bonusAwarded = newlyAwarded;
        });
      }
    } else {
      setState(() => _comprehensionCorrect = false);
      await ref.read(audioServiceProvider).speakWord(sentence.text);
    }
  }
}
