import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../core/audio/audio_service.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/curriculum_repository.dart';
import '../../core/i18n/daz_word_bridge.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/syllable_text_widget.dart';

/// Geführte 3-Stationen-Tages-Mission („Fips & Finas Abenteuer-Runde“)
/// kombiniert gezielte Fehler-Wiederholung (Spaced Repetition / Leitner-Boxen 1–3)
/// mit neuen Lerninhalten aus Hören, Silben und sinnentnehmendem Lesen.
class DailyMissionScreen extends ConsumerStatefulWidget {
  const DailyMissionScreen({super.key});

  @override
  ConsumerState<DailyMissionScreen> createState() => _DailyMissionScreenState();
}

class _MissionPlan {
  final LessonUnit phonicsUnit;
  final SoundQuizItem soundItem;
  final LessonUnit syllableUnit;
  final SyllableWord syllableWord;
  final bool useSyllablePuzzle;
  final List<String> syllableChoices;
  final String targetVowelKing;
  final LessonUnit readingUnit;
  final SentenceItem sentenceItem;
  final List<String> emojiChoices;
  final Set<String> reviewUnitIds;

  const _MissionPlan({
    required this.phonicsUnit,
    required this.soundItem,
    required this.syllableUnit,
    required this.syllableWord,
    required this.useSyllablePuzzle,
    required this.syllableChoices,
    required this.targetVowelKing,
    required this.readingUnit,
    required this.sentenceItem,
    required this.emojiChoices,
    required this.reviewUnitIds,
  });
}

class _DailyMissionScreenState extends ConsumerState<DailyMissionScreen> {
  static const _vowelDistractors = [
    'A',
    'E',
    'I',
    'O',
    'U',
    'Ei',
    'Au',
    'Eu',
    'Ie',
  ];

  int _roundSeed = 0;
  _MissionPlan? _plan;
  int _stationIndex = 0; // 0 = Hören, 1 = Silben, 2 = Lesen, 3 = Schatz-Feier
  bool? _stationFeedbackCorrect;
  bool _stationTransitioning = false;
  final List<String> _assembledSyllables = [];
  int? _tappedWordIdx;
  int _awardedStars = 0;

  _MissionPlan _generatePlan(
    CurriculumData curriculum,
    ChildProgress progress,
    int seed,
  ) {
    final rng = Random(101 + seed * 37 + progress.completedDailyMissions * 13);
    final accessible = curriculum.units
        .where((u) => progress.isStageAccessible(u.stage, curriculum.units))
        .toList();
    final fallbackPool = accessible.isNotEmpty
        ? accessible
        : curriculum.units;

    final reviewIds = progress.unitsNeedingReview(limit: 6);
    final prioritized = <LessonUnit>[];

    // 1. Spaced Repetition units due for review
    for (final id in reviewIds) {
      final match = fallbackPool.where((u) => u.id == id).firstOrNull;
      if (match != null && !prioritized.any((u) => u.id == match.id)) {
        prioritized.add(match);
      }
    }

    // 2. Unlocked units with open modules
    final unlocked = fallbackPool
        .where((u) => progress.isStageUnlocked(u.stage, curriculum.units))
        .toList();
    final activeStagePool = unlocked.isNotEmpty ? unlocked : fallbackPool;

    for (final u in activeStagePool) {
      if (progress.completedCountForUnit(u.id) < 4 &&
          !prioritized.any((p) => p.id == u.id)) {
        prioritized.add(u);
      }
    }

    // 3. Fill remaining slots from active stage pool
    for (final u in activeStagePool) {
      if (!prioritized.any((p) => p.id == u.id)) {
        prioritized.add(u);
      }
    }

    LessonUnit pickUnit(int slot, bool Function(LessonUnit) predicate) {
      final matches = prioritized.where(predicate).toList();
      if (matches.isEmpty) return prioritized.first;
      return matches[(slot + seed) % matches.length];
    }

    final u1 = pickUnit(0, (u) => u.soundQuiz.isNotEmpty);
    final soundItem = u1.soundQuiz[rng.nextInt(u1.soundQuiz.length)];

    final u2 = pickUnit(
      1,
      (u) => u.words.isNotEmpty && u.id != u1.id,
    );
    final multiSyllableWords =
        u2.words.where((w) => w.syllables.length >= 2).toList();
    final syllableWord = multiSyllableWords.isNotEmpty
        ? multiSyllableWords[rng.nextInt(multiSyllableWords.length)]
        : u2.words[rng.nextInt(u2.words.length)];
    final usePuzzle = syllableWord.syllables.length >= 2;
    final king =
        SyllableWord.extractVowelKing(syllableWord.syllables.first).trim();
    final normalizedKing = king.isEmpty
        ? 'A'
        : '${king[0].toUpperCase()}${king.substring(1).toLowerCase()}';

    final List<String> sylChoices;
    if (usePuzzle) {
      sylChoices = List<String>.from(syllableWord.syllables)..shuffle(rng);
      if (sylChoices.join() == syllableWord.fullWord &&
          sylChoices.length >= 2 &&
          sylChoices.first != sylChoices.last) {
        final first = sylChoices.removeAt(0);
        sylChoices.add(first);
      }
    } else {
      final distractors = _vowelDistractors
          .where((v) => v.toLowerCase() != normalizedKing.toLowerCase())
          .toList()
        ..shuffle(rng);
      sylChoices = [normalizedKing, ...distractors.take(2)]..shuffle(rng);
    }

    final u3 = pickUnit(
      2,
      (u) => u.sentences.isNotEmpty && u.id != u1.id && u.id != u2.id,
    );
    final sentenceItem = u3.sentences[rng.nextInt(u3.sentences.length)];
    final emojiChoices = <String>[
      sentenceItem.emoji,
      ...sentenceItem.distractorEmojis.take(2),
    ]..shuffle(rng);

    return _MissionPlan(
      phonicsUnit: u1,
      soundItem: soundItem,
      syllableUnit: u2,
      syllableWord: syllableWord,
      useSyllablePuzzle: usePuzzle,
      syllableChoices: sylChoices,
      targetVowelKing: normalizedKing,
      readingUnit: u3,
      sentenceItem: sentenceItem,
      emojiChoices: emojiChoices,
      reviewUnitIds: reviewIds.toSet(),
    );
  }

