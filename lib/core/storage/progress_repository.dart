import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../curriculum/curriculum_models.dart';
import '../i18n/app_localizations.dart';

enum ModuleType { phonics, tracing, syllables, reading }

enum SpeechSpeed { slow, normal, fast }

class AppSettings {
  final SpeechSpeed speechSpeed;
  final bool soundEnabled;
  final bool showSyllableArcs;
  final bool showVowelCrowns;
  final bool strictStageLock;
  final bool leftHandedMode;
  final bool highContrastMode;
  final bool largeTextMode;
  final AppLanguage appLanguage;
  final BridgeLanguage bridgeLanguage;
  final int dailyScreenTimeLimitMinutes;

  const AppSettings({
    this.speechSpeed = SpeechSpeed.normal,
    this.soundEnabled = true,
    this.showSyllableArcs = true,
    this.showVowelCrowns = true,
    this.strictStageLock = false,
    this.leftHandedMode = false,
    this.highContrastMode = false,
    this.largeTextMode = false,
    this.appLanguage = AppLanguage.de,
    this.bridgeLanguage = BridgeLanguage.none,
    this.dailyScreenTimeLimitMinutes = 0,
  });

  double get wordRate => switch (speechSpeed) {
        SpeechSpeed.slow => 0.34,
        SpeechSpeed.normal => 0.42,
        SpeechSpeed.fast => 0.50,
      };

  double get textScaleFactor => largeTextMode ? 1.15 : 1.0;

  AppSettings copyWith({
    SpeechSpeed? speechSpeed,
    bool? soundEnabled,
    bool? showSyllableArcs,
    bool? showVowelCrowns,
    bool? strictStageLock,
    bool? leftHandedMode,
    bool? highContrastMode,
    bool? largeTextMode,
    AppLanguage? appLanguage,
    BridgeLanguage? bridgeLanguage,
    int? dailyScreenTimeLimitMinutes,
  }) {
    return AppSettings(
      speechSpeed: speechSpeed ?? this.speechSpeed,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      showSyllableArcs: showSyllableArcs ?? this.showSyllableArcs,
      showVowelCrowns: showVowelCrowns ?? this.showVowelCrowns,
      strictStageLock: strictStageLock ?? this.strictStageLock,
      leftHandedMode: leftHandedMode ?? this.leftHandedMode,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      largeTextMode: largeTextMode ?? this.largeTextMode,
      appLanguage: appLanguage ?? this.appLanguage,
      bridgeLanguage: bridgeLanguage ?? this.bridgeLanguage,
      dailyScreenTimeLimitMinutes:
          dailyScreenTimeLimitMinutes ?? this.dailyScreenTimeLimitMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'speechSpeed': speechSpeed.name,
        'soundEnabled': soundEnabled,
        'showSyllableArcs': showSyllableArcs,
        'showVowelCrowns': showVowelCrowns,
        'strictStageLock': strictStageLock,
        'leftHandedMode': leftHandedMode,
        'highContrastMode': highContrastMode,
        'largeTextMode': largeTextMode,
        'appLanguage': appLanguage.code,
        'bridgeLanguage': bridgeLanguage.code,
        'dailyScreenTimeLimitMinutes': dailyScreenTimeLimitMinutes,
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
      strictStageLock: (json['strictStageLock'] as bool?) ?? false,
      leftHandedMode: (json['leftHandedMode'] as bool?) ?? false,
      highContrastMode: (json['highContrastMode'] as bool?) ?? false,
      largeTextMode: (json['largeTextMode'] as bool?) ?? false,
      appLanguage: AppLanguage.fromCode(json['appLanguage'] as String?),
      bridgeLanguage:
          BridgeLanguage.fromCode(json['bridgeLanguage'] as String?),
      dailyScreenTimeLimitMinutes:
          ((json['dailyScreenTimeLimitMinutes'] as num?)?.toInt() ?? 0)
              .clamp(0, 180),
    );
  }
}

class ChildProfile {
  final String id;
  final String name;
  final String avatarEmoji;
  final String themeColorHex;
  final String groupName;
  final String emojiPin;
  final BridgeLanguage? profileBridgeLanguage;
  final bool? profileLeftHandedMode;
  final SpeechSpeed? profileSpeechSpeed;
  final int totalStars;
  final int bonusStars;
  final Map<String, Set<String>> completedModulesByUnit;
  final Map<String, Set<String>> tracingStepsByUnit;
  final Set<String> completedBonuses;
  final Set<int> unlockedStagesOverride;
  final Map<String, int> mistakeCountsByUnit;
  final Map<String, int> masteryBoxByUnit;
  final Map<String, String> lastPracticedDateByUnit;
  final Set<int> completedStageStories;
  final int completedDailyMissions;
  final String lastDailyMissionDate;
  final int dailyGoalTarget;
  final int dailyCompletedCount;
  final String lastActiveDate;
  final int streakDays;
  final bool dailyGoalRewardedToday;
  final Map<String, int> activityHistoryByDate;
  final int dailyActiveSeconds;
  final String activeTimeDate;
  final int bonusMinutesGrantedToday;

