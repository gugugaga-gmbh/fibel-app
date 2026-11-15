import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_service.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/curriculum_repository.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    final curriculumAsync = ref.watch(curriculumProvider);
    final unit = widget.unit;

    return DefaultTabController(
      length: unit != null ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            unit != null
                ? 'Laute hören: ${unit.letter} ${unit.lowercase}'
                : 'Anlauttabelle',
          ),
          bottom: unit != null
              ? const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.train_rounded), text: 'Laut-Zug'),
                    Tab(icon: Icon(Icons.grid_view_rounded), text: 'Anlauttabelle'),
                  ],
                )
              : null,
        ),
        body: curriculumAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fehler: $e')),
          data: (curriculum) {
            if (unit == null) {
              return _buildAnlautGrid(curriculum.anlautTable);
            }
            return TabBarView(
              children: [
                _buildSoundTrainQuiz(unit),
                _buildAnlautGrid(curriculum.anlautTable),
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
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          MascotBanner(
            character: MascotCharacter.fina,
            message:
                'Wo hörst du das „${unit.phoneme}“ in „${item.word}“?',
            onTap: () => ref.read(audioServiceProvider).speakWord(item.word),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => ref.read(audioServiceProvider).speakWord(item.word),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 28,
                ),
                child: Column(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volume_up_rounded,
                            color: AppColors.syllableBlue),
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
          const SizedBox(height: 28),
          const Text(
            'Tippe auf den richtigen Waggon:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
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
      await ref.read(audioServiceProvider).speakWord(item.word);
    }
  }

  Widget _buildAnlautGrid(List<AnlautEntry> entries) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: MascotBanner(
            character: MascotCharacter.fips,
            message: 'Tippe auf ein Bild, um den Anlaut zu hören!',
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  ref
                      .read(audioServiceProvider)
                      .speakPhoneme('${entry.phoneme}. ${entry.word}');
                },
                child: Card(
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
                        Text(entry.emoji, style: const TextStyle(fontSize: 34)),
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
              );
            },
          ),
        ),
      ],
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
