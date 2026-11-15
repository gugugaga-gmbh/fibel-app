import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../curriculum/curriculum_models.dart';

enum ModuleType { phonics, tracing, syllables, reading }

enum SpeechSpeed { slow, normal, fast }

class AppSettings {
  final SpeechSpeed speechSpeed;
  final bool soundEnabled;
  final bool showSyllableArcs;
  final bool showVowelCrowns;

  const AppSettings({
    this.speechSpeed = SpeechSpeed.normal,
    this.soundEnabled = true,
    this.showSyllableArcs = true,
    this.showVowelCrowns = true,
  });

  double get wordRate => switch (speechSpeed) {
        SpeechSpeed.slow => 0.34,
        SpeechSpeed.normal => 0.42,
        SpeechSpeed.fast => 0.50,
      };

  AppSettings copyWith({
    SpeechSpeed? speechSpeed,
    bool? soundEnabled,
    bool? showSyllableArcs,
    bool? showVowelCrowns,
  }) {
    return AppSettings(
      speechSpeed: speechSpeed ?? this.speechSpeed,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      showSyllableArcs: showSyllableArcs ?? this.showSyllableArcs,
      showVowelCrowns: showVowelCrowns ?? this.showVowelCrowns,
    );
  }

  Map<String, dynamic> toJson() => {
        'speechSpeed': speechSpeed.name,
        'soundEnabled': soundEnabled,
        'showSyllableArcs': showSyllableArcs,
        'showVowelCrowns': showVowelCrowns,
      };

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppSettings();
    final speedStr = json['speechSpeed'] as String?;
    final speed = SpeechSpeed.values.firstWhere(
      (e) => e.name == speedStr,
      orElse: () => SpeechSpeed.normal,
    );
    return AppSettings(
      speechSpeed: speed,
      soundEnabled: (json['soundEnabled'] as bool?) ?? true,
      showSyllableArcs: (json['showSyllableArcs'] as bool?) ?? true,
      showVowelCrowns: (json['showVowelCrowns'] as bool?) ?? true,
    );
  }
}

class ChildProfile {
  final String id;
  final String name;
  final String avatarEmoji;
  final int totalStars;
  final int bonusStars;
  final Map<String, Set<String>> completedModulesByUnit;
  final Map<String, Set<String>> tracingStepsByUnit;
  final Set<String> completedBonuses;
  final Set<int> unlockedStagesOverride;
  final int dailyGoalTarget;
  final int dailyCompletedCount;
  final String lastActiveDate;
  final int streakDays;
  final bool dailyGoalRewardedToday;

  const ChildProfile({
    required this.id,
    this.name = 'Lese-Entdecker',
    this.avatarEmoji = '🦊',
    this.totalStars = 0,
    this.bonusStars = 0,
    this.completedModulesByUnit = const {},
    this.tracingStepsByUnit = const {},
    this.completedBonuses = const {},
    this.unlockedStagesOverride = const {},
    this.dailyGoalTarget = 3,
    this.dailyCompletedCount = 0,
    this.lastActiveDate = '',
    this.streakDays = 0,
    this.dailyGoalRewardedToday = false,
  });

