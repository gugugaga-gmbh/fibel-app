import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/curriculum/curriculum_repository.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/stage_certificate_dialog.dart';
import '../home/profile_selector_dialog.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  static const _avatars = [
    '🦊',
    '🦉',
    '🦁',
    '🐼',
    '🦄',
    '🐸',
    '🐯',
    '🐨',
    '🐰',
    '🐻',
    '🐬',
    '🦋',
    '🦖',
    '🐝',
    '🐧',
    '🐢',
  ];

  static const _profileColors = [
    ('#1E88E5', 'Blau'),
    ('#E53935', 'Rot'),
    ('#00897B', 'Türkis'),
    ('#FB8C00', 'Orange'),
    ('#7E57C2', 'Lila'),
    ('#43A047', 'Grün'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final curriculumAsync = ref.watch(curriculumProvider);
    final active = progress.activeProfile;
    final settings = progress.settings;
    final loc = AppLocalizations.of(settings.appLanguage);

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
                        final accent = ProfileSelectorSheet.parseProfileColor(
                          prof.themeColorHex,
                        );
                        final bridge = prof.profileBridgeLanguage ??
                            settings.bridgeLanguage;
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected
                                  ? accent
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: accent.withValues(alpha: 0.08),
                          leading: CircleAvatar(
                            backgroundColor: accent.withValues(alpha: 0.18),
                            child: Text(
                              prof.avatarEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  prof.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (prof.hasEmojiPin) ...[
                                const SizedBox(width: 6),
                                const Text(
                                  '🔑',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                              if (bridge.isEnabled) ...[
                                const SizedBox(width: 6),
                                Text(
                                  bridge.flagEmoji,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${prof.totalStars} ⭐ (davon ${prof.bonusStars} Bonus) • Serie: ${prof.streakDays} 🔥'
                            '${prof.groupName.trim().isNotEmpty ? ' • 🏫 ${prof.groupName}' : ''}',
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
                      if (progress.profiles.length > 1) ...[
                        const Divider(height: 24),
                        Text(
                          loc.tr('class_comparison'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...progress.profiles.map((prof) {
                          final childView = ChildProgress(
                            activeProfileId: prof.id,
                            profiles: [prof],
                            settings: settings,
                          );
                          final stageSummary = curriculum.stages.map((st) {
                            final pct = (childView
                                        .stageProgress(st, curriculum.units)
                                        .ratio *
                                    100)
                                .round();
                            return 'S$st: $pct%';
                          }).join(' • ');
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Text(prof.avatarEmoji),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    prof.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  stageSummary,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Sprache & DaZ-Wort-Brücke (Mehrsprachigkeit)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🌍', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.tr('language_and_daz'),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        loc.tr('parent_language_label'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppLanguage.values.map((lang) {
                          final selected = settings.appLanguage == lang;
                          return ChoiceChip(
                            label: Text('${lang.flagEmoji} ${lang.nativeName}'),
                            selected: selected,
                            onSelected: (_) {
                              ref
                                  .read(progressProvider.notifier)
                                  .updateSettings(
                                    settings.copyWith(appLanguage: lang),
                                  );
                            },
                          );
                        }).toList(),
                      ),
                      const Divider(height: 22),
                      Text(
                        '${loc.tr('bridge_language_label')} (${active.name})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.tr('bridge_language_hint'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: BridgeLanguage.values.map((bLang) {
                          final currentBridge = progress.effectiveBridgeLanguage;
                          final selected = currentBridge == bLang;
                          return ChoiceChip(
                            label:
                                Text('${bLang.flagEmoji} ${bLang.nativeName}'),
                            selected: selected,
                            onSelected: (_) {
                              ref
                                  .read(progressProvider.notifier)
                                  .updateActiveProfile(
                                    profileBridgeLanguage: bLang,
                                  );
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Kompetenz-Auswertung & Förderempfehlungen
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
                        label: '5. Lesepass-Geschichten (Stufen 1–5)',
                        done: progress.completedStageStories.length,
                        total: curriculum.stageStories.isEmpty
                            ? 5
                            : curriculum.stageStories.length,
                        color: const Color(0xFF7E57C2),
                      ),
                      const Divider(height: 24),
                      Builder(
                        builder: (context) {
                          final boxes = progress.masteryBoxCounts;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${loc.tr('report_leitner')} & Abenteuer-Runden',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Chip(
                                    label: Text('🌱 Üben: ${boxes.box1}'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Chip(
                                    label: Text('🌿 Gefestigt: ${boxes.box2}'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Chip(
                                    label: Text('🌳 Sicher: ${boxes.box3}'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Chip(
                                    label: Text(
                                      '🧭 Abenteuer: ${active.completedDailyMissions}',
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 24),
                      Text(
                        loc.tr('weekly_activity'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildWeeklyActivityBar(active),
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

              // 4. Stufen-Fortschritt & Lehrkraft-Freischaltung (70%-Regel)
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
                      for (final stage in curriculum.stages)
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

              // 5. Didaktik-, Kinderschutz- & Audio-Einstellungen
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
                      Row(
                        children: [
                          const Text('🌙 ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              loc.tr('screen_time_title'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Heute aktiv: ${(progress.activeSecondsForToday() / 60).ceil()} Min.'
                        '${settings.dailyScreenTimeLimitMinutes > 0 ? ' (Limit: ${progress.effectiveScreenTimeLimitMinutes()} Min.)' : ' (Kein Zeitlimit)'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Aus')),
                          ButtonSegment(value: 10, label: Text('10m')),
                          ButtonSegment(value: 15, label: Text('15m')),
                          ButtonSegment(value: 20, label: Text('20m')),
                          ButtonSegment(value: 30, label: Text('30m')),
                        ],
                        selected: {
                          const {0, 10, 15, 20, 30}.contains(
                            settings.dailyScreenTimeLimitMinutes,
                          )
                              ? settings.dailyScreenTimeLimitMinutes
                              : 0,
                        },
                        onSelectionChanged: (sel) {
                          ref
                              .read(progressProvider.notifier)
                              .updateScreenTimeLimitMinutes(sel.first);
                        },
                      ),
                      if (settings.dailyScreenTimeLimitMinutes > 0) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => ref
                              .read(progressProvider.notifier)
                              .grantExtraScreenTimeMinutes(5),
                          icon: const Icon(Icons.more_time_rounded, size: 18),
                          label: const Text('+5 Min. für heute schenken'),
                        ),
                      ],
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
                        selected: {progress.effectiveSettings.speechSpeed},
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
                        value: progress.effectiveSettings.leftHandedMode,
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

              // 6. Offline-Sicherung & Zurücksetzen
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
                            icon:
                                const Icon(Icons.assignment_turned_in_rounded),
                            label:
                                const Text('Lernbericht & Urkunde erstellen'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showExportDialog(context, ref, singleOnly: false),
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Offline-Backup exportieren'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showExportDialog(context, ref, singleOnly: true),
                            icon: const Icon(Icons.person_pin_rounded),
                            label: Text(loc.tr('export_single_profile')),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showImportDialog(context, ref, mergeOnly: false),
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Offline-Backup importieren'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showImportDialog(context, ref, mergeOnly: true),
                            icon: const Icon(Icons.group_add_rounded),
                            label: Text(loc.tr('import_merge_profile')),
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

  Widget _buildWeeklyActivityBar(ChildProfile profile) {
    final now = DateTime.now();
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final days = List.generate(7, (idx) {
      final d = now.subtract(Duration(days: 6 - idx));
      final iso = '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      final count = profile.activityHistoryByDate[iso] ??
          (profile.lastActiveDate == iso ? profile.dailyCompletedCount : 0);
      final dayLabel = weekdays[(d.weekday - 1).clamp(0, 6)];
      return (label: dayLabel, count: count);
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((entry) {
        final active = entry.count > 0;
        return Column(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.successGreen.withValues(alpha: 0.18)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: active
                      ? AppColors.successGreen
                      : const Color(0xFFD1D5DB),
                ),
              ),
              child: Text(
                active ? '${entry.count}' : '–',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: active
                      ? AppColors.successGreen
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _buildDiagnosticRecommendation(
    ChildProgress progress,
    List<String> reviewLetters,
  ) {
    if (reviewLetters.isNotEmpty) {
      return '🔁 Gezieltes Wiederholen empfohlen bei: ${reviewLetters.join(', ')}. '
          'Die geführte „Abenteuer-Runde“ auf dem Startbildschirm wählt diese Laute per Spaced Repetition automatisch bevorzugt aus.';
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

  void _showExportDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool singleOnly,
  }) {
    final notifier = ref.read(progressProvider.notifier);
    final jsonStr = singleOnly
        ? notifier.exportActiveProfileJson()
        : notifier.exportProgressJson();
    Clipboard.setData(ClipboardData(text: jsonStr));

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          singleOnly
              ? 'Einzel-Profil exportiert (JSON)'
              : 'Offline-Backup (JSON)',
        ),
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

  void _showImportDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool mergeOnly,
  }) {
    final controller = TextEditingController();
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                mergeOnly
                    ? 'Profil hinzufügen (Merge-Import)'
                    : 'Offline-Backup importieren',
              ),
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
                    final notifier = ref.read(progressProvider.notifier);
                    final raw = controller.text.trim();
                    final ok = mergeOnly
                        ? await notifier.importAndMergeProfileJson(raw)
                        : await notifier.importProgressJson(raw);
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
    AppLanguage selectedLang = progress.settings.appLanguage;
    String report =
        progress.generateParentReport(curriculum, language: selectedLang);
    Clipboard.setData(ClipboardData(text: report));

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Lernbericht & Lese-Pass'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Der Bericht wurde in die Zwischenablage kopiert (Sprache wählbar für mehrsprachige Elterngespräche):',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: AppLanguage.values.map((lang) {
                        return ChoiceChip(
                          label: Text('${lang.flagEmoji} ${lang.code.toUpperCase()}'),
                          selected: selectedLang == lang,
                          onSelected: (_) {
                            setDialogState(() {
                              selectedLang = lang;
                              report = progress.generateParentReport(
                                curriculum,
                                language: selectedLang,
                              );
                            });
                            Clipboard.setData(ClipboardData(text: report));
                          },
                        );
                      }).toList(),
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
                          textDirection: selectedLang.isRtl
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Stufen-Urkunden direkt öffnen:',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: curriculum.stages.map((stage) {
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
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Fertig'),
                ),
              ],
            );
          },
        );
      },
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
    final nameController = TextEditingController(text: existing?.name ?? '');
    final groupController =
        TextEditingController(text: existing?.groupName ?? '');
    String chosenAvatar = existing?.avatarEmoji ?? _avatars.first;
    String chosenColorHex =
        existing?.themeColorHex ?? _profileColors.first.$1;
    BridgeLanguage chosenBridge =
        existing?.profileBridgeLanguage ?? BridgeLanguage.none;
    bool? chosenLeftHanded = existing?.profileLeftHandedMode;
    final pinEmojis = <String>[];
    if (existing != null && existing.emojiPin.isNotEmpty) {
      pinEmojis.addAll(
        existing.emojiPin.runes.map((r) => String.fromCharCode(r)),
      );
    }

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Neues Kinder-Profil' : 'Profil bearbeiten',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name des Kindes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: groupController,
                      decoration: const InputDecoration(
                        labelText: 'Gruppe / Klasse (optional, z. B. Klasse 1a)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Avatar wählen:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _avatars.map((emoji) {
                        final selected = emoji == chosenAvatar;
                        return ChoiceChip(
                          label: Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              setDialogState(() => chosenAvatar = emoji),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Lieblingsfarbe:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _profileColors.map((pair) {
                        final hex = pair.$1;
                        final label = pair.$2;
                        final selected = chosenColorHex == hex;
                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) =>
                              setDialogState(() => chosenColorHex = hex),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'DaZ-Wort-Brücke (Herkunftssprache):',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: BridgeLanguage.values.map((bLang) {
                        final selected = chosenBridge == bLang;
                        return ChoiceChip(
                          label:
                              Text('${bLang.flagEmoji} ${bLang.nativeName}'),
                          selected: selected,
                          onSelected: (_) =>
                              setDialogState(() => chosenBridge = bLang),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Linkshänder-Modus für dieses Kind'),
                      value: chosenLeftHanded ?? false,
                      onChanged: (v) =>
                          setDialogState(() => chosenLeftHanded = v),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Optionaler 2-Emoji-Schlüssel (Schul-Tablet):',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (pinEmojis.isNotEmpty)
                          TextButton(
                            onPressed: () =>
                                setDialogState(() => pinEmojis.clear()),
                            child: const Text('Löschen'),
                          ),
                      ],
                    ),
                    Text(
                      pinEmojis.isEmpty
                          ? 'Kein Schlüssel aktiv (direkter Wechsel)'
                          : 'Gewählt: ${pinEmojis.join(' ')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ProfileSelectorSheet.emojiPinChoices.map((em) {
                        return ActionChip(
                          label: Text(em, style: const TextStyle(fontSize: 18)),
                          onPressed: () {
                            setDialogState(() {
                              if (pinEmojis.length >= 2) {
                                pinEmojis.clear();
                              }
                              pinEmojis.add(em);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final pinStr =
                        pinEmojis.length == 2 ? pinEmojis.join() : '';
                    if (existing == null) {
                      await ref.read(progressProvider.notifier).addProfile(
                            name: name,
                            avatarEmoji: chosenAvatar,
                            themeColorHex: chosenColorHex,
                            groupName: groupController.text.trim(),
                            emojiPin: pinStr,
                            profileBridgeLanguage: chosenBridge,
                            profileLeftHandedMode: chosenLeftHanded,
                          );
                    } else {
                      await ref
                          .read(progressProvider.notifier)
                          .updateActiveProfile(
                            name: name,
                            avatarEmoji: chosenAvatar,
                            themeColorHex: chosenColorHex,
                            groupName: groupController.text.trim(),
                            emojiPin: pinStr,
                            profileBridgeLanguage: chosenBridge,
                            profileLeftHandedMode: chosenLeftHanded,
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