  const ChildProfile({
    required this.id,
    this.name = 'Lese-Entdecker',
    this.avatarEmoji = '🦊',
    this.themeColorHex = '#1E88E5',
    this.groupName = '',
    this.emojiPin = '',
    this.profileBridgeLanguage,
    this.profileLeftHandedMode,
    this.profileSpeechSpeed,
    this.totalStars = 0,
    this.bonusStars = 0,
    this.completedModulesByUnit = const {},
    this.tracingStepsByUnit = const {},
    this.completedBonuses = const {},
    this.unlockedStagesOverride = const {},
    this.mistakeCountsByUnit = const {},
    this.masteryBoxByUnit = const {},
    this.lastPracticedDateByUnit = const {},
    this.completedStageStories = const {},
    this.completedDailyMissions = 0,
    this.lastDailyMissionDate = '',
    this.dailyGoalTarget = 3,
    this.dailyCompletedCount = 0,
    this.lastActiveDate = '',
    this.streakDays = 0,
    this.dailyGoalRewardedToday = false,
    this.activityHistoryByDate = const {},
    this.dailyActiveSeconds = 0,
    this.activeTimeDate = '',
    this.bonusMinutesGrantedToday = 0,
  });

  bool get hasEmojiPin => emojiPin.trim().isNotEmpty;

  ChildProfile copyWith({
    String? id,
    String? name,
    String? avatarEmoji,
    String? themeColorHex,
    String? groupName,
    String? emojiPin,
    BridgeLanguage? profileBridgeLanguage,
    bool clearProfileBridgeLanguage = false,
    bool? profileLeftHandedMode,
    bool clearProfileLeftHandedMode = false,
    SpeechSpeed? profileSpeechSpeed,
    bool clearProfileSpeechSpeed = false,
    int? totalStars,
    int? bonusStars,
    Map<String, Set<String>>? completedModulesByUnit,
    Map<String, Set<String>>? tracingStepsByUnit,
    Set<String>? completedBonuses,
    Set<int>? unlockedStagesOverride,
    Map<String, int>? mistakeCountsByUnit,
    Map<String, int>? masteryBoxByUnit,
    Map<String, String>? lastPracticedDateByUnit,
    Set<int>? completedStageStories,
    int? completedDailyMissions,
    String? lastDailyMissionDate,
    int? dailyGoalTarget,
    int? dailyCompletedCount,
    String? lastActiveDate,
    int? streakDays,
    bool? dailyGoalRewardedToday,
    Map<String, int>? activityHistoryByDate,
    int? dailyActiveSeconds,
    String? activeTimeDate,
    int? bonusMinutesGrantedToday,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      themeColorHex: themeColorHex ?? this.themeColorHex,
      groupName: groupName ?? this.groupName,
      emojiPin: emojiPin ?? this.emojiPin,
      profileBridgeLanguage: clearProfileBridgeLanguage
          ? null
          : (profileBridgeLanguage ?? this.profileBridgeLanguage),
      profileLeftHandedMode: clearProfileLeftHandedMode
          ? null
          : (profileLeftHandedMode ?? this.profileLeftHandedMode),
      profileSpeechSpeed: clearProfileSpeechSpeed
          ? null
          : (profileSpeechSpeed ?? this.profileSpeechSpeed),
      totalStars: totalStars ?? this.totalStars,
      bonusStars: bonusStars ?? this.bonusStars,
      completedModulesByUnit:
          completedModulesByUnit ?? this.completedModulesByUnit,
      tracingStepsByUnit: tracingStepsByUnit ?? this.tracingStepsByUnit,
      completedBonuses: completedBonuses ?? this.completedBonuses,
      unlockedStagesOverride:
          unlockedStagesOverride ?? this.unlockedStagesOverride,
      mistakeCountsByUnit: mistakeCountsByUnit ?? this.mistakeCountsByUnit,
      masteryBoxByUnit: masteryBoxByUnit ?? this.masteryBoxByUnit,
      lastPracticedDateByUnit:
          lastPracticedDateByUnit ?? this.lastPracticedDateByUnit,
      completedStageStories:
          completedStageStories ?? this.completedStageStories,
      completedDailyMissions:
          completedDailyMissions ?? this.completedDailyMissions,
      lastDailyMissionDate: lastDailyMissionDate ?? this.lastDailyMissionDate,
      dailyGoalTarget: dailyGoalTarget ?? this.dailyGoalTarget,
      dailyCompletedCount: dailyCompletedCount ?? this.dailyCompletedCount,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      streakDays: streakDays ?? this.streakDays,
      dailyGoalRewardedToday:
          dailyGoalRewardedToday ?? this.dailyGoalRewardedToday,
      activityHistoryByDate:
          activityHistoryByDate ?? this.activityHistoryByDate,
      dailyActiveSeconds: dailyActiveSeconds ?? this.dailyActiveSeconds,
      activeTimeDate: activeTimeDate ?? this.activeTimeDate,
      bonusMinutesGrantedToday:
          bonusMinutesGrantedToday ?? this.bonusMinutesGrantedToday,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarEmoji': avatarEmoji,
      'themeColorHex': themeColorHex,
      'groupName': groupName,
      'emojiPin': emojiPin,
      if (profileBridgeLanguage != null)
        'profileBridgeLanguage': profileBridgeLanguage!.code,
      if (profileLeftHandedMode != null)
        'profileLeftHandedMode': profileLeftHandedMode,
      if (profileSpeechSpeed != null)
        'profileSpeechSpeed': profileSpeechSpeed!.name,
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
      'mistakeCountsByUnit': mistakeCountsByUnit,
      'masteryBoxByUnit': masteryBoxByUnit,
      'lastPracticedDateByUnit': lastPracticedDateByUnit,
      'completedStageStories': completedStageStories.toList(),
      'completedDailyMissions': completedDailyMissions,
      'lastDailyMissionDate': lastDailyMissionDate,
      'dailyGoalTarget': dailyGoalTarget,
      'dailyCompletedCount': dailyCompletedCount,
      'lastActiveDate': lastActiveDate,
      'streakDays': streakDays,
      'dailyGoalRewardedToday': dailyGoalRewardedToday,
      'activityHistoryByDate': activityHistoryByDate,
      'dailyActiveSeconds': dailyActiveSeconds,
      'activeTimeDate': activeTimeDate,
      'bonusMinutesGrantedToday': bonusMinutesGrantedToday,
    };
  }

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    Map<String, Set<String>> parseSetMap(String field) {
      final raw = (json[field] as Map<String, dynamic>?) ?? {};
      return raw.map(
        (k, v) => MapEntry(k, (v as List<dynamic>).cast<String>().toSet()),
      );
    }