  void _startNewRound(CurriculumData curriculum, ChildProgress progress) {
    setState(() {
      _roundSeed++;
      _stationIndex = 0;
      _stationFeedbackCorrect = null;
      _stationTransitioning = false;
      _assembledSyllables.clear();
      _tappedWordIdx = null;
      _awardedStars = 0;
      _plan = _generatePlan(curriculum, progress, _roundSeed);
    });
  }

  Future<void> _completeCurrentStation(
    String unitId, {
    required bool isFinalStation,
  }) async {
    if (_stationTransitioning) return;
    setState(() {
      _stationFeedbackCorrect = true;
      _stationTransitioning = true;
    });

    final notifier = ref.read(progressProvider.notifier);
    await notifier.recordMissionStepSuccess(unitId);

    if (isFinalStation) {
      await ref.read(audioServiceProvider).playCelebrationFanfare();
      final stars = await notifier.completeDailyMission();
      await ref.read(audioServiceProvider).speakWord(
            'Juhu! Du hast die Abenteuer-Runde geschafft und $stars Bonus-Sterne gewonnen!',
          );
      if (!mounted) return;
      setState(() {
        _awardedStars = stars;
        _stationIndex = 3;
        _stationFeedbackCorrect = null;
        _stationTransitioning = false;
      });
    } else {
      await ref.read(audioServiceProvider).playSuccessChime();
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() {
        _stationIndex++;
        _stationFeedbackCorrect = null;
        _stationTransitioning = false;
        _assembledSyllables.clear();
        _tappedWordIdx = null;
      });
    }
  }

  Future<void> _handleMistake(String unitId, String spokenHint) async {
    if (_stationTransitioning) return;
    setState(() => _stationFeedbackCorrect = false);
    await ref.read(audioServiceProvider).playGentleHintChime();
    await ref.read(progressProvider.notifier).recordMistake(unitId);
    await ref.read(audioServiceProvider).speakWord(spokenHint);
  }

  @override
  Widget build(BuildContext context) {
    final curriculumAsync = ref.watch(curriculumProvider);
    final progress = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fips & Finas Abenteuer-Runde 🧭'),
      ),
      body: curriculumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (curriculum) {
          _plan ??= _generatePlan(curriculum, progress, _roundSeed);
          final plan = _plan!;

          return Column(
            children: [
              _buildStationProgressHeader(plan),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: switch (_stationIndex) {
                    0 => _buildStation1Phonics(plan),
                    1 => _buildStation2Syllables(plan, progress.settings),
                    2 => _buildStation3Reading(plan, progress.settings),
                    _ => _buildCelebrationView(plan, curriculum, progress),
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStationProgressHeader(_MissionPlan plan) {
    const stations = [
      ('1. Hören', '🚂'),
      ('2. Silben', '👑'),
      ('3. Lesen', '📖'),
      ('Schatz', '🎁'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(stations.length, (idx) {
          final done = idx < _stationIndex || _stationIndex == 3;
          final current = idx == _stationIndex && _stationIndex < 3;
          final bg = done
              ? AppColors.successGreen
              : (current ? AppColors.syllableBlue : const Color(0xFFF3F4F6));
          final fg = (done || current) ? Colors.white : const Color(0xFF4B5563);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  done && idx < 3 ? '✓' : stations[idx].$2,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  stations[idx].$1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReviewBadgeIfDue(_MissionPlan plan, LessonUnit unit) {
    if (!plan.reviewUnitIds.contains(unit.id)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.starGold.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '🔁 Schatzkisten-Wiederholung: Laut ${unit.letter}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF92400E),
          ),
        ),
      ),
    );
  }

  Widget _buildStation1Phonics(_MissionPlan plan) {
    final unit = plan.phonicsUnit;
    final item = plan.soundItem;

    return Column(
      children: [
        _buildReviewBadgeIfDue(plan, unit),
        MascotBanner(
          character: MascotCharacter.fina,
          message:
              'Station 1: Wo hörst du das „${unit.phoneme}“ (${unit.letter}) in „${item.word}“?',
          onTap: () => ref.read(audioServiceProvider).speakWord(item.word),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => ref.read(audioServiceProvider).speakWord(item.word),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
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
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  DazWordBridgeChip(germanWord: item.word),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _StationChoiceButton(
              emoji: '🚂',
              label: 'Anfang',
              onTap: () => _checkSoundPosition(unit, item, SoundPosition.start),
            ),
            const SizedBox(width: 10),
            _StationChoiceButton(
              emoji: '🚃',
              label: 'Mitte',
              onTap: () =>
                  _checkSoundPosition(unit, item, SoundPosition.middle),
            ),
            const SizedBox(width: 10),
            _StationChoiceButton(
              emoji: '🚋',
              label: 'Ende',
              onTap: () => _checkSoundPosition(unit, item, SoundPosition.end),
            ),
          ],
        ),
        _buildFeedbackBanner(
          rightText: 'Super gehört! Weiter zu Station 2! ⭐',
          retryText: 'Hör noch einmal genau hin: „${item.word}“.',
        ),
      ],
    );
  }

  Future<void> _checkSoundPosition(
    LessonUnit unit,
    SoundQuizItem item,
    SoundPosition chosen,
  ) async {
    if (chosen == item.position) {
      await _completeCurrentStation(unit.id, isFinalStation: false);
    } else {
      await _handleMistake(unit.id, item.word);
    }
  }

  Widget _buildStation2Syllables(_MissionPlan plan, AppSettings settings) {
    final unit = plan.syllableUnit;
    final word = plan.syllableWord;

    if (plan.useSyllablePuzzle) {
      return Column(
        children: [
          _buildReviewBadgeIfDue(plan, unit),
          MascotBanner(
            character: MascotCharacter.fips,
            message:
                'Station 2: Baue das Wort „${word.fullWord}“ aus den Silben zusammen!',
            onTap: () =>
                ref.read(audioServiceProvider).speakWord(word.fullWord),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                children: [
                  Text(word.emoji, style: const TextStyle(fontSize: 68)),
                  DazWordBridgeChip(germanWord: word.fullWord),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(minHeight: 64),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _assembledSyllables.isEmpty
                          ? const Text(
                              'Tippe unten in der richtigen Reihenfolge...',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            )
                          : SyllableTextWidget(
                              syllables: _assembledSyllables,
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
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: plan.syllableChoices.map((syl) {
              return ElevatedButton(
                onPressed: () => _onSelectPuzzleSyllable(unit, word, syl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.syllableBlue,
                  side: const BorderSide(
                    color: AppColors.syllableBlue,
                    width: 2.5,
                  ),
                  minimumSize: const Size(96, 62),
                ),
                child: Text(
                  syl,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_assembledSyllables.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() {
                _assembledSyllables.clear();
                _stationFeedbackCorrect = null;
              }),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Neu zusammensetzen'),
            ),
          ],
          _buildFeedbackBanner(
            rightText: 'Klasse gepuzzelt! Jetzt zum Lese-Finale! ⭐',
            retryText: 'Fast! Höre das Wort an und versuche es noch einmal.',
          ),
        ],
      );
    }

    // Single-syllable word -> Silbenkönig-Krone quiz
    return Column(
      children: [
        _buildReviewBadgeIfDue(plan, unit),
        MascotBanner(
          character: MascotCharacter.fips,
          message:
              'Station 2: Welcher Silbenkönig 👑 klingt in „${word.fullWord}“?',
          onTap: () => ref.read(audioServiceProvider).speakWord(word.fullWord),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
            child: Column(
              children: [
                Text(word.emoji, style: const TextStyle(fontSize: 68)),
                const SizedBox(height: 8),
                Text(
                  word.fullWord,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DazWordBridgeChip(germanWord: word.fullWord),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: plan.syllableChoices.map((vowel) {
            return ElevatedButton(
              onPressed: () async {
                if (vowel.toLowerCase() ==
                    plan.targetVowelKing.toLowerCase()) {
                  await _completeCurrentStation(unit.id, isFinalStation: false);
                } else {
                  await _handleMistake(unit.id, word.fullWord);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.foxOrange,
                side: const BorderSide(color: AppColors.starGold, width: 2.5),
                minimumSize: const Size(96, 66),
              ),
              child: Text(
                '👑 $vowel',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }).toList(),
        ),
        _buildFeedbackBanner(
          rightText: 'Richtiger Silbenkönig! Weiter zum Lese-Finale! ⭐',
          retryText: 'Sprich „${word.fullWord}“ langsam und achte auf den König!',
        ),
      ],
    );
  }

  Future<void> _onSelectPuzzleSyllable(
    LessonUnit unit,
    SyllableWord target,
    String syllable,
  ) async {
    if (_stationTransitioning) return;
    await ref.read(audioServiceProvider).speakSyllable(syllable);
    setState(() {
      _assembledSyllables.add(syllable);
    });

    if (_assembledSyllables.length >= target.syllables.length) {
      if (_assembledSyllables.join() == target.fullWord) {
        await _completeCurrentStation(unit.id, isFinalStation: false);
      } else {
        await _handleMistake(unit.id, target.fullWord);
        if (!mounted) return;
        setState(() => _assembledSyllables.clear());
      }
    }
  }

  Widget _buildStation3Reading(_MissionPlan plan, AppSettings settings) {
    final unit = plan.readingUnit;
    final sentence = plan.sentenceItem;

    return Column(
      children: [
        _buildReviewBadgeIfDue(plan, unit),
        MascotBanner(
          character: MascotCharacter.fina,
          message:
              'Station 3 (Lese-Finale): Lies den Satz und tippe auf das passende Bild!',
          onTap: () => ref.read(audioServiceProvider).speakWord(sentence.text),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: List.generate(sentence.words.length, (idx) {
                    final w = sentence.words[idx];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _tappedWordIdx = idx);
                        ref.read(audioServiceProvider).speakWord(w.fullWord);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _tappedWordIdx == idx
                              ? AppColors.starGold.withValues(alpha: 0.25)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SyllableTextWidget(
                          syllables: w.syllables,
                          fontSize: 30,
                          showArcs: settings.showSyllableArcs,
                          showVowelCrowns: settings.showVowelCrowns,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(audioServiceProvider).speakWord(sentence.text),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Satz anhören'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Welches Bild passt zum Satz?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: plan.emojiChoices.map((emoji) {
            return ElevatedButton(
              onPressed: () async {
                if (emoji == sentence.emoji) {
                  await _completeCurrentStation(unit.id, isFinalStation: true);
                } else {
                  await _handleMistake(unit.id, sentence.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(
                  color: AppColors.syllableBlue,
                  width: 2.5,
                ),
                minimumSize: const Size(98, 86),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 48)),
            );
          }).toList(),
        ),
        _buildFeedbackBanner(
          rightText: 'Fantastisch gelesen! Dein Schatz öffnet sich! 🎉',
          retryText: 'Lies noch einmal jedes Wort in Ruhe durch!',
        ),
      ],
    );
  }

  Widget _buildCelebrationView(
    _MissionPlan plan,
    CurriculumData curriculum,
    ChildProgress progress,
  ) {
    final boxes = progress.masteryBoxCounts;
    final practicedLetters = <String>{
      plan.phonicsUnit.letter,
      plan.syllableUnit.letter,
      plan.readingUnit.letter,
    }.join(' • ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🧭🏆🎉', style: TextStyle(fontSize: 58)),
            const SizedBox(height: 12),
            const Text(
              'Abenteuer-Runde geschafft!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Du hast +$_awardedStars Bonus-${_awardedStars == 1 ? "Stern" : "Sterne"} für dein Sticker-Album gewonnen!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.foxOrange,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.owlTeal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text(
                    'Geübte Laute dieser Runde: $practicedLetters',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Deine Lern-Schatzkiste: 🌱 ${boxes.box1} • 🌿 ${boxes.box2} • 🌳 ${boxes.box3}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _startNewRound(curriculum, progress),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Noch eine Runde spielen'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Zur Lese-Welt'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackBanner({
    required String rightText,
    required String retryText,
  }) {
    if (_stationFeedbackCorrect == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Text(
        _stationFeedbackCorrect! ? rightText : retryText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _stationFeedbackCorrect!
              ? AppColors.successGreen
              : AppColors.syllableRed,
        ),
      ),
    );
  }
}

class _StationChoiceButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _StationChoiceButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.syllableBlue,
          side: const BorderSide(color: AppColors.syllableBlue, width: 2.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
