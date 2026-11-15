import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/curriculum/curriculum_repository.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/parental_gate_dialog.dart';

class StickerAlbumScreen extends ConsumerWidget {
  const StickerAlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final curriculumAsync = ref.watch(curriculumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Sticker-Album'),
        actions: [
          IconButton(
            tooltip: 'Elternbereich',
            icon: const Icon(Icons.lock_outline_rounded),
            onPressed: () async {
              final allowed = await ParentalGateDialog.show(context);
              if (allowed && context.mounted) {
                _showParentsDialog(context, ref);
              }
            },
          ),
        ],
      ),
      body: curriculumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (curriculum) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: MascotBanner(
                  character: MascotCharacter.fips,
                  message:
                      'Du hast schon ${progress.totalStars} Sterne gesammelt! Sammle weiter für neue Sticker.',
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: curriculum.stickers.length,
                  itemBuilder: (context, idx) {
                    final sticker = curriculum.stickers[idx];
                    final unlocked =
                        progress.totalStars >= sticker.requiredStars;

                    return Card(
                      color: unlocked
                          ? Colors.white
                          : const Color(0xFFF3F4F6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              unlocked ? sticker.emoji : '🔒',
                              style: const TextStyle(fontSize: 52),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sticker.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: unlocked
                                    ? const Color(0xFF1F2937)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              unlocked
                                  ? 'Freigeschaltet!'
                                  : 'Ab ${sticker.requiredStars} ⭐',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: unlocked
                                    ? AppColors.successGreen
                                    : const Color(0xFF6B7280),
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
        },
      ),
    );
  }

  void _showParentsDialog(BuildContext context, WidgetRef ref) {
    final progress = ref.read(progressProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elternbereich'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kind: ${progress.childName}'),
            const SizedBox(height: 6),
            Text('Gesammelte Sterne: ${progress.totalStars}'),
            const SizedBox(height: 6),
            Text(
              'Bearbeitete Buchstaben: ${progress.completedModulesByUnit.length}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(progressProvider.notifier).resetAll();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.syllableRed),
            child: const Text('Fortschritt zurücksetzen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}