  ChildProfile copyWith({
    String? id,
    String? name,
    String? avatarEmoji,
    int? totalStars,
    int? bonusStars,
    Map<String, Set<String>>? completedModulesByUnit,
    Map<String, Set<String>>? tracingStepsByUnit,
    Set<String>? completedBonuses,
    Set<int>? unlockedStagesOverride,
    int? dailyGoalTarget,
    int? dailyCompletedCount,
    String? lastActiveDate,
    int? streakDays,
    bool? dailyGoalRewardedToday,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      totalStars: totalStars ?? this.totalStars,
      bonusStars: bonusStars ?? this.bonusStars,
      completedModulesByUnit:
          completedModulesByUnit ?? this.completedModulesByUnit,
      tracingStepsByUnit: tracingStepsByUnit ?? this.tracingStepsByUnit,
      completedBonuses: completedBonuses ?? this.completedBonuses,
      unlockedStagesOverride:
          unlockedStagesOverride ?? this.unlockedStagesOverride,
      dailyGoalTarget: dailyGoalTarget ?? this.dailyGoalTarget,
      dailyCompletedCount: dailyCompletedCount ?? this.dailyCompletedCount,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      streakDays: streakDays ?? this.streakDays,
      dailyGoalRewardedToday:
          dailyGoalRewardedToday ?? this.dailyGoalRewardedToday,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarEmoji': avatarEmoji,
      'totalStars': totalStars,
      'bonusStars': bonusStars,
      'completedModulesByUnit': completedModulesByUnit.map(
        (key, value) => MapEntry(key, value.toList()),
      ),
      'tracingStepsByUnit': tracingStepsByUnit.map(
        (key, value) => MapEntry(key, value.toList()),
      ),
      'completedBonuses': completedBonuses.toList(),
      'unlockedStagesOverride': unlockedStagesOverride.toList(),
      'dailyGoalTarget': dailyGoalTarget,
      'dailyCompletedCount': dailyCompletedCount,
      'lastActiveDate': lastActiveDate,
      'streakDays': streakDays,
      'dailyGoalRewardedToday': dailyGoalRewardedToday,
    };
  }

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    Map<String, Set<String>> parseSetMap(String field) {
      final raw = (json[field] as Map<String, dynamic>?) ?? {};
      return raw.map(
        (k, v) => MapEntry(k, (v as List<dynamic>).cast<String>().toSet()),
      );
    }

    return ChildProfile(
      id: (json['id'] as String?) ?? 'default',
      name: (json['name'] as String?) ??
          (json['childName'] as String?) ??
          'Lese-Entdecker',
      avatarEmoji: (json['avatarEmoji'] as String?) ?? '🦊',
      totalStars: (json['totalStars'] as num?)?.toInt() ?? 0,
      bonusStars: (json['bonusStars'] as num?)?.toInt() ?? 0,
      completedModulesByUnit: parseSetMap('completedModulesByUnit'),
      tracingStepsByUnit: parseSetMap('tracingStepsByUnit'),
      completedBonuses: ((json['completedBonuses'] as List<dynamic>?) ?? [])
          .cast<String>()
          .toSet(),
      unlockedStagesOverride:
          ((json['unlockedStagesOverride'] as List<dynamic>?) ?? [])
              .map((e) => (e as num).toInt())
              .toSet(),
      dailyGoalTarget: (json['dailyGoalTarget'] as num?)?.toInt() ?? 3,
      dailyCompletedCount: (json['dailyCompletedCount'] as num?)?.toInt() ?? 0,
      lastActiveDate: (json['lastActiveDate'] as String?) ?? '',
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      dailyGoalRewardedToday: (json['dailyGoalRewardedToday'] as bool?) ?? false,
    );
  }
}

class ChildProgress {
  final String activeProfileId;
  final List<ChildProfile> profiles;
  final AppSettings settings;

  const ChildProgress({
    this.activeProfileId = 'default',
    this.profiles = const [ChildProfile(id: 'default')],
    this.settings = const AppSettings(),
  });

  /// Backward-compatible convenience constructor for single-profile tests/callers.
  factory ChildProgress.single({
    String childName = 'Lese-Entdecker',
    String avatarEmoji = '🦊',
    int totalStars = 0,
    Map<String, Set<String>> completedModulesByUnit = const {},
  }) {
    return ChildProgress(
      activeProfileId: 'default',
      profiles: [
        ChildProfile(
          id: 'default',
          name: childName,
          avatarEmoji: avatarEmoji,
          totalStars: totalStars,
          completedModulesByUnit: completedModulesByUnit,
        ),
      ],
    );
  }

  ChildProfile get activeProfile {
    if (profiles.isEmpty) {
      return const ChildProfile(id: 'default');
    }
    return profiles.firstWhere(
      (p) => p.id == activeProfileId,
      orElse: () => profiles.first,
    );
  }

  String get childName => activeProfile.name;
  String get avatarEmoji => activeProfile.avatarEmoji;
  int get totalStars => activeProfile.totalStars;
  int get bonusStars => activeProfile.bonusStars;
  Map<String, Set<String>> get completedModulesByUnit =>
      activeProfile.completedModulesByUnit;
  Map<String, Set<String>> get tracingStepsByUnit =>
      activeProfile.tracingStepsByUnit;
  Set<String> get completedBonuses => activeProfile.completedBonuses;
  Set<int> get unlockedStagesOverride => activeProfile.unlockedStagesOverride;
  int get dailyGoalTarget => activeProfile.dailyGoalTarget;
  int get dailyCompletedCount => activeProfile.dailyCompletedCount;
  int get streakDays => activeProfile.streakDays;

