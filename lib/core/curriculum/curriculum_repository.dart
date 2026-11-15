import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'curriculum_models.dart';

class CurriculumRepository {
  static const String assetPath = 'assets/data/curriculum_de.json';

  Future<CurriculumData> loadCurriculum({AssetBundle? bundle}) async {
    final targetBundle = bundle ?? rootBundle;
    final rawJson = await targetBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return CurriculumData.fromJson(decoded);
  }
}

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return CurriculumRepository();
});

final curriculumProvider = FutureProvider<CurriculumData>((ref) async {
  final repo = ref.watch(curriculumRepositoryProvider);
  return repo.loadCurriculum();
});
