import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_service.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/curriculum_repository.dart';
import '../../core/i18n/daz_word_bridge.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/stage_certificate_dialog.dart';
import '../../core/widgets/syllable_text_widget.dart';

class StageStoryScreen extends ConsumerStatefulWidget {
  final int? initialStage;

  const StageStoryScreen({super.key, this.initialStage});

  @override
  ConsumerState<StageStoryScreen> createState() => _StageStoryScreenState();
}

class _StageStoryScreenState extends ConsumerState<StageStoryScreen> {
  late int _selectedStage;
  int _sentenceIndex = 0;
  int? _highlightedWordIdx;
  bool _showSyllableHelp = true;
  bool? _quizCorrect;
  bool _newlyRewarded = false;
  List<StoryChoice> _shuffledChoices = const [];

  @override
  void initState() {
    super.initState();
    _selectedStage = widget.initialStage ?? 1;
  }

  void _selectStage(int stage, StageStory? story) {
    setState(() {
      _selectedStage = stage;
      _sentenceIndex = 0;
      _highlightedWordIdx = null;
      _quizCorrect = null;
      _newlyRewarded = false;
      if (story != null) {
        _prepareChoices(story);
      }
    });
  }

  void _prepareChoices(StageStory story) {
    final list = <StoryChoice>[
      StoryChoice(emoji: story.answerEmoji, text: story.answerText),
      ...story.distractorOptions,
    ]..shuffle(Random(story.stage * 31));
    _shuffledChoices = list;
  }

