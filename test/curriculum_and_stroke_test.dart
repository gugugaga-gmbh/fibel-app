import 'package:fibel_app/core/audio/audio_service.dart';
import 'package:fibel_app/core/curriculum/curriculum_models.dart';
import 'package:fibel_app/core/curriculum/curriculum_repository.dart';
import 'package:fibel_app/core/i18n/app_localizations.dart';
import 'package:fibel_app/core/i18n/daz_word_bridge.dart';
import 'package:fibel_app/core/storage/progress_repository.dart';
import 'package:fibel_app/features/writing/stroke_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurriculumRepository', () {
    test(
        'loads curriculum_de.json with 33 units across 4 stages, 37 anlaute, 24 stickers, 4 stage stories and 8 rhyme pairs',
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
      expect(data.stickers.length, 24);
      expect(data.stageStories.length, 4);
      expect(data.rhymePairs.length, 8);

      for (final stage in [1, 2, 3, 4]) {
        final story = data.storyForStage(stage);
        expect(story, isNotNull);
        expect(story!.sentences.length, greaterThanOrEqualTo(3));
        for (final s in story.sentences) {
          for (final w in s.words) {
            expect(w.syllables.join(), w.fullWord);
          }
        }
        expect(data.rhymesForStage(stage), isNotEmpty);
      }

      for (final r in data.rhymePairs) {
        expect(r.targetSyllables.join(), r.targetWord);
        expect(r.matchingSyllables.join(), r.matchingWord);
        expect(r.distractors.length, greaterThanOrEqualTo(2));
      }
    });

    test('SyllableWord.extractVowelKing extracts vowels and diphthongs', () {
      expect(SyllableWord.extractVowelKing('Maus'), 'au');
      expect(SyllableWord.extractVowelKing('Eis'), 'Ei');
      expect(SyllableWord.extractVowelKing('Son'), 'o');
      expect(SyllableWord.extractVowelKing('Tie'), 'ie');
      expect(SyllableWord.extractVowelKing('Bä'), 'ä');
    });

    test(
        'DazWordBridge covers all curriculum anchor words, practice words and story titles across 5 bridge languages',
        () async {
      final data = await CurriculumRepository().loadCurriculum();
      final bridgeLanguages = [
        BridgeLanguage.en,
        BridgeLanguage.tr,
        BridgeLanguage.uk,
        BridgeLanguage.ar,
        BridgeLanguage.es,
      ];

      expect(DazWordBridge.translate('Maus', BridgeLanguage.none), isNull);
      expect(DazWordBridge.coveredWordCount, greaterThanOrEqualTo(136));

      for (final lang in bridgeLanguages) {
        for (final unit in data.units) {
          expect(
            DazWordBridge.translate(unit.anchorWord, lang),
            isNotNull,
            reason: 'Missing ${lang.code} translation for ${unit.anchorWord}',
          );
          for (final w in unit.words) {
            expect(
              DazWordBridge.translate(w.fullWord, lang),
              isNotNull,
              reason: 'Missing ${lang.code} translation for ${w.fullWord}',
            );
          }
        }
        for (final story in data.stageStories) {
          expect(
            DazWordBridge.translate(story.title, lang),
            isNotNull,
            reason: 'Missing ${lang.code} translation for story ${story.title}',
          );
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

      // Stage story completion awards +2 bonus stars once and unlocks stage certificate
      expect(
        notifier.state.isStageCertificateEarned(1, curriculum.units),
        isFalse,
      );
      expect(await notifier.completeStageStory(1), isTrue);
      expect(await notifier.completeStageStory(1), isFalse);
      expect(notifier.state.isStageStoryCompleted(1), isTrue);
      expect(
        notifier.state.isStageCertificateEarned(1, curriculum.units),
        isTrue,
      );

      // Customizable daily goal target & accessibility settings
      await notifier.updateDailyGoalTarget(5);
      expect(notifier.state.dailyGoalTarget, 5);
      await notifier.updateSettings(
        notifier.state.settings.copyWith(
          highContrastMode: true,
          largeTextMode: true,
        ),
      );
      expect(notifier.state.settings.highContrastMode, isTrue);
      expect(notifier.state.settings.textScaleFactor, 1.15);

      // Offline parent & teacher learning report (German default + localized)
      final report = notifier.state.generateParentReport(curriculum);
      expect(report, contains('FIPS & FINA – LERNBERICHT'));
      expect(report, contains('🏆 Urkunde erreicht'));

      final reportEn = notifier.state.generateParentReport(
        curriculum,
        language: AppLanguage.en,
      );
      expect(reportEn, contains('LEARNING REPORT'));
      expect(reportEn, contains('🏆 Certificate earned'));

      final reportTr = notifier.state.generateParentReport(
        curriculum,
        language: AppLanguage.tr,
      );
      expect(reportTr, contains('ÖĞRENME RAPORU'));

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

    test(
        'supports per-child settings, 2-emoji child lock, group filtering and single-profile merge import',
        () async {
      SharedPreferences.setMockInitialValues({});
      final repo = ProgressRepository();
      final notifier = ProgressNotifier(repo);

      // Configure first child with Turkish bridge language and Class 1a
      await notifier.updateActiveProfile(
        name: 'Aylin',
        avatarEmoji: '🦄',
        themeColorHex: '#7E57C2',
        groupName: 'Klasse 1a',
        emojiPin: '🍎🚗',
        profileBridgeLanguage: BridgeLanguage.tr,
        profileLeftHandedMode: false,
      );

      expect(notifier.state.effectiveBridgeLanguage, BridgeLanguage.tr);
      expect(notifier.state.effectiveSettings.leftHandedMode, isFalse);
      expect(
        notifier.verifyEmojiPin(notifier.state.activeProfileId, '🍎⚽'),
        isFalse,
      );
      expect(
        notifier.verifyEmojiPin(notifier.state.activeProfileId, '🍎🚗'),
        isTrue,
      );

      // Export single profile for Aylin
      final aylinJson = notifier.exportActiveProfileJson();

      // Add second child with Ukrainian bridge language and left-handed mode
      await notifier.addProfile(
        name: 'Taras',
        avatarEmoji: '🦁',
        themeColorHex: '#00897B',
        groupName: 'Klasse 1b',
        profileBridgeLanguage: BridgeLanguage.uk,
        profileLeftHandedMode: true,
      );

      expect(notifier.state.profiles.length, 2);
      expect(notifier.state.effectiveBridgeLanguage, BridgeLanguage.uk);
      expect(notifier.state.effectiveSettings.leftHandedMode, isTrue);
      expect(notifier.state.availableGroups, ['Klasse 1a', 'Klasse 1b']);

      // Merge-import Aylin into a fresh instance that only has a default child
      SharedPreferences.setMockInitialValues({});
      final repo2 = ProgressRepository();
      final notifier2 = ProgressNotifier(repo2);
      await notifier2.updateChildName('Noah');
      expect(notifier2.state.profiles.length, 1);

      expect(await notifier2.importAndMergeProfileJson(aylinJson), isTrue);
      expect(notifier2.state.profiles.length, 2);
      expect(notifier2.state.childName, 'Aylin');
      expect(notifier2.state.effectiveBridgeLanguage, BridgeLanguage.tr);
    });
  });
}