    Map<String, int> parseIntMap(String field) {
      final raw = (json[field] as Map<String, dynamic>?) ?? {};
      return raw.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    Map<String, String> parseStringMap(String field) {
      final raw = (json[field] as Map<String, dynamic>?) ?? {};
      return raw.map((k, v) => MapEntry(k, v.toString()));
    }

    final rawBridge = json['profileBridgeLanguage'] as String?;
    final rawSpeed = json['profileSpeechSpeed'] as String?;
    SpeechSpeed? parsedSpeed;
    if (rawSpeed != null) {
      for (final s in SpeechSpeed.values) {
        if (s.name == rawSpeed) {
          parsedSpeed = s;
          break;
        }
      }
    }

    return ChildProfile(
      id: (json['id'] as String?) ?? 'default',
      name: (json['name'] as String?) ??
          (json['childName'] as String?) ??
          'Lese-Entdecker',
      avatarEmoji: (json['avatarEmoji'] as String?) ?? '🦊',
      themeColorHex: (json['themeColorHex'] as String?) ?? '#1E88E5',
      groupName: (json['groupName'] as String?) ?? '',
      emojiPin: (json['emojiPin'] as String?) ?? '',
      profileBridgeLanguage:
          rawBridge != null ? BridgeLanguage.fromCode(rawBridge) : null,
      profileLeftHandedMode: json['profileLeftHandedMode'] as bool?,
      profileSpeechSpeed: parsedSpeed,
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
      mistakeCountsByUnit: parseIntMap('mistakeCountsByUnit'),
      masteryBoxByUnit: parseIntMap('masteryBoxByUnit'),
      lastPracticedDateByUnit: parseStringMap('lastPracticedDateByUnit'),
      completedStageStories:
          ((json['completedStageStories'] as List<dynamic>?) ?? [])
              .map((e) => (e as num).toInt())
              .toSet(),
      completedDailyMissions:
          (json['completedDailyMissions'] as num?)?.toInt() ?? 0,
      lastDailyMissionDate: (json['lastDailyMissionDate'] as String?) ?? '',
      dailyGoalTarget: (json['dailyGoalTarget'] as num?)?.toInt() ?? 3,
      dailyCompletedCount: (json['dailyCompletedCount'] as num?)?.toInt() ?? 0,
      lastActiveDate: (json['lastActiveDate'] as String?) ?? '',
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      dailyGoalRewardedToday: (json['dailyGoalRewardedToday'] as bool?) ?? false,
      activityHistoryByDate: parseIntMap('activityHistoryByDate'),
      dailyActiveSeconds: (json['dailyActiveSeconds'] as num?)?.toInt() ?? 0,
      activeTimeDate: (json['activeTimeDate'] as String?) ?? '',
      bonusMinutesGrantedToday:
          (json['bonusMinutesGrantedToday'] as num?)?.toInt() ?? 0,
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

  /// Combines global settings with any per-child overrides configured on [activeProfile].
  AppSettings get effectiveSettings {
    final p = activeProfile;
    return settings.copyWith(
      leftHandedMode: p.profileLeftHandedMode ?? settings.leftHandedMode,
      speechSpeed: p.profileSpeechSpeed ?? settings.speechSpeed,
      bridgeLanguage: p.profileBridgeLanguage ?? settings.bridgeLanguage,
    );
  }

  BridgeLanguage get effectiveBridgeLanguage =>
      activeProfile.profileBridgeLanguage ?? settings.bridgeLanguage;

  String get childName => activeProfile.name;
  String get avatarEmoji => activeProfile.avatarEmoji;
  String get themeColorHex => activeProfile.themeColorHex;
  String get groupName => activeProfile.groupName;
  int get totalStars => activeProfile.totalStars;
  int get bonusStars => activeProfile.bonusStars;
  Map<String, Set<String>> get completedModulesByUnit =>
      activeProfile.completedModulesByUnit;
  Map<String, Set<String>> get tracingStepsByUnit =>
      activeProfile.tracingStepsByUnit;
  Set<String> get completedBonuses => activeProfile.completedBonuses;
  Set<int> get unlockedStagesOverride => activeProfile.unlockedStagesOverride;
  Map<String, int> get mistakeCountsByUnit => activeProfile.mistakeCountsByUnit;
  Map<String, int> get masteryBoxByUnit => activeProfile.masteryBoxByUnit;
  Map<String, String> get lastPracticedDateByUnit =>
      activeProfile.lastPracticedDateByUnit;
  Set<int> get completedStageStories => activeProfile.completedStageStories;
  int get completedDailyMissions => activeProfile.completedDailyMissions;
  String get lastDailyMissionDate => activeProfile.lastDailyMissionDate;
  int get dailyGoalTarget => activeProfile.dailyGoalTarget;
  int get dailyCompletedCount => activeProfile.dailyCompletedCount;
  int get streakDays => activeProfile.streakDays;
  Map<String, int> get activityHistoryByDate =>
      activeProfile.activityHistoryByDate;

  static String todayIsoString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static int _daysBetweenIso(String fromIso, String toIso) {
    final a = DateTime.tryParse(fromIso);
    final b = DateTime.tryParse(toIso);
    if (a == null || b == null) return 0;
    final start = DateTime.utc(a.year, a.month, a.day);
    final end = DateTime.utc(b.year, b.month, b.day);
    return end.difference(start).inDays;
  }

  /// Returns true if the active child has already completed a guided Abenteuer-Runde today.
  bool isDailyMissionDoneToday({String? todayIso}) {
    final today = todayIso ?? todayIsoString();
    return activeProfile.lastDailyMissionDate == today;
  }

  /// Active learning seconds accumulated today for the active profile.
  int activeSecondsForToday({String? todayIso}) {
    final today = todayIso ?? todayIsoString();
    if (activeProfile.activeTimeDate != today) return 0;
    return activeProfile.dailyActiveSeconds;
  }

  /// Effective daily screen-time limit in minutes (`0` means disabled/unlimited).
  int effectiveScreenTimeLimitMinutes({String? todayIso}) {
    final baseLimit = settings.dailyScreenTimeLimitMinutes;
    if (baseLimit <= 0) return 0;
    final today = todayIso ?? todayIsoString();
    final extra = activeProfile.activeTimeDate == today
        ? activeProfile.bonusMinutesGrantedToday
        : 0;
    return baseLimit + extra;
  }

  /// Remaining seconds before Fips & Fina's gentle bedtime pause (`-1` if limit is off).
  int remainingScreenTimeSeconds({String? todayIso}) {
    final limitMin = effectiveScreenTimeLimitMinutes(todayIso: todayIso);
    if (limitMin <= 0) return -1;
    final used = activeSecondsForToday(todayIso: todayIso);
    return (limitMin * 60 - used).clamp(0, 86400);
  }

  /// True when a daily screen-time limit is active and today's allowance is used up.
  bool isBedtimePauseReached({String? todayIso}) {
    final limitMin = effectiveScreenTimeLimitMinutes(todayIso: todayIso);
    if (limitMin <= 0) return false;
    return activeSecondsForToday(todayIso: todayIso) >= limitMin * 60;
  }

  /// Counts of practiced units across Leitner Spaced-Repetition boxes (1 = 🌱, 2 = 🌿, 3 = 🌳).
  ({int box1, int box2, int box3}) get masteryBoxCounts {
    int b1 = 0;
    int b2 = 0;
    int b3 = 0;
    final allTrackedIds = <String>{
      ...completedModulesByUnit.keys,
      ...mistakeCountsByUnit.keys,
      ...masteryBoxByUnit.keys,
    };
    for (final id in allTrackedIds) {
      final box = effectiveMasteryBox(id);
      if (box <= 1) {
        b1++;
      } else if (box == 2) {
        b2++;
      } else {
        b3++;
      }
    }
    return (box1: b1, box2: b2, box3: b3);
  }

  /// Effective Leitner box (`1..3`) for [unitId]. Mistakes always pull a unit into Box 1.
  int effectiveMasteryBox(String unitId) {
    if ((mistakeCountsByUnit[unitId] ?? 0) > 0) return 1;
    final stored = masteryBoxByUnit[unitId];
    if (stored != null) return stored.clamp(1, 3);
    final doneCount = completedCountForUnit(unitId);
    if (doneCount >= 4) return 3;
    if (doneCount >= 2) return 2;
    return 1;
  }

  /// Required review interval in days for a given Leitner box (`1 -> 1d`, `2 -> 3d`, `3 -> 7d`).
  static int reviewIntervalDaysForBox(int box) => switch (box) {
        1 => 1,
        2 => 3,
        _ => 7,
      };

  /// Returns all distinct non-empty group/class names across profiles.
  List<String> get availableGroups {
    final set = <String>{};
    for (final p in profiles) {
      final g = p.groupName.trim();
      if (g.isNotEmpty) set.add(g);
    }
    final list = set.toList()..sort();
    return list;
  }

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

  bool isStageStoryCompleted(int stage) {
    return completedStageStories.contains(stage) ||
        completedBonuses.contains('stage_story:$stage');
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

  /// Returns unit IDs sorted by mistake frequency, followed by due Leitner Spaced-Repetition units.
  List<String> unitsNeedingReview({
    int limit = 5,
    String? referenceDateIso,
  }) {
    final today = referenceDateIso ?? todayIsoString();
    final mistakeEntries = mistakeCountsByUnit.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <String>[];
    for (final e in mistakeEntries) {
      if (result.length >= limit) return result;
      result.add(e.key);
    }

    // Spaced Repetition (Leitner boxes 1..3): include units whose review interval elapsed
    final dueLeitner = <({String unitId, int box, int overdueDays})>[];
    final candidateIds = <String>{
      ...masteryBoxByUnit.keys,
      ...lastPracticedDateByUnit.keys,
    };
    for (final unitId in candidateIds) {
      if (result.contains(unitId)) continue;
      final lastIso = lastPracticedDateByUnit[unitId];
      if (lastIso == null || lastIso.isEmpty) continue;
      final box = effectiveMasteryBox(unitId);
      final interval = reviewIntervalDaysForBox(box);
      final elapsed = _daysBetweenIso(lastIso, today);
      if (elapsed >= interval) {
        dueLeitner.add((
          unitId: unitId,
          box: box,
          overdueDays: elapsed - interval,
        ));
      }
    }

    dueLeitner.sort((a, b) {
      final boxCmp = a.box.compareTo(b.box);
      if (boxCmp != 0) return boxCmp;
      return b.overdueDays.compareTo(a.overdueDays);
    });

    for (final item in dueLeitner) {
      if (result.length >= limit) break;
      result.add(item.unitId);
    }
    return result;
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

  /// Pedagogical 70% progression status: Stage 1 is always unlocked.
  /// Stage n > 1 reaches unlocked status when Stage n-1 has >= 70% of core module stars
  /// OR when unlocked via teacher override in ParentDashboard.
  bool isStageUnlocked(int stage, List<LessonUnit> allUnits) {
    if (stage <= 1) return true;
    if (unlockedStagesOverride.contains(stage)) return true;
    final prev = stageProgress(stage - 1, allUnits);
    return prev.ratio >= 0.70;
  }

  /// Returns true when the child can open units in [stage].
  bool isStageAccessible(int stage, List<LessonUnit> allUnits) {
    if (!settings.strictStageLock) return true;
    return isStageUnlocked(stage, allUnits);
  }

  /// Returns true when a child has earned the Lese-Urkunde for [stage]
  /// (either by completing the stage story or reaching >= 70% of stage stars).
  bool isStageCertificateEarned(int stage, List<LessonUnit> allUnits) {
    if (isStageStoryCompleted(stage)) return true;
    final stats = stageProgress(stage, allUnits);
    return stats.max > 0 && stats.ratio >= 0.70;
  }

  /// Generates a human-readable, offline Markdown/text report of the active child's
  /// learning progress, competencies, and earned stage certificates in [language]
  /// (defaults to `settings.appLanguage`, which is `AppLanguage.de`).
  String generateParentReport(
    CurriculumData curriculum, {
    AppLanguage? language,
  }) {
    final lang = language ?? settings.appLanguage;
    final loc = AppLocalizations.of(lang);
    final p = activeProfile;
    final totalUnits = curriculum.units.length;
    final phonics = completedCountForModuleType(ModuleType.phonics);
    final tracing = completedCountForModuleType(ModuleType.tracing);
    final syllables = completedCountForModuleType(ModuleType.syllables);
    final reading = completedCountForModuleType(ModuleType.reading);
    final stories = completedStageStories.length;
    final boxes = masteryBoxCounts;
    final todayMinutes = (activeSecondsForToday() / 60).ceil();

    final buf = StringBuffer()
      ..writeln(loc.tr('report_header'))
      ..writeln('${loc.tr('report_child')}: ${p.avatarEmoji} ${p.name}');
    if (p.groupName.trim().isNotEmpty) {
      buf.writeln('${loc.tr('report_group')}: ${p.groupName}');
    }
    if (effectiveBridgeLanguage.isEnabled) {
      buf.writeln(
        'DaZ-Wort-Brücke: ${effectiveBridgeLanguage.flagEmoji} ${effectiveBridgeLanguage.nativeName}',
      );
    }
    buf
      ..writeln(
        '${loc.tr('report_stars')}: ${p.totalStars} ⭐ (${p.bonusStars} ${loc.tr('report_bonus')})',
      )
      ..writeln(
        '${loc.tr('report_daily')}: ${p.dailyCompletedCount}/${p.dailyGoalTarget} • ${loc.tr('report_streak')}: ${p.streakDays} ${loc.tr('report_days')} 🔥',
      )
      ..writeln(
        '${loc.tr('report_missions')}: ${p.completedDailyMissions} 🧭 • ${loc.tr('report_screen_time')}: $todayMinutes Min.',
      )
      ..writeln(
        '${loc.tr('report_leitner')}: 🌱 ${boxes.box1} • 🌿 ${boxes.box2} • 🌳 ${boxes.box3}',
      )
      ..writeln('')
      ..writeln(loc.tr('report_competencies'))
      ..writeln('${loc.tr('report_mod_phonics')}: $phonics / $totalUnits')
      ..writeln('${loc.tr('report_mod_tracing')}:   $tracing / $totalUnits')
      ..writeln('${loc.tr('report_mod_syllables')}:         $syllables / $totalUnits')
      ..writeln('${loc.tr('report_mod_reading')}:     $reading / $totalUnits')
      ..writeln(
        '${loc.tr('report_mod_stories')}:     $stories / ${curriculum.stageStories.length}',
      )
      ..writeln('')
      ..writeln(loc.tr('report_stages'));

    for (final stage in curriculum.stages) {
      final st = stageProgress(stage, curriculum.units);
      final pct = (st.ratio * 100).round();
      final cert = isStageCertificateEarned(stage, curriculum.units)
          ? loc.tr('report_cert_earned')
          : loc.tr('report_cert_in_progress');
      buf.writeln(
        '${loc.tr('report_stage')} $stage: ${st.earned}/${st.max} ⭐ ($pct %) – $cert',
      );
    }

    final reviewIds = unitsNeedingReview();
    if (reviewIds.isNotEmpty) {
      final letters = reviewIds
          .map(
            (id) => curriculum.units
                .where((u) => u.id == id)
                .map((u) => u.letter)
                .firstOrNull,
          )
          .whereType<String>()
          .toList();
      if (letters.isNotEmpty) {
        buf
          ..writeln('')
          ..writeln('${loc.tr('report_review_rec')}: ${letters.join(', ')}');
      }
    }
    return buf.toString().trim();
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
      'version': 4,
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
  static const _storageKeyV3 = 'fibel_child_progress_v3';
  static const _storageKeyV4 = 'fibel_child_progress_v4';

  Future<ChildProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in const [
      _storageKeyV4,
      _storageKeyV3,
      _storageKeyV2,
      _storageKeyV1,
    ]) {
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final loaded = ChildProgress.fromJson(decoded);
          if (key != _storageKeyV4) {
            await saveProgress(loaded);
          }
          return loaded;
        } catch (_) {}
      }
    }

    return const ChildProgress();
  }

  Future<void> saveProgress(ChildProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(progress.toJson());
    await prefs.setString(_storageKeyV4, encoded);
    await prefs.setString(_storageKeyV3, encoded);
    await prefs.setString(_storageKeyV2, encoded);
    await prefs.setString(_storageKeyV1, encoded);
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKeyV4);
    await prefs.remove(_storageKeyV3);
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

  static String _todayIso() => ChildProgress.todayIsoString();

  ChildProfile _recordDailyActivity(ChildProfile profile, {String? dateIso}) {
    final today = dateIso ?? _todayIso();
    int streak = profile.streakDays;
    int dailyCount = profile.dailyCompletedCount;
    bool rewarded = profile.dailyGoalRewardedToday;

    if (profile.lastActiveDate != today) {
      final parsedToday = DateTime.tryParse(today) ?? DateTime.now();
      final yesterday = parsedToday.subtract(const Duration(days: 1));
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

    final nextHistory = Map<String, int>.from(profile.activityHistoryByDate);
    nextHistory[today] = dailyCount;

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
      activityHistoryByDate: nextHistory,
    );
  }

  Future<void> updateChildName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _mutated = true;
    state = state.updateActive((p) => p.copyWith(name: trimmed));
    await _repo.saveProgress(state);
  }

