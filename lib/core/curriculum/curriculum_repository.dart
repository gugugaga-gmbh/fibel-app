import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'curriculum_models.dart';

class CurriculumRepository {
  static const String assetPath = 'assets/data/curriculum_de.json';
  static CurriculumData? _cached;

  Future<CurriculumData> loadCurriculum({AssetBundle? bundle}) async {
    if (bundle == null && _cached != null) {
      return _cached!;
    }
    final targetBundle = bundle ?? rootBundle;
    final rawJson = await targetBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final data = CurriculumData.fromJson(decoded);
    if (bundle == null) {
      _cached = data;
    }
    return data;
  }
}

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return CurriculumRepository();
});

final curriculumProvider = FutureProvider<CurriculumData>((ref) async {
  final repo = ref.watch(curriculumRepositoryProvider);
  return repo.loadCurriculum();
});
