import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_service.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/syllable_text_widget.dart';

class SyllablePracticeScreen extends ConsumerStatefulWidget {
  final LessonUnit unit;

  const SyllablePracticeScreen({super.key, required this.unit});

  @override
  ConsumerState<SyllablePracticeScreen> createState() =>
      _SyllablePracticeScreenState();
}

class _SyllablePracticeScreenState
    extends ConsumerState<SyllablePracticeScreen> {
  int _wordIndex = 0;
  int? _highlightedSyllable;
  final Set<String> _tappedCombos = {};

  // Silben-Klatschen bonus quiz state
  int _clapQuizIdx = 0;
  bool? _clapCorrect;
  bool _clapQuizFinished = false;

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    final progress = ref.watch(progressProvider);
    final bonusEarned = progress.isBonusCompleted('syllable_clap:${unit.id}');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Silben schwingen: ${unit.letter} ${unit.lowercase}'),
          bottom: TabBar(
            tabs: [
              const Tab(
                icon: Icon(Icons.waves_rounded),
                text: 'Silben & Teppich',
              ),
              Tab(
                icon: Icon(
                  bonusEarned
                      ? Icons.stars_rounded
                      : Icons.pan_tool_alt_rounded,
                  color: bonusEarned ? AppColors.starGold : null,
                ),
                text: 'Silben klatschen ⭐',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCarpetTab(unit, progress),
            _buildClapQuizTab(unit, bonusEarned),
          ],
        ),
      ),
    );
  }

  Widget _buildCarpetTab(LessonUnit unit, ChildProgress progress) {
    final words = unit.words;
    final currentWord = words.isNotEmpty ? words[_wordIndex] : null;
    final settings = progress.settings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MascotBanner(
            character: MascotCharacter.fina,
            message:
                'Tippe auf die blauen und roten Silbenbögen, um das Wort zu schwingen!',
            onTap: currentWord != null
                ? () => ref
                    .read(audioServiceProvider)
                    .speakWord(currentWord.fullWord)
                : null,
          ),
          const SizedBox(height: 16),
          if (currentWord != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      currentWord.emoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 12),
                    SyllableTextWidget(
                      syllables: currentWord.syllables,
                      fontSize: 44,
                      showArcs: settings.showSyllableArcs,
                      showVowelCrowns: settings.showVowelCrowns,
                      highlightedIndex: _highlightedSyllable,
                      onSyllableTap: (idx) {
                        setState(() => _highlightedSyllable = idx);
                        ref
                            .read(audioServiceProvider)
                            .speakSyllable(currentWord.syllables[idx]);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(audioServiceProvider)
                              .speakWord(currentWord.fullWord),
                          icon: const Icon(Icons.volume_up_rounded),
                          label: const Text('Ganzes Wort'),
                        ),
                        const SizedBox(width: 12),
                        if (words.length > 1)
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _wordIndex = (_wordIndex + 1) % words.length;
                                _highlightedSyllable = null;
                              });
                            },
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Nächstes'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Silbenteppich – Tippe jede Silbe an:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(unit.syllableCombos.length, (i) {
              final combo = unit.syllableCombos[i];
              final tapped = _tappedCombos.contains(combo);
              final color =
                  i % 2 == 0 ? AppColors.syllableBlue : AppColors.syllableRed;

              return ElevatedButton(
                onPressed: () async {
                  setState(() => _tappedCombos.add(combo));
                  await ref.read(audioServiceProvider).speakSyllable(combo);
                  if (_tappedCombos.length == unit.syllableCombos.length) {
                    await ref
                        .read(progressProvider.notifier)
                        .completeModule(unit.id, ModuleType.syllables);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tapped ? color : Colors.white,
                  foregroundColor: tapped ? Colors.white : color,
                  side: BorderSide(color: color, width: 2.5),
                  minimumSize: const Size(88, 64),
                ),
                child: Text(
                  combo,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }),
          ),
          if (_tappedCombos.length == unit.syllableCombos.length &&
              unit.syllableCombos.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Klasse! Du hast alle Silben geübt! ⭐',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.successGreen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClapQuizTab(LessonUnit unit, bool bonusEarned) {
    if (unit.words.isEmpty) {
      return const Center(child: Text('Keine Wörter vorhanden.'));
    }

    if (_clapQuizFinished) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👏🌟', style: TextStyle(fontSize: 68)),
              const SizedBox(height: 16),
              const Text(
                'Super geklatscht! Du hast den Bonus-Stern gewonnen! ⭐',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _clapQuizIdx = 0;
                    _clapCorrect = null;
                    _clapQuizFinished = false;
                  });
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Noch einmal spielen'),
              ),
            ],
          ),
        ),
      );
    }

    final target = unit.words[_clapQuizIdx % unit.words.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          MascotBanner(
            character: MascotCharacter.fina,
            message:
                'Klatsche mit! Wie viele Silben hat das Wort „${target.fullWord}“?',
            onTap: () =>
                ref.read(audioServiceProvider).speakWord(target.fullWord),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () =>
                ref.read(audioServiceProvider).speakWord(target.fullWord),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
                child: Column(
                  children: [
                    Text(target.emoji, style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 12),
                    if (_clapCorrect == true)
                      SyllableTextWidget(
                        syllables: target.syllables,
                        fontSize: 38,
                        showVowelCrowns: true,
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.volume_up_rounded,
                            color: AppColors.syllableBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            target.fullWord,
                            style: const TextStyle(
                              fontSize: 30,
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
            'Tippe auf die richtige Silben-Anzahl:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [1, 2, 3].map((count) {
              final claps = List.filled(count, '👏').join();
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ElevatedButton(
                    onPressed: () => _onSelectClapCount(unit, target, count),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.syllableBlue,
                      side: const BorderSide(
                        color: AppColors.syllableBlue,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Column(
                      children: [
                        Text(claps, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 6),
                        Text(
                          '$count ${count == 1 ? 'Silbe' : 'Silben'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (_clapCorrect != null)
            Text(
              _clapCorrect!
                  ? 'Genau! „${target.fullWord}“ hat ${target.syllables.length} ${target.syllables.length == 1 ? 'Silbe' : 'Silben'}! ⭐'
                  : 'Sprich das Wort langsam mit und klatsche noch einmal!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _clapCorrect!
                    ? AppColors.successGreen
                    : AppColors.syllableRed,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onSelectClapCount(
    LessonUnit unit,
    SyllableWord target,
    int chosenCount,
  ) async {
    final isRight = chosenCount == target.syllables.length;
    setState(() => _clapCorrect = isRight);

    if (isRight) {
      await ref
          .read(audioServiceProvider)
          .speakWord('Richtig! ${target.syllables.join(' - ')}');
      if (_clapQuizIdx + 1 < unit.words.length) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          setState(() {
            _clapQuizIdx++;
            _clapCorrect = null;
          });
        });
      } else {
        await ref
            .read(progressProvider.notifier)
            .awardBonusStar('syllable_clap:${unit.id}');
        if (mounted) {
          setState(() => _clapQuizFinished = true);
        }
      }
    } else {
      await ref.read(audioServiceProvider).speakWord(target.fullWord);
    }
  }
}