  Future<void> updateActiveProfile({
    String? name,
    String? avatarEmoji,
    String? themeColorHex,
    String? groupName,
    String? emojiPin,
    BridgeLanguage? profileBridgeLanguage,
    bool clearProfileBridgeLanguage = false,
    bool? profileLeftHandedMode,
    bool clearProfileLeftHandedMode = false,
    SpeechSpeed? profileSpeechSpeed,
    bool clearProfileSpeechSpeed = false,
  }) async {
    _mutated = true;
    state = state.updateActive(
      (p) => p.copyWith(
        name: (name != null && name.trim().isNotEmpty) ? name.trim() : p.name,
        avatarEmoji: avatarEmoji ?? p.avatarEmoji,
        themeColorHex: themeColorHex ?? p.themeColorHex,
        groupName: groupName != null ? groupName.trim() : p.groupName,
        emojiPin: emojiPin != null ? emojiPin.trim() : p.emojiPin,
        profileBridgeLanguage: profileBridgeLanguage,
        clearProfileBridgeLanguage: clearProfileBridgeLanguage,
        profileLeftHandedMode: profileLeftHandedMode,
        clearProfileLeftHandedMode: clearProfileLeftHandedMode,
        profileSpeechSpeed: profileSpeechSpeed,
        clearProfileSpeechSpeed: clearProfileSpeechSpeed,
      ),
    );
    await _repo.saveProgress(state);
  }

