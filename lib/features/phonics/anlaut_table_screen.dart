import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_service.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/curriculum_repository.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/syllable_text_widget.dart';

class AnlautTableScreen extends ConsumerStatefulWidget {
  final LessonUnit? unit;

  const AnlautTableScreen({super.key, this.unit});

  @override
  ConsumerState<AnlautTableScreen> createState() => _AnlautTableScreenState();
}

class _AnlautTableScreenState extends ConsumerState<AnlautTableScreen> {
  int _quizIndex = 0;
  bool? _lastAnswerCorrect;
  bool _quizFinished = false;
  AnlautCategory? _selectedCategory;

  // Reim-Detektiv & Minimalpaare state
  int _rhymeIndex = 0;
  bool? _rhymeAnswerCorrect;
  bool _rhymeBonusNewlyEarned = false;

  @override
  Widget build(BuildContext context) {
    final curriculumAsync = ref.watch(curriculumProvider);
    final unit = widget.unit;

    return DefaultTabController(
      length: unit != null ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            unit != null
                ? 'Laute hören: ${unit.letter} ${unit.lowercase}'
                : 'Anlauttabelle',
          ),
          bottom: TabBar(
            tabs: [
              if (unit != null)
                const Tab(icon: Icon(Icons.train_rounded), text: 'Laut-Zug'),
              const Tab(
                icon: Icon(Icons.grid_view_rounded),
                text: 'Anlauttabelle',
              ),
              const Tab(
                icon: Icon(Icons.music_note_rounded),
                text: 'Reim-Detektiv ⭐',
              ),
            ],
          ),
        ),
        body: curriculumAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fehler: $e')),
          data: (curriculum) {
            final stageRhymes = unit != null
                ? curriculum.rhymesForStage(unit.stage)
                : curriculum.rhymePairs;
            final effectiveRhymes =
                stageRhymes.isNotEmpty ? stageRhymes : curriculum.rhymePairs;

            if (unit == null) {
              return TabBarView(
                children: [
                  _buildAnlautGrid(curriculum.anlautTable),
                  _buildRhymeDetectiveTab(effectiveRhymes),
                ],
              );
            }
            return TabBarView(
              children: [
                _buildSoundTrainQuiz(unit),
                _buildAnlautGrid(curriculum.anlautTable),
                _buildRhymeDetectiveTab(effectiveRhymes),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSoundTrainQuiz(LessonUnit unit) {
    if (unit.soundQuiz.isEmpty) {
      return const Center(child: Text('Keine Laut-Übung vorhanden.'));
    }

    if (_quizFinished) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌟', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text(
                'Super gehört! Du hast alle ${unit.letter}-Laute gefunden!',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Zurück zur Übersicht'),
              ),
            ],
          ),
        ),
      );
    }

    final item = unit.soundQuiz[_quizIndex];
    final total = unit.soundQuiz.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          MascotBanner(
            character: MascotCharacter.fina,
            message: 'Wo hörst du das „${unit.phoneme}“ in „${item.word}“?',
            onTap: () => ref.read(audioServiceProvider).speakWord(item.word),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (idx) {
              final done = idx < _quizIndex;
              final active = idx == _quizIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.successGreen
                      : (active
                          ? AppColors.syllableBlue
                          : const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  done ? '✓' : '${idx + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: (done || active)
                        ? Colors.white
                        : const Color(0xFF4B5563),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => ref.read(audioServiceProvider).speakWord(item.word),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.syllableBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.word,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tippe auf den richtigen Waggon:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _TrainWagonButton(
                label: 'Anfang',
                icon: '🚂',
                onTap: () => _checkAnswer(unit, item, SoundPosition.start),
              ),
              const SizedBox(width: 10),
              _TrainWagonButton(
                label: 'Mitte',
                icon: '🚃',
                onTap: () => _checkAnswer(unit, item, SoundPosition.middle),
              ),
              const SizedBox(width: 10),
              _TrainWagonButton(
                label: 'Ende',
                icon: '🚋',
                onTap: () => _checkAnswer(unit, item, SoundPosition.end),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_lastAnswerCorrect != null)
            Text(
              _lastAnswerCorrect!
                  ? 'Richtig! Toll gemacht! ⭐'
                  : 'Hör noch einmal genau hin!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _lastAnswerCorrect!
                    ? AppColors.successGreen
                    : AppColors.syllableRed,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _checkAnswer(
    LessonUnit unit,
    SoundQuizItem item,
    SoundPosition chosen,
  ) async {
    final correct = chosen == item.position;
    setState(() => _lastAnswerCorrect = correct);

    if (correct) {
      await ref.read(audioServiceProvider).playSuccessChime();
      await ref.read(audioServiceProvider).speakWord('Richtig! ${item.word}');
      if (_quizIndex + 1 < unit.soundQuiz.length) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() {
            _quizIndex++;
            _lastAnswerCorrect = null;
          });
        });
      } else {
        await ref
            .read(progressProvider.notifier)
            .completeModule(unit.id, ModuleType.phonics);
        if (mounted) {
          setState(() => _quizFinished = true);
        }
      }
    } else {
      await ref.read(audioServiceProvider).playGentleHintChime();
      await ref.read(progressProvider.notifier).recordMistake(unit.id);
      await ref.read(audioServiceProvider).speakWord(item.word);
    }
  }

  Widget _buildAnlautGrid(List<AnlautEntry> entries) {
    final showCrowns = ref.watch(progressProvider).settings.showVowelCrowns;
    final filtered = _selectedCategory == null
        ? entries
        : entries.where((e) => e.category == _selectedCategory).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: MascotBanner(
            character: MascotCharacter.fips,
            message: 'Tippe auf ein Bild, um den Anlaut zu hören!',
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _FilterChipButton(
                label: 'Alle (${entries.length})',
                selected: _selectedCategory == null,
                onTap: () => setState(() => _selectedCategory = null),
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                label: 'Silbenkönige 👑',
                selected: _selectedCategory == AnlautCategory.vowel,
                onTap: () =>
                    setState(() => _selectedCategory = AnlautCategory.vowel),
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                label: 'Mitlaute',
                selected: _selectedCategory == AnlautCategory.consonant,
                onTap: () => setState(
                    () => _selectedCategory = AnlautCategory.consonant),
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                label: 'Sch / Ei / Au …',
                selected: _selectedCategory == AnlautCategory.digraph,
                onTap: () =>
                    setState(() => _selectedCategory = AnlautCategory.digraph),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final entry = filtered[index];
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  ref
                      .read(audioServiceProvider)
                      .speakPhoneme('${entry.phoneme}. ${entry.word}');
                },
                child: Card(
                  child: Stack(
                    children: [
                      if (showCrowns && entry.isVowel)
                        const Positioned(
                          top: 6,
                          right: 8,
                          child: Text('👑', style: TextStyle(fontSize: 14)),
                        ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    entry.letter,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.syllableBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    entry.lowercase,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.syllableRed,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entry.emoji,
                                style: const TextStyle(fontSize: 34),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.word,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildRhymeDetectiveTab(List<RhymePairItem> rhymes) {
    if (rhymes.isEmpty) {
      return const Center(child: Text('Keine Reim-Aufgaben vorhanden.'));
    }

    final settings = ref.watch(progressProvider).settings;
    final item = rhymes[_rhymeIndex % rhymes.length];
    final choices = <StoryChoice>[
      StoryChoice(emoji: item.matchingEmoji, text: item.matchingWord),
      ...item.distractors,
    ]..shuffle(Random(item.id.hashCode));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          MascotBanner(
            character: MascotCharacter.fina,
            message:
                'Reim-Detektiv: Welches Wort klingt fast genauso und reimt sich auf „${item.targetWord}“?',
            onTap: () =>
                ref.read(audioServiceProvider).speakWord(item.targetWord),
          ),
          const SizedBox(height: 12),
          if (item.isMinimalPair)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.owlTeal.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '👂 Minimalpaar: Nur der erste Laut ändert sich!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.owlTeal,
                ),
              ),
            ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () =>
                ref.read(audioServiceProvider).speakWord(item.targetWord),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                child: Column(
                  children: [
                    Text(
                      item.targetEmoji,
                      style: const TextStyle(fontSize: 68),
                    ),
                    const SizedBox(height: 8),
                    SyllableTextWidget(
                      syllables: item.targetSyllables,
                      fontSize: 34,
                      showArcs: settings.showSyllableArcs,
                      showVowelCrowns: settings.showVowelCrowns,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.volume_up_rounded,
                          size: 20,
                          color: AppColors.syllableBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Aufgabe ${(_rhymeIndex % rhymes.length) + 1} von ${rhymes.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tippe auf das passende Reimwort:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final choice in choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      _checkRhymeAnswer(item, choice, rhymes.length),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F2937),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    side: const BorderSide(
                      color: AppColors.syllableBlue,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(choice.emoji, style: const TextStyle(fontSize: 34)),
                      const SizedBox(width: 14),
                      Text(
                        choice.text,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_rhymeAnswerCorrect != null) ...[
            const SizedBox(height: 10),
            Text(
              _rhymeAnswerCorrect!
                  ? (_rhymeBonusNewlyEarned
                      ? 'Spitze! „${item.targetWord} – ${item.matchingWord}“ reimt sich! +1 ⭐'
                      : 'Richtig! „${item.targetWord} – ${item.matchingWord}“ klingt gleich! ⭐')
                  : 'Sprich beide Wörter laut aus und hör auf das Ende!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _rhymeAnswerCorrect!
                    ? AppColors.successGreen
                    : AppColors.syllableRed,
              ),
            ),
          ],
          if (rhymes.length > 1) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() {
                _rhymeIndex = (_rhymeIndex + 1) % rhymes.length;
                _rhymeAnswerCorrect = null;
                _rhymeBonusNewlyEarned = false;
              }),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Nächstes Reim-Rätsel'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _checkRhymeAnswer(
    RhymePairItem item,
    StoryChoice chosen,
    int totalRhymes,
  ) async {
    final isRight = chosen.text == item.matchingWord;
    if (isRight) {
      await ref.read(audioServiceProvider).playSuccessChime();
      final newly = await ref
          .read(progressProvider.notifier)
          .awardBonusStar('rhyme_quiz:${item.id}');
      await ref.read(audioServiceProvider).speakWord(
            'Super! ${item.targetWord} und ${item.matchingWord}',
          );
      if (mounted) {
        setState(() {
          _rhymeAnswerCorrect = true;
          _rhymeBonusNewlyEarned = newly;
        });
      }
    } else {
      await ref.read(audioServiceProvider).playGentleHintChime();
      await ref
          .read(audioServiceProvider)
          .speakWord('${item.targetWord}. ${chosen.text}');
      if (mounted) {
        setState(() {
          _rhymeAnswerCorrect = false;
          _rhymeBonusNewlyEarned = false;
        });
      }
    }
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : const Color(0xFF1F2937),
        ),
      ),
      selected: selected,
      selectedColor: AppColors.syllableBlue,
      backgroundColor: Colors.white,
      onSelected: (_) => onTap(),
    );
  }
}

class _TrainWagonButton extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const _TrainWagonButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          side: const BorderSide(color: AppColors.syllableBlue, width: 2),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
