import 'package:fibel_app/core/audio/audio_service.dart';
import 'package:fibel_app/core/curriculum/curriculum_repository.dart';
import 'package:fibel_app/core/storage/progress_repository.dart';
import 'package:fibel_app/features/writing/stroke_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurriculumRepository', () {
    test(
        'loads curriculum_de.json with 33 units across 4 stages, 37 anlaute, 20 stickers and 4 stage stories',
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
      expect(data.stickers.length, 20);
      expect(data.stageStories.length, 4);

      for (final stage in [1, 2, 3, 4]) {
        final story = data.storyForStage(stage);
        expect(story, isNotNull);
        expect(story!.sentences.length, greaterThanOrEqualTo(3));
        for (final s in story.sentences) {
          for (final w in s.words) {
            expect(w.syllables.join(), w.fullWord);
          }
        }
      }
    });
  });

  group('AudioService', () {
    test('normalizes single consonants and phrases to phonetic articulation',
        () {
      expect(AudioService.normalizePhonemeForSpeech('B'), 'bə');
      expect(AudioService.normalizePhonemeForSpeech('Z'), 'ts');
      expect(
        AudioService.normalizePhonemeForSpeech('Mmm. Wie Maus'),
        'mmm. Wie Maus',
      );
    });

    test('builds valid RIFF WAV buffer for offline chimes', () {
      final wav = AudioService.buildChimeWav(
        frequencies: const [523.25, 659.25],
        noteDurationMs: 50,
      );
      expect(wav.length, greaterThan(44));
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
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

    test(
        'supports multi-child profiles, 3-step tracing, bonus stars, stage lock modes, adaptive mistakes and JSON backup',
        () async {
      SharedPreferences.setMockInitialValues({});
      final repo = ProgressRepository();
      final notifier = ProgressNotifier(repo);
      final curriculum = await CurriculumRepository().loadCurriculum();

      // Stage 1 is unlocked, Stage 2 is locked by 70% calculation initially
      expect(notifier.state.isStageUnlocked(1, curriculum.units), isTrue);
      expect(notifier.state.isStageUnlocked(2, curriculum.units), isFalse);

      // By default (strictStageLock == false), all stages are accessible with soft recommendation
      expect(notifier.state.isStageAccessible(2, curriculum.units), isTrue);

      // Enabling strictStageLock enforces 70% lock
      await notifier.updateSettings(
        notifier.state.settings
            .copyWith(strictStageLock: true, leftHandedMode: true),
      );
      expect(notifier.state.isStageAccessible(2, curriculum.units), isFalse);
      expect(notifier.state.settings.leftHandedMode, isTrue);

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

      // Adaptive mistake tracking & resolution
      await notifier.recordMistake('unit_02_a');
      await notifier.recordMistake('unit_02_a');
      expect(notifier.state.unitsNeedingReview(), contains('unit_02_a'));
      await notifier.completeModule('unit_02_a', ModuleType.phonics);
      expect(notifier.state.mistakeCountsByUnit['unit_02_a'], 1);

      // Stage story completion awards +2 bonus stars once
      expect(await notifier.completeStageStory(1), isTrue);
      expect(await notifier.completeStageStory(1), isFalse);
      expect(notifier.state.isStageStoryCompleted(1), isTrue);

      // Bonus star awarded once per key
      expect(await notifier.awardBonusStar('syllable_clap:unit_01_m'), isTrue);
      expect(await notifier.awardBonusStar('syllable_clap:unit_01_m'), isFalse);

      // Teacher override unlocks Stage 2 even in strict mode
      await notifier.toggleStageOverride(2);
      expect(notifier.state.isStageUnlocked(2, curriculum.units), isTrue);
      expect(notifier.state.isStageAccessible(2, curriculum.units), isTrue);

      // Offline JSON export and import
      final exported = notifier.exportProgressJson();
      await notifier.addProfile(name: 'Leo', avatarEmoji: '🦁');
      expect(notifier.state.profiles.length, 2);

      expect(await notifier.importProgressJson(exported), isTrue);
      expect(notifier.state.profiles.length, 1);
      expect(notifier.state.isStageStoryCompleted(1), isTrue);
    });
  });
}