  /// Verifies the optional 2-emoji child lock PIN for [profileId].
  /// Returns true if the profile has no PIN or if [enteredPin] matches.
  bool verifyEmojiPin(String profileId, String enteredPin) {
    final match = state.profiles.where((p) => p.id == profileId).firstOrNull;
    if (match == null || !match.hasEmojiPin) return true;
    return match.emojiPin == enteredPin.trim();
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
    String themeColorHex = '#1E88E5',
    String groupName = '',
    String emojiPin = '',
    BridgeLanguage? profileBridgeLanguage,
    bool? profileLeftHandedMode,
    SpeechSpeed? profileSpeechSpeed,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _mutated = true;
    final newId =
        'child_${DateTime.now().microsecondsSinceEpoch}_${state.profiles.length}';
    final newProfile = ChildProfile(
      id: newId,
      name: trimmed,
      avatarEmoji: avatarEmoji,
      themeColorHex: themeColorHex,
      groupName: groupName.trim(),
      emojiPin: emojiPin.trim(),
      profileBridgeLanguage: profileBridgeLanguage,
      profileLeftHandedMode: profileLeftHandedMode,
      profileSpeechSpeed: profileSpeechSpeed,
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
    final remaining = state.profiles.where((p) => p.id != profileId).toList();
    final nextActive = state.activeProfileId == profileId
        ? remaining.first.id
        : state.activeProfileId;
    state = state.copyWith(
      activeProfileId: nextActive,
      profiles: remaining,
    );
    await _repo.saveProgress(state);
  }

  Future<void> completeModule(
    String unitId,
    ModuleType module, {
    String? dateIso,
  }) async {
    _mutated = true;
    final today = dateIso ?? _todayIso();
    state = state.updateActive((profile) {
      final currentMap = Map<String, Set<String>>.from(
        profile.completedModulesByUnit.map(
          (k, v) => MapEntry(k, Set<String>.from(v)),
        ),
      );
      final unitSet = currentMap.putIfAbsent(unitId, () => <String>{});
      final isNew = unitSet.add(module.name);

      // Reduce mistake counter when a child successfully completes a module
      final nextMistakes = Map<String, int>.from(profile.mistakeCountsByUnit);
      if (nextMistakes.containsKey(unitId)) {
        final decreased = nextMistakes[unitId]! - 1;
        if (decreased <= 0) {
          nextMistakes.remove(unitId);
        } else {
          nextMistakes[unitId] = decreased;
        }
      }

      // Advance Spaced Repetition Leitner box (1 -> 2 -> 3) when no mistakes remain
      final nextBoxes = Map<String, int>.from(profile.masteryBoxByUnit);
      final prevBox = nextBoxes[unitId] ?? 1;
      nextBoxes[unitId] = nextMistakes.containsKey(unitId)
          ? 1
          : (prevBox + 1).clamp(1, 3);

      final nextPracticed =
          Map<String, String>.from(profile.lastPracticedDateByUnit);
      nextPracticed[unitId] = today;

      var updated = profile.copyWith(
        totalStars: isNew ? profile.totalStars + 1 : profile.totalStars,
        completedModulesByUnit: currentMap,
        mistakeCountsByUnit: nextMistakes,
        masteryBoxByUnit: nextBoxes,
        lastPracticedDateByUnit: nextPracticed,
      );
      if (isNew) {
        updated = _recordDailyActivity(updated, dateIso: today);
      }
      return updated;
    });
    await _repo.saveProgress(state);
  }

  /// Records a mistake for adaptive Spaced Repetition (demotes to Box 1) and diagnostic feedback.
  Future<void> recordMistake(String unitId, {String? dateIso}) async {
    _mutated = true;
    final today = dateIso ?? _todayIso();
    state = state.updateActive((profile) {
      final next = Map<String, int>.from(profile.mistakeCountsByUnit);
      next[unitId] = (next[unitId] ?? 0) + 1;
      final nextBoxes = Map<String, int>.from(profile.masteryBoxByUnit);
      nextBoxes[unitId] = 1;
      final nextPracticed =
          Map<String, String>.from(profile.lastPracticedDateByUnit);
      nextPracticed[unitId] = today;
      return profile.copyWith(
        mistakeCountsByUnit: next,
        masteryBoxByUnit: nextBoxes,
        lastPracticedDateByUnit: nextPracticed,
      );
    });
    await _repo.saveProgress(state);
  }

  /// Records a solved step inside the Guided Daily Mission („Abenteuer-Runde“),
  /// reducing mistake count and advancing the unit's Spaced-Repetition Leitner box.
  Future<void> recordMissionStepSuccess(
    String unitId, {
    String? dateIso,
  }) async {
    _mutated = true;
    final today = dateIso ?? _todayIso();
    state = state.updateActive((profile) {
      final nextMistakes = Map<String, int>.from(profile.mistakeCountsByUnit);
      if (nextMistakes.containsKey(unitId)) {
        final decreased = nextMistakes[unitId]! - 1;
        if (decreased <= 0) {
          nextMistakes.remove(unitId);
        } else {
          nextMistakes[unitId] = decreased;
        }
      }
      final nextBoxes = Map<String, int>.from(profile.masteryBoxByUnit);
      final prevBox = nextBoxes[unitId] ?? 1;
      nextBoxes[unitId] = nextMistakes.containsKey(unitId)
          ? 1
          : (prevBox + 1).clamp(1, 3);

      final nextPracticed =
          Map<String, String>.from(profile.lastPracticedDateByUnit);
      nextPracticed[unitId] = today;

      return profile.copyWith(
        mistakeCountsByUnit: nextMistakes,
        masteryBoxByUnit: nextBoxes,
        lastPracticedDateByUnit: nextPracticed,
      );
    });
    await _repo.saveProgress(state);
  }

  /// Completes a 3-station Guided Daily Mission („Abenteuer-Runde“), awarding
  /// +2 bonus stars on the first round of the day (+1 star on extra replay rounds).
  Future<int> completeDailyMission({String? dateIso}) async {
    _mutated = true;
    final today = dateIso ?? _todayIso();
    int awarded = 1;
    state = state.updateActive((profile) {
      final firstToday = profile.lastDailyMissionDate != today;
      awarded = firstToday ? 2 : 1;
      var updated = profile.copyWith(
        totalStars: profile.totalStars + awarded,
        bonusStars: profile.bonusStars + awarded,
        completedDailyMissions: profile.completedDailyMissions + 1,
        lastDailyMissionDate: today,
      );
      updated = _recordDailyActivity(updated, dateIso: today);
      return updated;
    });
    await _repo.saveProgress(state);
    return awarded;
  }

  /// Tracks active learning seconds for the „Schlafenszeit-Pause“ child protection timer.
  Future<void> recordActiveLearningSeconds(
    int seconds, {
    String? dateIso,
  }) async {
    if (seconds <= 0) return;
    _mutated = true;
    final today = dateIso ?? _todayIso();
    final clamped = seconds.clamp(1, 600);
    state = state.updateActive((profile) {
      final sameDay = profile.activeTimeDate == today;
      final nextSeconds = (sameDay ? profile.dailyActiveSeconds : 0) + clamped;
      final nextBonusMin = sameDay ? profile.bonusMinutesGrantedToday : 0;
      return profile.copyWith(
        dailyActiveSeconds: nextSeconds,
        activeTimeDate: today,
        bonusMinutesGrantedToday: nextBonusMin,
      );
    });
    await _repo.saveProgress(state);
  }

  /// Parent override behind ParentalGate: grants extra learning minutes for today.
  Future<void> grantExtraScreenTimeMinutes(
    int extraMinutes, {
    String? dateIso,
  }) async {
    if (extraMinutes <= 0) return;
    _mutated = true;
    final today = dateIso ?? _todayIso();
    state = state.updateActive((profile) {
      final sameDay = profile.activeTimeDate == today;
      final currentBonus = sameDay ? profile.bonusMinutesGrantedToday : 0;
      final currentSec = sameDay ? profile.dailyActiveSeconds : 0;
      return profile.copyWith(
        activeTimeDate: today,
        dailyActiveSeconds: currentSec,
        bonusMinutesGrantedToday: currentBonus + extraMinutes.clamp(1, 60),
      );
    });
    await _repo.saveProgress(state);
  }

  /// Updates the optional daily screen-time limit in minutes (`0` = off, `10/15/20/30`).
  Future<void> updateScreenTimeLimitMinutes(int limitMinutes) async {
    _mutated = true;
    state = state.copyWith(
      settings: state.settings.copyWith(
        dailyScreenTimeLimitMinutes: limitMinutes.clamp(0, 180),
      ),
    );
    await _repo.saveProgress(state);
  }

  /// Marks a stage story as read & understood, awarding +2 bonus stars on first completion.
  Future<bool> completeStageStory(int stage) async {
    _mutated = true;
    bool newlyCompleted = false;
    state = state.updateActive((profile) {
      if (profile.completedStageStories.contains(stage)) {
        return profile;
      }
      newlyCompleted = true;
      final nextStories = Set<int>.from(profile.completedStageStories)
        ..add(stage);
      final nextBonuses = Set<String>.from(profile.completedBonuses)
        ..add('stage_story:$stage');
      var updated = profile.copyWith(
        totalStars: profile.totalStars + 2,
        bonusStars: profile.bonusStars + 2,
        completedStageStories: nextStories,
        completedBonuses: nextBonuses,
      );
      updated = _recordDailyActivity(updated);
      return updated;
    });
    if (newlyCompleted) {
      await _repo.saveProgress(state);
    }
    return newlyCompleted;
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

  /// Awards bonus star(s) for completing optional challenges. Returns true if newly awarded.
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

  Future<void> updateDailyGoalTarget(int target) async {
    final clamped = target.clamp(1, 10);
    _mutated = true;
    state = state.updateActive((p) => p.copyWith(dailyGoalTarget: clamped));
    await _repo.saveProgress(state);
  }

  /// Exports all profiles and settings as a formatted JSON string for offline backup.
  String exportProgressJson() {
    return const JsonEncoder.withIndent('  ').convert(state.toJson());
  }

  /// Exports only the currently active child profile as a standalone JSON object.
  String exportActiveProfileJson() {
    return const JsonEncoder.withIndent('  ')
        .convert(state.activeProfile.toJson());
  }

  /// Imports profiles and settings from a JSON backup string (100% offline, replaces state).
  Future<bool> importProgressJson(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final imported = ChildProgress.fromJson(decoded);
      _mutated = true;
      state = imported;
      await _repo.saveProgress(state);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Imports a single ChildProfile JSON (or all profiles from a full backup) and merges
  /// them into the existing profile list without deleting other sibling/classroom profiles.
  Future<bool> importAndMergeProfileJson(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final incomingProfiles = <ChildProfile>[];
      if (decoded.containsKey('profiles')) {
        final full = ChildProgress.fromJson(decoded);
        incomingProfiles.addAll(full.profiles);
      } else {
        incomingProfiles.add(ChildProfile.fromJson(decoded));
      }
      if (incomingProfiles.isEmpty) return false;

      _mutated = true;
      final existingById = {for (final p in state.profiles) p.id: p};
      String lastMergedId = state.activeProfileId;

      for (var inc in incomingProfiles) {
        if (existingById.containsKey(inc.id) && inc.id == 'default') {
          inc = inc.copyWith(
            id: 'child_${DateTime.now().microsecondsSinceEpoch}_${existingById.length}',
          );
        }
        existingById[inc.id] = inc;
        lastMergedId = inc.id;
      }

      state = state.copyWith(
        activeProfileId: lastMergedId,
        profiles: existingById.values.toList(),
      );
      await _repo.saveProgress(state);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetActiveProfileProgress() async {
    _mutated = true;
    state = state.updateActive(
      (p) => ChildProfile(
        id: p.id,
        name: p.name,
        avatarEmoji: p.avatarEmoji,
        themeColorHex: p.themeColorHex,
        groupName: p.groupName,
        emojiPin: p.emojiPin,
        profileBridgeLanguage: p.profileBridgeLanguage,
        profileLeftHandedMode: p.profileLeftHandedMode,
        profileSpeechSpeed: p.profileSpeechSpeed,
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
