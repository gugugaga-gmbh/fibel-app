import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/audio/audio_service.dart';
import '../../core/curriculum/curriculum_repository.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/parental_gate_dialog.dart';
import '../../core/widgets/stage_certificate_dialog.dart';

class StickerAlbumScreen extends ConsumerStatefulWidget {
  const StickerAlbumScreen({super.key});

  @override
  ConsumerState<StickerAlbumScreen> createState() => _StickerAlbumScreenState();
}

class _StickerAlbumScreenState extends ConsumerState<StickerAlbumScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
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
                context.push('/parents');
              }
            },
          ),
        ],
      ),
      body: curriculumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (curriculum) {
          final categories = curriculum.stickers
              .map((s) => s.category)
              .toSet()
              .toList();
          final filtered = _selectedCategory == null
              ? curriculum.stickers
              : curriculum.stickers
                  .where((s) => s.category == _selectedCategory)
                  .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: MascotBanner(
                  character: MascotCharacter.fips,
                  message:
                      'Du hast schon ${progress.totalStars} Sterne gesammelt! Tippe auf deine freigeschalteten Sticker!',
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: curriculum.stages.map((stage) {
                    final earned = progress.isStageCertificateEarned(
                      stage,
                      curriculum.units,
                    );
                    final story = curriculum.storyForStage(stage);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Text(
                          earned ? '🏆' : '🔒',
                          style: const TextStyle(fontSize: 16),
                        ),
                        label: Text(
                          'Urkunde Stufe $stage',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: earned
                                ? const Color(0xFF1F2937)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        backgroundColor: earned
                            ? AppColors.starGold.withValues(alpha: 0.22)
                            : Colors.white,
                        onPressed: () {
                          if (earned) {
                            ref
                                .read(audioServiceProvider)
                                .playCelebrationFanfare();
                            StageCertificateDialog.show(
                              context,
                              stage: stage,
                              story: story,
                              progress: progress,
                              allUnits: curriculum.units,
                            );
                          } else {
                            ref.read(audioServiceProvider).speakWord(
                                  'Lies die Geschichte von Stufe $stage im Lesepass oder sammle die Stufen-Sterne für diese Urkunde!',
                                );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Alle'),
                      selected: _selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                    ),
                    for (final cat in categories) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final sticker = filtered[idx];
                    final unlocked =
                        progress.totalStars >= sticker.requiredStars;

                    return InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        if (unlocked) {
                          ref
                              .read(audioServiceProvider)
                              .speakWord(sticker.voiceText);
                        } else {
                          ref.read(audioServiceProvider).speakWord(
                                'Sammle insgesamt ${sticker.requiredStars} Sterne für ${sticker.name}.',
                              );
                        }
                      },
                      child: Card(
                        color:
                            unlocked ? Colors.white : const Color(0xFFF3F4F6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                unlocked ? sticker.emoji : '🔒',
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                sticker.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
}
