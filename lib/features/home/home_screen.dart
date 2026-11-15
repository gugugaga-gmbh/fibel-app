import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/audio/audio_service.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/curriculum_repository.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculumAsync = ref.watch(curriculumProvider);
    final progress = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fips & Fina – Lese-Welt'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: const Text('⭐', style: TextStyle(fontSize: 18)),
              label: Text(
                '${progress.totalStars}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => context.push('/stickers'),
            ),
          ),
        ],
      ),
      body: curriculumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler beim Laden: $e')),
        data: (curriculum) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: MascotBanner(
                  character: MascotCharacter.fips,
                  message:
                      'Hallo ${progress.childName}! Wähle einen Buchstaben zum Lernen aus.',
                  onTap: () => ref
                      .read(audioServiceProvider)
                      .speakWord('Hallo! Wähle einen Buchstaben zum Lernen aus.'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/anlaut'),
                        icon: const Icon(Icons.grid_view_rounded),
                        label: const Text('Anlauttabelle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.syllableBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/stickers'),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Sticker'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.foxOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 190,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: curriculum.units.length,
                  itemBuilder: (context, index) {
                    final unit = curriculum.units[index];
                    final completedCount =
                        progress.completedCountForUnit(unit.id);

                    return InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _openUnitSheet(context, ref, unit),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    unit.letter,
                                    style: TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                      color: unit.color,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    unit.lowercase,
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w700,
                                      color: unit.color.withValues(alpha: 0.78),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${unit.anchorEmoji} ${unit.anchorWord}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(4, (starIdx) {
                                  final earned = starIdx < completedCount;
                                  return Icon(
                                    earned
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: earned
                                        ? AppColors.starGold
                                        : const Color(0xFFD1D5DB),
                                    size: 22,
                                  );
                                }),
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
        },
      ),
    );
  }

  void _openUnitSheet(BuildContext context, WidgetRef ref, LessonUnit unit) {
    ref
        .read(audioServiceProvider)
        .speakPhoneme('${unit.phoneme}. Wie ${unit.anchorWord}');
    final progress = ref.read(progressProvider);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${unit.anchorEmoji} Buchstabe ${unit.letter} ${unit.lowercase}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _ModuleTile(
                  icon: Icons.hearing_rounded,
                  color: AppColors.owlTeal,
                  title: '1. Laute hören',
                  subtitle: 'Anlaut-Zug & Anlauttabelle',
                  done: progress.isModuleCompleted(unit.id, ModuleType.phonics),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/unit/${unit.id}/phonics', extra: unit);
                  },
                ),
                const SizedBox(height: 10),
                _ModuleTile(
                  icon: Icons.edit_rounded,
                  color: AppColors.syllableBlue,
                  title: '2. Nachspuren & Schreiben',
                  subtitle: 'Im Dreilinien-Haus üben',
                  done: progress.isModuleCompleted(unit.id, ModuleType.tracing),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/unit/${unit.id}/tracing', extra: unit);
                  },
                ),
                const SizedBox(height: 10),
                _ModuleTile(
                  icon: Icons.waves_rounded,
                  color: AppColors.syllableRed,
                  title: '3. Silben schwingen',
                  subtitle: 'Silbenbögen & Silbenteppich',
                  done:
                      progress.isModuleCompleted(unit.id, ModuleType.syllables),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/unit/${unit.id}/syllables', extra: unit);
                  },
                ),
                const SizedBox(height: 10),
                _ModuleTile(
                  icon: Icons.menu_book_rounded,
                  color: AppColors.foxOrange,
                  title: '4. Wörter & Sätze',
                  subtitle: 'Silben-Puzzle & erstes Lesen',
                  done: progress.isModuleCompleted(unit.id, ModuleType.reading),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/unit/${unit.id}/reading', extra: unit);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      tileColor: color.withValues(alpha: 0.06),
      leading: CircleAvatar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: Icon(icon),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        done ? Icons.star_rounded : Icons.arrow_forward_ios_rounded,
        color: done ? AppColors.starGold : color,
        size: done ? 30 : 20,
      ),
    );
  }
}
