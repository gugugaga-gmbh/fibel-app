import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/curriculum_repository.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/stage_certificate_dialog.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  static const _avatars = ['🦊', '🦉', '🦁', '🐼', '🦄', '🐸', '🐯', '🐨'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final curriculumAsync = ref.watch(curriculumProvider);
    final active = progress.activeProfile;
    final settings = progress.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eltern- & Lehrkräftebereich'),
      ),
      body: curriculumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (curriculum) {
          final totalUnits = curriculum.units.length;
          final reviewUnitIds = progress.unitsNeedingReview();
          final reviewLetters = reviewUnitIds
              .map(
                (id) => curriculum.units
                    .where((u) => u.id == id)
                    .map((u) => u.letter)
                    .firstOrNull,
              )
              .whereType<String>()
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Kinder-Profile verwalten
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kinder-Profile',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _showAddOrEditProfileDialog(context, ref),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text('Neues Profil'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...progress.profiles.map((prof) {
                        final isSelected = prof.id == progress.activeProfileId;
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          selected: isSelected,
                          selectedTileColor:
                              AppColors.syllableBlue.withValues(alpha: 0.08),
                          leading: Text(
                            prof.avatarEmoji,
                            style: const TextStyle(fontSize: 30),
                          ),
                          title: Text(
                            prof.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${prof.totalStars} ⭐ (davon ${prof.bonusStars} Bonus) • Serie: ${prof.streakDays} 🔥',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Profil bearbeiten',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () async {
                                  await ref
                                      .read(progressProvider.notifier)
                                      .switchProfile(prof.id);
                                  if (context.mounted) {
                                    _showAddOrEditProfileDialog(
                                      context,
                                      ref,
                                      existing: prof,
                                    );
                                  }
                                },
                              ),
                              if (progress.profiles.length > 1)
                                IconButton(
                                  tooltip: 'Profil löschen',
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.syllableRed,
                                  ),
                                  onPressed: () => ref
                                      .read(progressProvider.notifier)
                                      .deleteProfile(prof.id),
                                ),
                            ],
                          ),
                          onTap: () => ref
                              .read(progressProvider.notifier)
                              .switchProfile(prof.id),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Kompetenz-Auswertung & Förderempfehlungen
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lernstand: ${active.avatarEmoji} ${active.name}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CompetenceRow(
                        label: '1. Laute hören (Anlaut-Zug)',
                        done: progress
                            .completedCountForModuleType(ModuleType.phonics),
                        total: totalUnits,
                        color: AppColors.owlTeal,
                      ),
                      const SizedBox(height: 8),
                      _CompetenceRow(
                        label: '2. Schreiben (Groß, Klein & Frei)',
                        done: progress
                            .completedCountForModuleType(ModuleType.tracing),
                        total: totalUnits,
                        color: AppColors.syllableBlue,
                      ),
                      const SizedBox(height: 8),
                      _CompetenceRow(
                        label: '3. Silben schwingen & Teppich',
                        done: progress
                            .completedCountForModuleType(ModuleType.syllables),
                        total: totalUnits,
                        color: AppColors.syllableRed,
                      ),
                      const SizedBox(height: 8),
                      _CompetenceRow(
                        label: '4. Wörter & Sätze lesen',
                        done: progress
                            .completedCountForModuleType(ModuleType.reading),
                        total: totalUnits,
                        color: AppColors.foxOrange,
                      ),
                      const SizedBox(height: 8),
                      _CompetenceRow(
                        label: '5. Lesepass-Geschichten (Stufen 1–4)',
                        done: progress.completedStageStories.length,
                        total: curriculum.stageStories.isEmpty
                            ? 4
                            : curriculum.stageStories.length,
                        color: const Color(0xFF7E57C2),
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Pädagogische Förderempfehlung:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _buildDiagnosticRecommendation(
                          progress,
                          reviewLetters,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Stufen-Fortschritt & Lehrkraft-Freischaltung (70%-Regel)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lernstufen & Lehrkraft-Freischaltung',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Standardmäßig sind alle Stufen mit sanfter Empfehlung frei wählbar. Optional kann unten der strikte Stufen-Sperrmodus (70 %-Regel) aktiviert werden.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final stage in [1, 2, 3, 4])
                        _buildStageControlTile(
                          context: context,
                          ref: ref,
                          stage: stage,
                          progress: progress,
                          curriculum: curriculum,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Didaktik- & Audio-Einstellungen
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Didaktik- & Audio-Einstellungen',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tägliches Lernziel (Übungen pro Tag):',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 2, label: Text('2')),
                          ButtonSegment(value: 3, label: Text('3')),
                          ButtonSegment(value: 5, label: Text('5')),
                          ButtonSegment(value: 7, label: Text('7')),
                        ],
                        selected: {
                          const {2, 3, 5, 7}.contains(progress.dailyGoalTarget)
                              ? progress.dailyGoalTarget
                              : 3,
                        },
                        onSelectionChanged: (sel) {
                          ref
                              .read(progressProvider.notifier)
                              .updateDailyGoalTarget(sel.first);
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Vorlese-Geschwindigkeit:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<SpeechSpeed>(
                        segments: const [
                          ButtonSegment(
                            value: SpeechSpeed.slow,
                            label: Text('Langsam'),
                          ),
                          ButtonSegment(
                            value: SpeechSpeed.normal,
                            label: Text('Normal'),
                          ),
                          ButtonSegment(
                            value: SpeechSpeed.fast,
                            label: Text('Zügig'),
                          ),
                        ],
                        selected: {settings.speechSpeed},
                        onSelectionChanged: (sel) {
                          ref.read(progressProvider.notifier).updateSettings(
                                settings.copyWith(speechSpeed: sel.first),
                              );
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sprachausgabe aktiviert'),
                        value: settings.soundEnabled,
                        onChanged: (v) => ref
                            .read(progressProvider.notifier)
                            .updateSettings(settings.copyWith(soundEnabled: v)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Silbenbögen unter Wörtern anzeigen'),
                        value: settings.showSyllableArcs,
                        onChanged: (v) =>
                            ref.read(progressProvider.notifier).updateSettings(
                                  settings.copyWith(showSyllableArcs: v),
                                ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title:
                            const Text('Silbenkönig-Kronen (👑) hervorheben'),
                        value: settings.showVowelCrowns,
                        onChanged: (v) =>
                            ref.read(progressProvider.notifier).updateSettings(
                                  settings.copyWith(showVowelCrowns: v),
                                ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Strikter Stufen-Sperrmodus (70 %-Regel)',
                        ),
                        subtitle: const Text(
                          'Wenn aus: Sanfte Empfehlung, alle Buchstaben frei wählbar',
                        ),
                        value: settings.strictStageLock,
                        onChanged: (v) =>
                            ref.read(progressProvider.notifier).updateSettings(
                                  settings.copyWith(strictStageLock: v),
                                ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Linkshänder-Modus beim Nachspuren (🤚)',
                        ),
                        subtitle: const Text(
                          'Platziert Linienhaus-Hilfen & Vorlage rechts statt links',
                        ),
                        value: settings.leftHandedMode,
                        onChanged: (v) =>
                            ref.read(progressProvider.notifier).updateSettings(
                                  settings.copyWith(leftHandedMode: v),
                                ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Größere Leseschrift (+15 % Barrierefreiheit)',
                        ),
                        value: settings.largeTextMode,
                        onChanged: (v) =>
                            ref.read(progressProvider.notifier).updateSettings(
                                  settings.copyWith(largeTextMode: v),
                                ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Erhöhter Kontrast-Modus (Sehhilfe)',
                        ),
                        value: settings.highContrastMode,
                        onChanged: (v) =>
                            ref.read(progressProvider.notifier).updateSettings(
                                  settings.copyWith(highContrastMode: v),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Offline-Sicherung & Zurücksetzen
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datenverwaltung & Offline-Backup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showReportDialog(context, ref, curriculum),
                            icon: const Icon(Icons.assignment_turned_in_rounded),
                            label: const Text('Lernbericht & Urkunde erstellen'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showExportDialog(context, ref),
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Offline-Backup exportieren'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showImportDialog(context, ref),
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Offline-Backup importieren'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(progressProvider.notifier)
                                  .resetActiveProfileProgress();
                            },
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: Text(
                              'Fortschritt von ${active.name} zurücksetzen',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(progressProvider.notifier)
                                  .resetAll();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.syllableRed,
                            ),
                            icon: const Icon(Icons.delete_forever_rounded),
                            label: const Text('Fortschritt zurücksetzen'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _buildDiagnosticRecommendation(
    ChildProgress progress,
    List<String> reviewLetters,
  ) {
    if (reviewLetters.isNotEmpty) {
      return '🔁 Gezieltes Wiederholen empfohlen bei: ${reviewLetters.join(', ')}. '
          'Das „Tägliche Training“ auf dem Startbildschirm wählt diese Laute automatisch bevorzugt aus.';
    }

    final phonics = progress.completedCountForModuleType(ModuleType.phonics);
    final tracing = progress.completedCountForModuleType(ModuleType.tracing);
    final syllables =
        progress.completedCountForModuleType(ModuleType.syllables);
    final reading = progress.completedCountForModuleType(ModuleType.reading);

    if (phonics == 0 && tracing == 0 && syllables == 0 && reading == 0) {
      return '🌱 Start-Tipp: Beginnt gemeinsam in Stufe 1 mit den Dauerlauten M, A, O, I und L.';
    }
    if (tracing < phonics && tracing <= syllables) {
      return '✍️ Schreib-Tipp: Das Hören klappt schon prima! Als Nächstes lohnt sich das Nachspuren im Linienhaus (Groß, Klein & Frei).';
    }
    if (syllables <= reading) {
      return '👏 Silben-Tipp: Übt das Silben-Klatschen und den Silbenteppich, um das flüssige Lesen weiter zu stärken.';
    }
    return '🌟 Toller Lernfortschritt! Probiert als Nächstes ein Stufen-Abenteuer im Lesepass oder das Blitzlesen aus.';
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    final jsonStr = ref.read(progressProvider.notifier).exportProgressJson();
    Clipboard.setData(ClipboardData(text: jsonStr));

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Offline-Backup (JSON)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Der Lernstand wurde in die Zwischenablage kopiert und kann lokal gesichert werden:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonStr,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Offline-Backup importieren'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'JSON-Backup hier einfügen',
                      errorText: errorText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(progressProvider.notifier)
                        .importProgressJson(controller.text.trim());
                    if (ok) {
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    } else {
                      setDialogState(() {
                        errorText = 'Ungültiges JSON-Format.';
                      });
                    }
                  },
                  child: const Text('Importieren'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReportDialog(
    BuildContext context,
    WidgetRef ref,
    CurriculumData curriculum,
  ) {
    final progress = ref.read(progressProvider);
    final report = progress.generateParentReport(curriculum);
    Clipboard.setData(ClipboardData(text: report));

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lernbericht & Lese-Pass'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Der Bericht wurde in die Zwischenablage kopiert (ideal zum Ausdrucken oder für Elterngespräche):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  report,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Stufen-Urkunden direkt öffnen:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [1, 2, 3, 4].map((stage) {
                return OutlinedButton.icon(
                  onPressed: () {
                    StageCertificateDialog.show(
                      ctx,
                      stage: stage,
                      story: curriculum.storyForStage(stage),
                      progress: progress,
                      allUnits: curriculum.units,
                    );
                  },
                  icon: const Text('🏆'),
                  label: Text('Stufe $stage'),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  Widget _buildStageControlTile({
    required BuildContext context,
    required WidgetRef ref,
    required int stage,
    required ChildProgress progress,
    required CurriculumData curriculum,
  }) {
    final allUnits = curriculum.units;
    final stats = progress.stageProgress(stage, allUnits);
    final unlocked = progress.isStageUnlocked(stage, allUnits);
    final manualOverride = progress.unlockedStagesOverride.contains(stage);
    final certEarned = progress.isStageCertificateEarned(stage, allUnits);
    final pct = (stats.ratio * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: unlocked ? AppColors.successGreen : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stufe $stage (${stats.earned}/${stats.max} ⭐ • $pct %)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                LinearProgressIndicator(
                  value: stats.ratio,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Urkunde Stufe $stage ansehen',
            icon: Icon(
              Icons.emoji_events_rounded,
              color: certEarned ? AppColors.starGold : const Color(0xFF9CA3AF),
            ),
            onPressed: () {
              StageCertificateDialog.show(
                context,
                stage: stage,
                story: curriculum.storyForStage(stage),
                progress: progress,
                allUnits: allUnits,
              );
            },
          ),
          if (stage > 1) ...[
            const SizedBox(width: 4),
            FilterChip(
              label: Text(manualOverride ? 'Manuell frei' : 'Freischalten'),
              selected: manualOverride,
              onSelected: (_) => ref
                  .read(progressProvider.notifier)
                  .toggleStageOverride(stage),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddOrEditProfileDialog(
    BuildContext context,
    WidgetRef ref, {
    ChildProfile? existing,
  }) {
    final controller = TextEditingController(text: existing?.name ?? '');
    String chosenAvatar = existing?.avatarEmoji ?? _avatars.first;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Neues Kinder-Profil' : 'Profil bearbeiten',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Name des Kindes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _avatars.map((emoji) {
                      final selected = emoji == chosenAvatar;
                      return ChoiceChip(
                        label:
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                        selected: selected,
                        onSelected: (_) =>
                            setDialogState(() => chosenAvatar = emoji),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    if (existing == null) {
                      await ref.read(progressProvider.notifier).addProfile(
                            name: name,
                            avatarEmoji: chosenAvatar,
                          );
                    } else {
                      await ref
                          .read(progressProvider.notifier)
                          .updateActiveProfile(
                            name: name,
                            avatarEmoji: chosenAvatar,
                          );
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CompetenceRow extends StatelessWidget {
  final String label;
  final int done;
  final int total;
  final Color color;

  const _CompetenceRow({
    required this.label,
    required this.done,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '$done / $total',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratio,
          color: color,
          backgroundColor: color.withValues(alpha: 0.14),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