  bool isModuleCompleted(String unitId, ModuleType module) {
    return completedModulesByUnit[unitId]?.contains(module.name) ?? false;
  }

  bool isTracingStepCompleted(String unitId, String step) {
    if (isModuleCompleted(unitId, ModuleType.tracing)) return true;
    return tracingStepsByUnit[unitId]?.contains(step) ?? false;
  }

  bool isBonusCompleted(String bonusKey) {
    return completedBonuses.contains(bonusKey);
  }

  int completedCountForUnit(String unitId) {
    return completedModulesByUnit[unitId]?.length ?? 0;
  }

  int completedCountForModuleType(ModuleType module) {
    int count = 0;
    for (final modules in completedModulesByUnit.values) {
      if (modules.contains(module.name)) count++;
    }
    return count;
  }

  /// Calculates (earnedCoreStars, maxCoreStars, ratio) for a given curriculum stage.
  ({int earned, int max, double ratio}) stageProgress(
    int stage,
    List<LessonUnit> allUnits,
  ) {
    final stageUnits = allUnits.where((u) => u.stage == stage).toList();
    if (stageUnits.isEmpty) {
      return (earned: 0, max: 0, ratio: 1.0);
    }
    final maxStars = stageUnits.length * 4;
    int earnedStars = 0;
    for (final u in stageUnits) {
      earnedStars += completedCountForUnit(u.id);
    }
    return (
      earned: earnedStars,
      max: maxStars,
      ratio: maxStars > 0 ? earnedStars / maxStars : 1.0,
    );
  }

  /// Strict 70% progression rule: Stage 1 is always unlocked.
  /// Stage n > 1 unlocks when Stage n-1 has >= 70% of core module stars
  /// OR when unlocked via teacher override in ParentDashboard.
  bool isStageUnlocked(int stage, List<LessonUnit> allUnits) {
    if (stage <= 1) return true;
    if (unlockedStagesOverride.contains(stage)) return true;
    final prev = stageProgress(stage - 1, allUnits);
    return prev.ratio >= 0.70;
  }

  ChildProgress copyWith({
    String? activeProfileId,
    List<ChildProfile>? profiles,
    AppSettings? settings,
    String? childName,
    int? totalStars,
    Map<String, Set<String>>? completedModulesByUnit,
  }) {
    var updatedProfiles = profiles ?? this.profiles;
    if (childName != null ||
        totalStars != null ||
        completedModulesByUnit != null) {
      final current = activeProfile;
      final modified = current.copyWith(
        name: childName ?? current.name,
        totalStars: totalStars ?? current.totalStars,
        completedModulesByUnit:
            completedModulesByUnit ?? current.completedModulesByUnit,
      );
      updatedProfiles = updatedProfiles
          .map((p) => p.id == current.id ? modified : p)
          .toList();
    }
    return ChildProgress(
      activeProfileId: activeProfileId ?? this.activeProfileId,
      profiles: updatedProfiles,
      settings: settings ?? this.settings,
    );
  }

  ChildProgress updateActive(ChildProfile Function(ChildProfile current) fn) {
    final current = activeProfile;
    final updated = fn(current);
    final nextProfiles =
        profiles.map((p) => p.id == current.id ? updated : p).toList();
    return copyWith(profiles: nextProfiles);
  }

  Map<String, dynamic> toJson() {
    return {
      'version': 2,
      'activeProfileId': activeProfileId,
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'settings': settings.toJson(),
      // Legacy top-level fields for backward compatibility
      'childName': childName,
      'totalStars': totalStars,
      'completedModulesByUnit': completedModulesByUnit.map(
        (key, value) => MapEntry(key, value.toList()),
      ),
    };
  }

  factory ChildProgress.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('profiles')) {
      final rawProfiles = (json['profiles'] as List<dynamic>?) ?? [];
      final parsedProfiles = rawProfiles
          .map((e) => ChildProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      final effectiveProfiles = parsedProfiles.isEmpty
          ? const [ChildProfile(id: 'default')]
          : parsedProfiles;
      return ChildProgress(
        activeProfileId:
            (json['activeProfileId'] as String?) ?? effectiveProfiles.first.id,
        profiles: effectiveProfiles,
        settings:
            AppSettings.fromJson(json['settings'] as Map<String, dynamic>?),
      );
    }

    // Migrate v1 format seamlessly
    final migratedProfile = ChildProfile.fromJson(json);
    return ChildProgress(
      activeProfileId: migratedProfile.id,
      profiles: [migratedProfile],
      settings: const AppSettings(),
    );
  }
}

