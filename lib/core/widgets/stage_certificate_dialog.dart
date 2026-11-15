import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../audio/audio_service.dart';
import '../curriculum/curriculum_models.dart';
import '../storage/progress_repository.dart';
import '../theme/app_theme.dart';

class StageCertificateDialog extends ConsumerWidget {
  final int stage;
  final StageStory? story;
  final ChildProgress progress;
  final List<LessonUnit> allUnits;

  const StageCertificateDialog({
    super.key,
    required this.stage,
    required this.story,
    required this.progress,
    required this.allUnits,
  });

  static Future<void> show(
    BuildContext context, {
    required int stage,
    required StageStory? story,
    required ChildProgress progress,
    required List<LessonUnit> allUnits,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => StageCertificateDialog(
        stage: stage,
        story: story,
        progress: progress,
        allUnits: allUnits,
      ),
    );
  }

  static String stageTitleFor(int stage) {
    return switch (stage) {
      1 => 'Silben-Starter (Stufe 1)',
      2 => 'Wörter-Baumeister (Stufe 2)',
      3 => 'Geheimzeichen-Entdecker (Stufe 3)',
      _ => 'Lese-Meister der 1. Klasse (Stufe 4)',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stageStats = progress.stageProgress(stage, allUnits);
    final stageLetters = allUnits
        .where((u) => u.stage == stage)
        .map((u) => u.letter)
        .join(' • ');
    final rankTitle = stageTitleFor(stage);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.starGold, width: 4),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🦊', style: TextStyle(fontSize: 34)),
                    SizedBox(width: 10),
                    Text('🏆', style: TextStyle(fontSize: 44)),
                    SizedBox(width: 10),
                    Text('🦉', style: TextStyle(fontSize: 34)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'LESE-URKUNDE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: AppColors.syllableBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rankTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foxOrange,
                  ),
                ),
                const Divider(height: 24, thickness: 1.5),
                Text(
                  progress.avatarEmoji,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 4),
                Text(
                  progress.childName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  story != null
                      ? 'hat das Abenteuer „${story!.title}“ und die Buchstaben von Stufe $stage erfolgreich gemeistert!'
                      : 'hat die Buchstaben und Übungen von Stufe $stage erfolgreich gemeistert!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.starGold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Gelernte Laute dieser Stufe:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stageLetters,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.syllableBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stufen-Sterne: ${stageStats.earned}/${stageStats.max} ⭐ • Gesamt: ${progress.totalStars} ⭐',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(audioServiceProvider)
                            .playCelebrationFanfare();
                        await ref.read(audioServiceProvider).speakWord(
                              'Herzlichen Glückwunsch, ${progress.childName}! '
                              'Du hast die Lese-Urkunde als $rankTitle gewonnen!',
                            );
                      },
                      icon: const Icon(Icons.volume_up_rounded),
                      label: const Text('Urkunde vorlesen'),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Schließen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
