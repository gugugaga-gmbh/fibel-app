import 'package:fibel_app/core/curriculum/curriculum_repository.dart';
import 'package:fibel_app/core/storage/progress_repository.dart';
import 'package:fibel_app/features/writing/stroke_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurriculumRepository', () {
    test('loads curriculum_de.json with 33 units across 4 stages, 37 anlaute and 16 stickers',
        () async {
      final repo = CurriculumRepository();
      final data = await repo.loadCurriculum();

      expect(data.units.length, 33);
      expect(data.units.first.letter, 'M');
      expect(data.unitsForStage(1).length, 7);
      expect(data.unitsForStage(2).length, 12);
      expect(data.unitsForStage(3).length, 7);
      expect(data.unitsForStage(4).length, 7);
      expect(data.anlautTable.length, 37);
      expect(data.stickers.length, 16);
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

    test('supports multi-child profiles, 3-step tracing, bonus stars and 70% stage lock',
        () async {
      SharedPreferences.setMockInitialValues({});
      final repo = ProgressRepository();
      final notifier = ProgressNotifier(repo);
      final curriculum = await CurriculumRepository().loadCurriculum();

      // Stage 1 is unlocked, Stage 2 is locked initially
      expect(notifier.state.isStageUnlocked(1, curriculum.units), isTrue);
      expect(notifier.state.isStageUnlocked(2, curriculum.units), isFalse);

      // 3-step tracing requirement: upper + lower + freehand
      expect(await notifier.recordTracingStep('unit_01_m', 'upper'), isFalse);
      expect(await notifier.recordTracingStep('unit_01_m', 'lower'), isFalse);
      expect(
        notifier.state.isModuleCompleted('unit_01_m', ModuleType.tracing),
        isFalse,
      );
      expect(await notifier.recordTracingStep('unit_01_m', 'freehand'), isTrue);
      expect(
        notifier.state.isModuleCompleted('unit_01_m', ModuleType.tracing),
        isTrue,
      );

      // Bonus star awarded once per key
      expect(await notifier.awardBonusStar('syllable_clap:unit_01_m'), isTrue);
      expect(await notifier.awardBonusStar('syllable_clap:unit_01_m'), isFalse);
      expect(notifier.state.bonusStars, 1);

      // Teacher override unlocks Stage 2
      await notifier.toggleStageOverride(2);
      expect(notifier.state.isStageUnlocked(2, curriculum.units), isTrue);

      // Add second child profile and switch
      await notifier.addProfile(name: 'Leo', avatarEmoji: '🦁');
      expect(notifier.state.childName, 'Leo');
      expect(notifier.state.totalStars, 0);
      expect(notifier.state.profiles.length, 2);
    });
  });
}
