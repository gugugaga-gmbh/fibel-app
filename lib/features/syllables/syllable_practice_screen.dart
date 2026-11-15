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

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    final words = unit.words;
    final currentWord = words.isNotEmpty ? words[_wordIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Silben schwingen: ${unit.letter} ${unit.lowercase}'),
      ),
      body: SingleChildScrollView(
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
                        showArcs: true,
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
                final color = i % 2 == 0
                    ? AppColors.syllableBlue
                    : AppColors.syllableRed;

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
      ),
    );
  }
}