class ProgressRepository {
  static const _storageKeyV1 = 'fibel_child_progress_v1';
  static const _storageKeyV2 = 'fibel_child_progress_v2';

  Future<ChildProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final rawV2 = prefs.getString(_storageKeyV2);
    if (rawV2 != null && rawV2.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawV2) as Map<String, dynamic>;
        return ChildProgress.fromJson(decoded);
      } catch (_) {}
    }

    // Fallback & migrate from v1 if present
    final rawV1 = prefs.getString(_storageKeyV1);
    if (rawV1 != null && rawV1.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawV1) as Map<String, dynamic>;
        final migrated = ChildProgress.fromJson(decoded);
        await saveProgress(migrated);
        return migrated;
      } catch (_) {}
    }

    return const ChildProgress();
  }

  Future<void> saveProgress(ChildProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(progress.toJson());
    await prefs.setString(_storageKeyV2, encoded);
    await prefs.setString(_storageKeyV1, encoded);
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKeyV2);
    await prefs.remove(_storageKeyV1);
  }
}

class ProgressNotifier extends StateNotifier<ChildProgress> {
  final ProgressRepository _repo;
  bool _mutated = false;

  ProgressNotifier(this._repo) : super(const ChildProgress()) {
    _init();
  }

  Future<void> _init() async {
    final loaded = await _repo.loadProgress();
    if (!_mutated && mounted) {
      state = loaded;
    }
  }

  static String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  ChildProfile _recordDailyActivity(ChildProfile profile) {
    final today = _todayIso();
    int streak = profile.streakDays;
    int dailyCount = profile.dailyCompletedCount;
    bool rewarded = profile.dailyGoalRewardedToday;

    if (profile.lastActiveDate != today) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayIso = '${yesterday.year.toString().padLeft(4, '0')}-'
          '${yesterday.month.toString().padLeft(2, '0')}-'
          '${yesterday.day.toString().padLeft(2, '0')}';
      if (profile.lastActiveDate == yesterdayIso) {
        streak += 1;
      } else {
        streak = 1;
      }
      dailyCount = 1;
      rewarded = false;
    } else {
      dailyCount += 1;
    }

    int extraBonus = 0;
    if (dailyCount >= profile.dailyGoalTarget && !rewarded) {
      rewarded = true;
      extraBonus = 2; // +2 Bonus-Sterne für das Erreichen des Tagesziels
    }

