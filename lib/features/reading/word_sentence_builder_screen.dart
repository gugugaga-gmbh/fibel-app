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
  int? _tappedSentenceWordIdx;

  @override
  void initState() {
    super.initState();
    _setupPuzzle();
  }

  void _setupPuzzle() {
    final words = widget.unit.words;
    if (words.isEmpty) {
      _shuffledPool = [];
      return;
    }
    final target = words[_wordIdx];
    _shuffledPool = List<String>.from(target.syllables)..shuffle(Random(42 + _wordIdx));
    _chosenSyllables.clear();
    _wordSolved = false;
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    final targetWord = unit.words.isNotEmpty ? unit.words[_wordIdx] : null;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Wörter & Sätze: ${unit.letter}'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.extension_rounded), text: 'Silben-Puzzle'),
              Tab(icon: Icon(Icons.menu_book_rounded), text: 'Erste Sätze'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPuzzleTab(unit, targetWord),
            _buildSentencesTab(unit),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleTab(LessonUnit unit, SyllableWord? targetWord) {
    if (targetWord == null) {
      return const Center(child: Text('Keine Wörter vorhanden.'));
    }

    return Padding(
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
                              showArcs: true,
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

  Widget _buildSentencesTab(LessonUnit unit) {
    if (unit.sentences.isEmpty) {
      return const Center(child: Text('Noch keine Sätze für diese Lektion.'));
    }
    final sentence = unit.sentences.first;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          MascotBanner(
            character: MascotCharacter.fina,
            message: 'Tippe auf ein Wort, um es dir vorlesen zu lassen!',
            onTap: () => ref.read(audioServiceProvider).speakWord(sentence.text),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: List.generate(sentence.words.length, (i) {
                  final word = sentence.words[i];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _tappedSentenceWordIdx = i);
                      ref.read(audioServiceProvider).speakWord(word.fullWord);
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
                        showArcs: true,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(audioServiceProvider).speakWord(sentence.text);
              await ref
                  .read(progressProvider.notifier)
                  .completeModule(unit.id, ModuleType.reading);
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Ganzen Satz vorlesen'),
          ),
        ],
      ),
    );
  }
}
