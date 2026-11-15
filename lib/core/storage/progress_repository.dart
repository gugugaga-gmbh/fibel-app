import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ModuleType { phonics, tracing, syllables, reading }

class ChildProgress {
  final String childName;
  final int totalStars;
  final Map<String, Set<String>> completedModulesByUnit;

  const ChildProgress({
    this.childName = 'Lese-Entdecker',
    this.totalStars = 0,
    this.completedModulesByUnit = const {},
  });

  bool isModuleCompleted(String unitId, ModuleType module) {
    return completedModulesByUnit[unitId]?.contains(module.name) ?? false;
  }

  int completedCountForUnit(String unitId) {
    return completedModulesByUnit[unitId]?.length ?? 0;
  }

  ChildProgress copyWith({
    String? childName,
    int? totalStars,
    Map<String, Set<String>>? completedModulesByUnit,
  }) {
    return ChildProgress(
      childName: childName ?? this.childName,
      totalStars: totalStars ?? this.totalStars,
      completedModulesByUnit:
          completedModulesByUnit ?? this.completedModulesByUnit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childName': childName,
      'totalStars': totalStars,
      'completedModulesByUnit': completedModulesByUnit.map(
        (key, value) => MapEntry(key, value.toList()),
      ),
    };
  }

  factory ChildProgress.fromJson(Map<String, dynamic> json) {
    final rawMap =
        (json['completedModulesByUnit'] as Map<String, dynamic>?) ?? {};
    final mapped = rawMap.map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>).cast<String>().toSet(),
      ),
    );
    return ChildProgress(
      childName: (json['childName'] as String?) ?? 'Lese-Entdecker',
      totalStars: (json['totalStars'] as num?)?.toInt() ?? 0,
      completedModulesByUnit: mapped,
    );
  }
}

class ProgressRepository {
  static const _storageKey = 'fibel_child_progress_v1';

  Future<ChildProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const ChildProgress();
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return ChildProgress.fromJson(decoded);
    } catch (_) {
      return const ChildProgress();
    }
  }

  Future<void> saveProgress(ChildProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(progress.toJson()));
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

class ProgressNotifier extends StateNotifier<ChildProgress> {
  final ProgressRepository _repo;

  ProgressNotifier(this._repo) : super(const ChildProgress()) {
    _init();
  }

  Future<void> _init() async {
    state = await _repo.loadProgress();
  }

  Future<void> updateChildName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(childName: trimmed);
    await _repo.saveProgress(state);
  }

  Future<void> completeModule(String unitId, ModuleType module) async {
    final currentMap = Map<String, Set<String>>.from(
      state.completedModulesByUnit.map((k, v) => MapEntry(k, Set<String>.from(v))),
    );
    final unitSet = currentMap.putIfAbsent(unitId, () => <String>{});
    final isNew = unitSet.add(module.name);
    state = state.copyWith(
      totalStars: isNew ? state.totalStars + 1 : state.totalStars,
      completedModulesByUnit: currentMap,
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