    return profile.copyWith(
      lastActiveDate: today,
      streakDays: streak,
      dailyCompletedCount: dailyCount,
      dailyGoalRewardedToday: rewarded,
      totalStars: profile.totalStars + extraBonus,
      bonusStars: profile.bonusStars + extraBonus,
    );
  }

  Future<void> updateChildName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _mutated = true;
    state = state.updateActive((p) => p.copyWith(name: trimmed));
    await _repo.saveProgress(state);
  }

  Future<void> updateActiveProfile({String? name, String? avatarEmoji}) async {
    _mutated = true;
    state = state.updateActive(
      (p) => p.copyWith(
        name: (name != null && name.trim().isNotEmpty) ? name.trim() : p.name,
        avatarEmoji: avatarEmoji ?? p.avatarEmoji,
      ),
    );
    await _repo.saveProgress(state);
  }

  Future<void> switchProfile(String profileId) async {
    if (state.profiles.any((p) => p.id == profileId)) {
      _mutated = true;
      state = state.copyWith(activeProfileId: profileId);
      await _repo.saveProgress(state);
    }
  }

  Future<void> addProfile({
    required String name,
    String avatarEmoji = '🦉',
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _mutated = true;
    final newId = 'child_${DateTime.now().millisecondsSinceEpoch}';
    final newProfile = ChildProfile(
      id: newId,
      name: trimmed,
      avatarEmoji: avatarEmoji,
    );
    state = state.copyWith(
      activeProfileId: newId,
      profiles: [...state.profiles, newProfile],
    );
    await _repo.saveProgress(state);
  }

  Future<void> deleteProfile(String profileId) async {
    if (state.profiles.length <= 1) return;
    _mutated = true;
    final remaining =
        state.profiles.where((p) => p.id != profileId).toList();
    final nextActive = state.activeProfileId == profileId
        ? remaining.first.id
        : state.activeProfileId;
    state = state.copyWith(
      activeProfileId: nextActive,
      profiles: remaining,
    );
    await _repo.saveProgress(state);
  }

  Future<void> completeModule(String unitId, ModuleType module) async {
    _mutated = true;
    state = state.updateActive((profile) {
      final currentMap = Map<String, Set<String>>.from(
        profile.completedModulesByUnit.map(
          (k, v) => MapEntry(k, Set<String>.from(v)),
        ),
      );
      final unitSet = currentMap.putIfAbsent(unitId, () => <String>{});
      final isNew = unitSet.add(module.name);
      var updated = profile.copyWith(
        totalStars: isNew ? profile.totalStars + 1 : profile.totalStars,
        completedModulesByUnit: currentMap,
      );
      if (isNew) {
        updated = _recordDailyActivity(updated);
      }
      return updated;
    });
    await _repo.saveProgress(state);
  }

  /// Records completion of a tracing sub-step ('upper', 'lower', 'freehand').
  /// Returns true when all 3 mandatory steps for the unit have been completed.
  Future<bool> recordTracingStep(String unitId, String step) async {
    _mutated = true;
    bool allThreeDone = false;
    state = state.updateActive((profile) {
      final currentSteps = Map<String, Set<String>>.from(
        profile.tracingStepsByUnit.map(
          (k, v) => MapEntry(k, Set<String>.from(v)),
        ),
      );
      final stepSet = currentSteps.putIfAbsent(unitId, () => <String>{});
      stepSet.add(step);
      allThreeDone = stepSet.contains('upper') &&
          stepSet.contains('lower') &&
          stepSet.contains('freehand');
      return profile.copyWith(tracingStepsByUnit: currentSteps);
    });
    if (allThreeDone) {
      await completeModule(unitId, ModuleType.tracing);
    } else {
      await _repo.saveProgress(state);
    }
    return allThreeDone;
  }

  /// Awards bonus star(s) for completing optional challenges (e.g. Silben-Klatschen,
  /// Satz-Rätsel, Anlaut-Werkstatt Wort-Rätsel). Returns true if newly awarded.
  Future<bool> awardBonusStar(String bonusKey, {int stars = 1}) async {
    _mutated = true;
    bool newlyAwarded = false;
    state = state.updateActive((profile) {
      if (profile.completedBonuses.contains(bonusKey)) {
        return profile;
      }
      newlyAwarded = true;
      final nextBonuses = Set<String>.from(profile.completedBonuses)
        ..add(bonusKey);
      var updated = profile.copyWith(
        totalStars: profile.totalStars + stars,
        bonusStars: profile.bonusStars + stars,
        completedBonuses: nextBonuses,
      );
      updated = _recordDailyActivity(updated);
      return updated;
    });
    if (newlyAwarded) {
      await _repo.saveProgress(state);
    }
    return newlyAwarded;
  }

  Future<void> toggleStageOverride(int stage) async {
    _mutated = true;
    state = state.updateActive((profile) {
      final next = Set<int>.from(profile.unlockedStagesOverride);
      if (next.contains(stage)) {
        next.remove(stage);
      } else {
        next.add(stage);
      }
      return profile.copyWith(unlockedStagesOverride: next);
    });
    await _repo.saveProgress(state);
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _mutated = true;
    state = state.copyWith(settings: newSettings);
    await _repo.saveProgress(state);
  }

  Future<void> resetActiveProfileProgress() async {
    _mutated = true;
    state = state.updateActive(
      (p) => ChildProfile(
        id: p.id,
        name: p.name,
        avatarEmoji: p.avatarEmoji,
      ),
    );
    await _repo.saveProgress(state);
  }

  Future<void> resetAll() async {
    await _repo.resetProgress();
    state = const ChildProgress();
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository();
});

final progressProvider =
    StateNotifierProvider<ProgressNotifier, ChildProgress>((ref) {
  final repo = ref.watch(progressRepositoryProvider);
  return ProgressNotifier(repo);
});
