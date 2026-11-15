import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/audio/audio_service.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/curriculum_repository.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/parental_gate_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _selectedStage;

  @override
  Widget build(BuildContext context) {
    final curriculumAsync = ref.watch(curriculumProvider);
    final progress = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fips & Fina – Lese-Welt'),
        actions: [
          IconButton(
            tooltip: 'Fips & Fina Tour',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showOnboardingTourDialog(context, ref),
          ),
          ActionChip(
            avatar: Text(
              progress.avatarEmoji,
              style: const TextStyle(fontSize: 16),
            ),
            label: Text(
              progress.childName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => _openProfileSheet(context, ref),
          ),
          const SizedBox(width: 8),
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
          final visibleUnits = _selectedStage == null
              ? curriculum.units
              : curriculum.unitsForStage(_selectedStage!);
          final reviewCount = progress.unitsNeedingReview().length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: MascotBanner(
                  character: MascotCharacter.fips,
                  message:
                      'Hallo ${progress.childName}! Wähle einen Buchstaben zum Lernen aus.',
                  onTap: () => ref
                      .read(audioServiceProvider)
                      .speakWord('Hallo! Wähle einen Buchstaben zum Lernen aus.'),
                ),
              ),
              // Daily goal & Adaptive Daily Training bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tagesziel: ${progress.dailyCompletedCount}/${progress.dailyGoalTarget} • ${progress.streakDays} 🔥'
                          '${reviewCount > 0 ? ' • $reviewCount Übungs-Tipps' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: const Size(48, 36),
                        ),
                        onPressed: () => _startDailyTraining(
                          context,
                          curriculum.units,
                          progress,
                        ),
                        icon: const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 20,
                        ),
                        label: const Text(
                          'Tägliches Training',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/anlaut'),
                        icon: const Icon(Icons.grid_view_rounded, size: 18),
                        label: const Text(
                          'Anlauttabelle',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.syllableBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/werkstatt'),
                        icon: const Icon(Icons.keyboard_alt_rounded, size: 18),
                        label: const Text(
                          'Werkstatt',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.owlTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(
                          '/stories',
                          extra: _selectedStage ?? 1,
                        ),
                        icon: const Icon(Icons.auto_stories_rounded, size: 18),
                        label: const Text(
                          'Geschichten',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7E57C2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/stickers'),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: const Text(
                          'Sticker',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.foxOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Alle Stufen'),
                      selected: _selectedStage == null,
                      onSelected: (_) =>
                          setState(() => _selectedStage = null),
                    ),
                    for (final stage in [1, 2, 3, 4]) ...[
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) {
                          final unlocked = progress.isStageUnlocked(
                            stage,
                            curriculum.units,
                          );
                          final strictLock =
                              progress.settings.strictStageLock;
                          final label = unlocked
                              ? 'Stufe $stage'
                              : (strictLock
                                  ? '🔒 Stufe $stage'
                                  : '💡 Stufe $stage');
                          return ChoiceChip(
                            label: Text(label),
                            selected: _selectedStage == stage,
                            onSelected: (_) =>
                                setState(() => _selectedStage = stage),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              if (_selectedStage != null)
                _buildStageStoryBanner(
                  context,
                  curriculum.storyForStage(_selectedStage!),
                  progress,
                ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 190,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: visibleUnits.length,
                  itemBuilder: (context, index) {
                    final unit = visibleUnits[index];
                    final completedCount =
                        progress.completedCountForUnit(unit.id);
                    final stageUnlocked = progress.isStageUnlocked(
                      unit.stage,
                      curriculum.units,
                    );
                    final accessible = progress.isStageAccessible(
                      unit.stage,
                      curriculum.units,
                    );
                    final needsReview =
                        (progress.mistakeCountsByUnit[unit.id] ?? 0) > 0;

                    return InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        if (!accessible) {
                          _showStageLockedDialog(
                            context,
                            ref,
                            unit.stage,
                            curriculum.units,
                            progress,
                          );
                        } else {
                          _openUnitSheet(
                            context,
                            ref,
                            unit,
                            showRecommendationHint: !stageUnlocked,
                          );
                        }
                      },
                      child: Card(
                        color: accessible
                            ? Colors.white
                            : const Color(0xFFF3F4F6),
                        child: Stack(
                          children: [
                            if (!accessible)
                              const Positioned(
                                top: 8,
                                right: 10,
                                child: Text(
                                  '🔒',
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            else if (unit.isVowel &&
                                progress.settings.showVowelCrowns)
                              const Positioned(
                                top: 8,
                                right: 10,
                                child: Text(
                                  '👑',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                            if (needsReview && accessible)
                              const Positioned(
                                top: 8,
                                left: 10,
                                child: Tooltip(
                                  message: 'Empfohlen zum Wiederholen',
                                  child: Text(
                                    '🔁',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          unit.letter,
                                          style: TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w800,
                                            color: accessible
                                                ? unit.color
                                                : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          unit.lowercase,
                                          style: TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w700,
                                            color: accessible
                                                ? unit.color
                                                    .withValues(alpha: 0.78)
                                                : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${unit.anchorEmoji} ${unit.anchorWord}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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

  Widget _buildStageStoryBanner(
    BuildContext context,
    StageStory? story,
    ChildProgress progress,
  ) {
    if (story == null) return const SizedBox.shrink();
    final done = progress.isStageStoryCompleted(story.stage);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/stories', extra: story.stage),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7F6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFB39DDB)),
          ),
          child: Row(
            children: [
              Text(story.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stufen-Abenteuer ${story.stage}: ${story.title}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      done
                          ? '🌟 Im Lesepass abgestempelt! Tippe zum Nochmal-Lesen.'
                          : '📖 Kurze Geschichte mit Rätsel (+2 Bonus-Sterne)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF5E35B1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startDailyTraining(
    BuildContext context,
    List<LessonUnit> allUnits,
    ChildProgress progress,
  ) {
    final accessibleUnits = allUnits
        .where((u) => progress.isStageAccessible(u.stage, allUnits))
        .toList();
    if (accessibleUnits.isEmpty) return;

    // 1. Adaptive review: prioritize units where mistakes occurred
    final reviewIds = progress.unitsNeedingReview();
    for (final unitId in reviewIds) {
      final match = accessibleUnits.where((u) => u.id == unitId).toList();
      if (match.isNotEmpty) {
        final unit = match.first;
        for (final mod in ModuleType.values) {
          if (!progress.isModuleCompleted(unit.id, mod)) {
            _navigateToModule(context, unit, mod);
            return;
          }
        }
        _navigateToModule(context, unit, ModuleType.reading);
        return;
      }
    }

    // 2. Otherwise pick the next uncompleted module in recommended order
    final unlockedUnits = allUnits
        .where((u) => progress.isStageUnlocked(u.stage, allUnits))
        .toList();
    final targetPool =
        unlockedUnits.isNotEmpty ? unlockedUnits : accessibleUnits;

    for (final unit in targetPool) {
      for (final mod in ModuleType.values) {
        if (!progress.isModuleCompleted(unit.id, mod)) {
          _navigateToModule(context, unit, mod);
          return;
        }
      }
    }

    // All unlocked modules completed -> practice reading on the first unit
    _navigateToModule(context, targetPool.first, ModuleType.reading);
  }

  void _navigateToModule(
    BuildContext context,
    LessonUnit unit,
    ModuleType module,
  ) {
    final path = switch (module) {
      ModuleType.phonics => '/unit/${unit.id}/phonics',
      ModuleType.tracing => '/unit/${unit.id}/tracing',
      ModuleType.syllables => '/unit/${unit.id}/syllables',
      ModuleType.reading => '/unit/${unit.id}/reading',
    };
    context.push(path, extra: unit);
  }

  void _showStageLockedDialog(
    BuildContext context,
    WidgetRef ref,
    int stage,
    List<LessonUnit> allUnits,
    ChildProgress progress,
  ) {
    final prevStage = stage - 1;
    final stats = progress.stageProgress(prevStage, allUnits);
    final needed = (stats.max * 0.70).ceil();
    final msg =
        'Stufe $stage schaltet sich frei, sobald du in Stufe $prevStage mindestens $needed von ${stats.max} Sternen gesammelt hast (aktuell: ${stats.earned} ⭐).';
    ref.read(audioServiceProvider).speakWord(msg);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('🔒 Stufe $stage noch gesperrt'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final allowed = await ParentalGateDialog.show(context);
              if (allowed && context.mounted) {
                await ref
                    .read(progressProvider.notifier)
                    .toggleStageOverride(stage);
              }
            },
            child: const Text('Eltern-Freischaltung'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Alles klar!'),
          ),
        ],
      ),
    );
  }

  void _showOnboardingTourDialog(BuildContext context, WidgetRef ref) {
    int step = 0;
    const steps = [
      (
        emoji: '🦊🦉',
        title: 'Hallo bei Fips & Fina!',
        text:
            'Ich bin Fips der Fuchs und das ist Eule Fina! Gemeinsam entdecken wir Buchstaben, Silben und Geschichten.',
      ),
      (
        emoji: '👑🔵🔴',
        title: 'Das Silben-Geheimnis',
        text:
            'Jede Silbe schwingt in Blau und Rot! Und auf jedem Silbenkönig (A, E, I, O, U) funkelt eine kleine Krone.',
      ),
      (
        emoji: '⭐🚀',
        title: 'Sterne & Sticker sammeln',
        text:
            'Für das Hören, Schreiben, Schwingen und Lesen bekommst du goldene Sterne für dein großes Sticker-Album!',
      ),
    ];

    ref.read(audioServiceProvider).speakWord(steps.first.text);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final current = steps[step];
            return AlertDialog(
              title: Row(
                children: [
                  Text(current.emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      current.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    current.text,
                    style: const TextStyle(fontSize: 17),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(audioServiceProvider).speakWord(current.text),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Vorlesen'),
                  ),
                ],
              ),
              actions: [
                if (step > 0)
                  TextButton(
                    onPressed: () {
                      setDialogState(() => step--);
                      ref
                          .read(audioServiceProvider)
                          .speakWord(steps[step].text);
                    },
                    child: const Text('Zurück'),
                  ),
                ElevatedButton(
                  onPressed: () {
                    if (step + 1 < steps.length) {
                      setDialogState(() => step++);
                      ref
                          .read(audioServiceProvider)
                          .speakWord(steps[step].text);
                    } else {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(
                    step + 1 < steps.length ? 'Weiter' : 'Los geht’s! 🎉',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openProfileSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final progress = sheetRef.watch(progressProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Wer lernt gerade?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...progress.profiles.map((prof) {
                      final active = prof.id == progress.activeProfileId;
                      return ListTile(
                        leading: Text(
                          prof.avatarEmoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                        title: Text(
                          prof.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle:
                            Text('${prof.totalStars} ⭐ • ${prof.streakDays} 🔥'),
                        trailing: active
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.successGreen,
                              )
                            : null,
                        onTap: () async {
                          await sheetRef
                              .read(progressProvider.notifier)
                              .switchProfile(prof.id);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                      );
                    }),
                    const Divider(),
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final allowed = await ParentalGateDialog.show(context);
                        if (allowed && context.mounted) {
                          context.push('/parents');
                        }
                      },
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: const Text('Eltern- & Lehrkräftebereich'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openUnitSheet(
    BuildContext context,
    WidgetRef ref,
    LessonUnit unit, {
    bool showRecommendationHint = false,
  }) {
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
                if (showRecommendationHint) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.starGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '💡 Tipp: Stufe ${unit.stage - 1} hat noch offene Sterne – du kannst hier aber schon frei üben!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
                  subtitle: 'Groß, Klein & Frei im Linienhaus',
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
                  subtitle: 'Silbenbögen, Teppich & Klatschen',
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
                  subtitle: 'Silben-Puzzle, Sätze, Rätsel & Blitzlesen',
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