  @override
  Widget build(BuildContext context) {
    final curriculumAsync = ref.watch(curriculumProvider);
    final progress = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesepass & Geschichten'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: const Text('Silben-Hilfe'),
              selected: _showSyllableHelp,
              onSelected: (v) => setState(() => _showSyllableHelp = v),
            ),
          ),
        ],
      ),
      body: curriculumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (curriculum) {
          final story = curriculum.storyForStage(_selectedStage);
          if (story != null && _shuffledChoices.isEmpty) {
            _prepareChoices(story);
          }

          return Column(
            children: [
              // Lesepass Stage Selector Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [1, 2, 3, 4].map((stage) {
                      final st = curriculum.storyForStage(stage);
                      final done = progress.isStageStoryCompleted(stage);
                      final selected = _selectedStage == stage;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          avatar: Text(
                            done ? '🌟' : (st?.emoji ?? '📖'),
                            style: const TextStyle(fontSize: 16),
                          ),
                          label: Text(
                            'Stufe $stage: ${st?.title ?? "Geschichte"}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          selected: selected,
                          onSelected: (_) => _selectStage(stage, st),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (story == null)
                const Expanded(
                  child: Center(
                    child: Text('Keine Geschichte für diese Stufe gefunden.'),
                  ),
                )
              else
                Expanded(
                  child: _buildStoryBody(story, progress, curriculum.units),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStoryBody(
    StageStory story,
    ChildProgress progress,
    List<LessonUnit> allUnits,
  ) {
    final sentences = story.sentences;
    final isAtQuiz = _sentenceIndex >= sentences.length;
    final storyCompleted = progress.isStageStoryCompleted(story.stage);
    final certEarned =
        progress.isStageCertificateEarned(story.stage, allUnits);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          MascotBanner(
            character: MascotCharacter.fina,
            message: isAtQuiz
                ? 'Super gelesen! Kannst du jetzt die Rätselfrage zur Geschichte beantworten?'
                : 'Lese-Abenteuer Stufe ${story.stage}: „${story.title}“. Tippe auf ein Wort zum Anhören!',
            onTap: () {
              if (isAtQuiz) {
                ref.read(audioServiceProvider).speakWord(story.question);
              } else {
                ref
                    .read(audioServiceProvider)
                    .speakWord(sentences[_sentenceIndex].text);
              }
            },
          ),
          DazWordBridgeChip(germanWord: story.title),
          const SizedBox(height: 16),
          // Progress dots (Sentences + Quiz star)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < sentences.length; i++)
                GestureDetector(
                  onTap: () => setState(() {
                    _sentenceIndex = i;
                    _highlightedWordIdx = null;
                  }),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _sentenceIndex == i
                          ? AppColors.syllableBlue
                          : (i < _sentenceIndex
                              ? AppColors.successGreen
                              : const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Seite ${i + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _sentenceIndex >= i
                            ? Colors.white
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _sentenceIndex = sentences.length),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAtQuiz
                        ? AppColors.foxOrange
                        : (storyCompleted
                            ? AppColors.starGold
                            : const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    storyCompleted ? '🌟 Lesepass' : '❓ Rätsel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: (isAtQuiz || storyCompleted)
                          ? Colors.white
                          : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!isAtQuiz)
            _buildSentencePage(sentences[_sentenceIndex], sentences.length,
                progress.settings)
          else
            _buildComprehensionQuiz(story, certEarned, progress, allUnits),
        ],
      ),
    );
  }

  Widget _buildSentencePage(
    SentenceItem sentence,
    int totalSentences,
    AppSettings settings,
  ) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(sentence.emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: List.generate(sentence.words.length, (idx) {
                    final word = sentence.words[idx];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _highlightedWordIdx = idx);
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
                          color: _highlightedWordIdx == idx
                              ? AppColors.starGold.withValues(alpha: 0.28)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _showSyllableHelp
                            ? SyllableTextWidget(
                                syllables: word.syllables,
                                fontSize: 32,
                                showArcs: settings.showSyllableArcs,
                                showVowelCrowns: settings.showVowelCrowns,
                              )
                            : Text(
                                word.fullWord,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            if (_sentenceIndex > 0)
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _sentenceIndex--;
                  _highlightedWordIdx = null;
                }),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Zurück'),
              ),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(audioServiceProvider).speakWord(sentence.text),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Satz vorlesen'),
            ),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _sentenceIndex++;
                _highlightedWordIdx = null;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.foxOrange,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _sentenceIndex + 1 < totalSentences
                    ? 'Nächste Seite'
                    : 'Zum Lese-Rätsel 🌟',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComprehensionQuiz(
    StageStory story,
    bool certEarned,
    ChildProgress progress,
    List<LessonUnit> allUnits,
  ) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(story.emoji, style: const TextStyle(fontSize: 54)),
                const SizedBox(height: 12),
                Text(
                  story.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                for (final choice in _shuffledChoices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _checkStoryAnswer(story, choice),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1F2937),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          side: const BorderSide(
                            color: AppColors.syllableBlue,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              choice.emoji,
                              style: const TextStyle(fontSize: 34),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              choice.text,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_quizCorrect != null) ...[
          const SizedBox(height: 16),
          Text(
            _quizCorrect!
                ? (_newlyRewarded
                    ? 'Juhu! Lesepass-Stempel & +2 Bonus-Sterne gewonnen! 🌟🌟'
                    : 'Genau richtig! Du hast die Geschichte super verstanden! ⭐')
                : 'Blättere noch einmal zurück und lies genau nach!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  _quizCorrect! ? AppColors.successGreen : AppColors.syllableRed,
            ),
          ),
        ],
        if (certEarned || _quizCorrect == true) ...[
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              StageCertificateDialog.show(
                context,
                stage: story.stage,
                story: story,
                progress: progress,
                allUnits: allUnits,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.starGold,
              foregroundColor: const Color(0xFF1F2937),
            ),
            icon: const Icon(Icons.emoji_events_rounded),
            label: Text('Lese-Urkunde Stufe ${story.stage} ansehen 🏆'),
          ),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() {
            _sentenceIndex = 0;
            _quizCorrect = null;
          }),
          icon: const Icon(Icons.menu_book_rounded),
          label: const Text('Geschichte noch einmal von vorn lesen'),
        ),
      ],
    );
  }

  Future<void> _checkStoryAnswer(StageStory story, StoryChoice chosen) async {
    final isRight = chosen.text == story.answerText;
    if (isRight) {
      await ref.read(audioServiceProvider).playCelebrationFanfare();
      final newly = await ref
          .read(progressProvider.notifier)
          .completeStageStory(story.stage);
      await ref
          .read(audioServiceProvider)
          .speakWord('Super! ${story.answerText} ist richtig!');
      if (mounted) {
        setState(() {
          _quizCorrect = true;
          _newlyRewarded = newly;
        });
      }
    } else {
      await ref.read(audioServiceProvider).playGentleHintChime();
      await ref.read(audioServiceProvider).speakWord(story.question);
      if (mounted) {
        setState(() => _quizCorrect = false);
      }
    }
  }
}
