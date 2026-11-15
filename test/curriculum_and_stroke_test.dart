import 'package:fibel_app/core/curriculum/curriculum_repository.dart';
import 'package:fibel_app/core/storage/progress_repository.dart';
import 'package:fibel_app/features/writing/stroke_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurriculumRepository', () {
    test('loads curriculum_de.json with units, anlautTable and stickers',
        () async {
      final repo = CurriculumRepository();
      final data = await repo.loadCurriculum();

      expect(data.units.length, 10);
      expect(data.units.first.letter, 'M');
      expect(data.anlautTable.length, greaterThanOrEqualTo(26));
      expect(data.stickers.length, greaterThanOrEqualTo(5));
    });
  });

  group('StrokeValidator', () {
    final reference = [
      [const Offset(0.2, 0.2), const Offset(0.2, 0.8)],
    ];

    test('returns true when user traces along reference path', () {
      final user = [
        [
          const Offset(0.20, 0.20),
          const Offset(0.21, 0.35),
          const Offset(0.19, 0.50),
          const Offset(0.20, 0.65),
          const Offset(0.21, 0.80),
        ],
      ];
      expect(
        StrokeValidator.validateStrokes(
          referenceStrokes: reference,
          userStrokesNormalized: user,
        ),
        isTrue,
      );
    });

    test('returns false when user draws far away from reference path', () {
      final user = [
        [
          const Offset(0.8, 0.2),
          const Offset(0.8, 0.4),
          const Offset(0.8, 0.6),
          const Offset(0.8, 0.8),
        ],
      ];
      expect(
        StrokeValidator.validateStrokes(
          referenceStrokes: reference,
          userStrokesNormalized: user,
        ),
        isFalse,
      );
    });
  });

  group('ProgressRepository', () {
    test('saves and loads child progress locally', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = ProgressRepository();
      final notifier = ProgressNotifier(repo);

      await notifier.updateChildName('Mia');
      await notifier.completeModule('unit_01_m', ModuleType.tracing);
      await notifier.completeModule('unit_01_m', ModuleType.syllables);

      expect(notifier.state.childName, 'Mia');
      expect(notifier.state.totalStars, 2);
      expect(
        notifier.state.isModuleCompleted('unit_01_m', ModuleType.tracing),
        isTrue,
      );

      final loaded = await repo.loadProgress();
      expect(loaded.childName, 'Mia');
      expect(loaded.totalStars, 2);
    });
  });
}
