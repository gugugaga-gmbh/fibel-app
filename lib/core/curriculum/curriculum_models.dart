import 'dart:ui';

enum SoundPosition { start, middle, end }

enum AnlautCategory { vowel, consonant, digraph }

class AnlautEntry {
  final String letter;
  final String lowercase;
  final String word;
  final String emoji;
  final String phoneme;
  final bool isVowel;
  final AnlautCategory category;

  const AnlautEntry({
    required this.letter,
    required this.lowercase,
    required this.word,
    required this.emoji,
    required this.phoneme,
    this.isVowel = false,
    this.category = AnlautCategory.consonant,
  });

  factory AnlautEntry.fromJson(Map<String, dynamic> json) {
    final letter = json['letter'] as String;
    final catStr = json['category'] as String?;
    final defaultVowel = const {
      'A',
      'E',
      'I',
      'O',
      'U',
      'Ä',
      'Ö',
      'Ü',
      'Ei',
      'Au',
      'Eu',
    }.contains(letter);
    final isVowel = (json['isVowel'] as bool?) ?? defaultVowel;
    final category = switch (catStr) {
      'vowel' => AnlautCategory.vowel,
      'digraph' => AnlautCategory.digraph,
      'consonant' => AnlautCategory.consonant,
      _ => letter.length > 1
          ? AnlautCategory.digraph
          : (isVowel ? AnlautCategory.vowel : AnlautCategory.consonant),
    };

    return AnlautEntry(
      letter: letter,
      lowercase: json['lowercase'] as String,
      word: json['word'] as String,
      emoji: json['emoji'] as String,
      phoneme: json['phoneme'] as String,
      isVowel: isVowel,
      category: category,
    );
  }
}

class SyllableWord {
  final String fullWord;
  final List<String> syllables;
  final String emoji;

  const SyllableWord({
    required this.fullWord,
    required this.syllables,
    this.emoji = '',
  });

  /// Returns true if the syllable contains a German vowel (Silbenkönig).
  static bool containsVowel(String syllable) {
    return RegExp(r'[aeiouäöüyAEIOUÄÖÜY]').hasMatch(syllable);
  }

  /// Extracts the primary vowel or diphthong (Silbenkönig) of a German syllable.
  static String extractVowelKing(String syllable) {
    final lower = syllable.toLowerCase();
    for (final diphthong in const ['ei', 'au', 'eu', 'äu', 'ie']) {
      final idx = lower.indexOf(diphthong);
      if (idx >= 0) {
        return syllable.substring(idx, idx + diphthong.length);
      }
    }
    final match = RegExp(r'[aeiouäöüyAEIOUÄÖÜY]+').firstMatch(syllable);
    return match?.group(0) ?? '';
  }

  factory SyllableWord.fromJson(Map<String, dynamic> json) {
    return SyllableWord(
      fullWord: json['fullWord'] as String,
      syllables: (json['syllables'] as List<dynamic>).cast<String>(),
      emoji: (json['emoji'] as String?) ?? '',
    );
  }
}

class SentenceItem {
  final String text;
  final List<SyllableWord> words;
  final String emoji;
  final List<String> distractorEmojis;

  const SentenceItem({
    required this.text,
    required this.words,
    this.emoji = '📖',
    this.distractorEmojis = const ['🎈', '⚽'],
  });

  factory SentenceItem.fromJson(Map<String, dynamic> json) {
    return SentenceItem(
      text: json['text'] as String,
      words: (json['words'] as List<dynamic>)
          .map((e) => SyllableWord.fromJson(e as Map<String, dynamic>))
          .toList(),
      emoji: (json['emoji'] as String?) ?? '📖',
      distractorEmojis: (json['distractorEmojis'] as List<dynamic>?)
              ?.cast<String>() ??
          const ['🎈', '⚽'],
    );
  }
}

class SoundQuizItem {
  final String word;
  final String emoji;
  final SoundPosition position;

  const SoundQuizItem({
    required this.word,
    required this.emoji,
    required this.position,
  });

  factory SoundQuizItem.fromJson(Map<String, dynamic> json) {
    final posStr = json['position'] as String;
    final position = switch (posStr) {
      'start' => SoundPosition.start,
      'middle' => SoundPosition.middle,
      'end' => SoundPosition.end,
      _ => SoundPosition.start,
    };
    return SoundQuizItem(
      word: json['word'] as String,
      emoji: json['emoji'] as String,
      position: position,
    );
  }
}

class LessonUnit {
  final String id;
  final int order;
  final int stage;
  final String letter;
  final String lowercase;
  final String phoneme;
  final String anchorWord;
  final String anchorEmoji;
  final bool isVowel;
  final Color color;
  final List<List<Offset>> upperStrokes;
  final List<List<Offset>> lowerStrokes;
  final List<String> syllableCombos;
  final List<SoundQuizItem> soundQuiz;
  final List<SyllableWord> words;
  final List<SentenceItem> sentences;

  const LessonUnit({
    required this.id,
    required this.order,
    required this.stage,
    required this.letter,
    required this.lowercase,
    required this.phoneme,
    required this.anchorWord,
    required this.anchorEmoji,
    this.isVowel = false,
    required this.color,
    required this.upperStrokes,
    required this.lowerStrokes,
    required this.syllableCombos,
    required this.soundQuiz,
    required this.words,
    required this.sentences,
  });

  static List<List<Offset>> _parseStrokes(List<dynamic> raw) {
    return raw.map((stroke) {
      return (stroke as List<dynamic>).map((pt) {
        final pair = pt as List<dynamic>;
        return Offset(
          (pair[0] as num).toDouble(),
          (pair[1] as num).toDouble(),
        );
      }).toList();
    }).toList();
  }

  static Color _parseColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    final value = int.tryParse('FF$clean', radix: 16) ?? 0xFF1E88E5;
    return Color(value);
  }

  static int _defaultStageForOrder(int order) {
    if (order <= 7) return 1;
    if (order <= 19) return 2;
    if (order <= 26) return 3;
    if (order <= 33) return 4;
    return 5;
  }

  factory LessonUnit.fromJson(Map<String, dynamic> json) {
    final order = (json['order'] as num).toInt();
    final letter = json['letter'] as String;
    final defaultVowel = const {
      'A',
      'E',
      'I',
      'O',
      'U',
      'Ä',
      'Ö',
      'Ü',
      'Ei',
      'Au',
      'Eu',
      'Ie',
    }.contains(letter);

    return LessonUnit(
      id: json['id'] as String,
      order: order,
      stage: (json['stage'] as num?)?.toInt() ?? _defaultStageForOrder(order),
      letter: letter,
      lowercase: json['lowercase'] as String,
      phoneme: json['phoneme'] as String,
      anchorWord: json['anchorWord'] as String,
      anchorEmoji: json['anchorEmoji'] as String,
      isVowel: (json['isVowel'] as bool?) ?? defaultVowel,
      color: _parseColor(json['colorHex'] as String),
      upperStrokes: _parseStrokes(json['upperStrokes'] as List<dynamic>),
      lowerStrokes: _parseStrokes(json['lowerStrokes'] as List<dynamic>),
      syllableCombos: (json['syllableCombos'] as List<dynamic>).cast<String>(),
      soundQuiz: (json['soundQuiz'] as List<dynamic>)
          .map((e) => SoundQuizItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      words: (json['words'] as List<dynamic>)
          .map((e) => SyllableWord.fromJson(e as Map<String, dynamic>))
          .toList(),
      sentences: (json['sentences'] as List<dynamic>)
          .map((e) => SentenceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StickerItem {
  final String id;
  final String name;
  final String emoji;
  final int requiredStars;
  final String category;
  final String voiceText;

  const StickerItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.requiredStars,
    this.category = 'Waldfreunde',
    this.voiceText = '',
  });

  factory StickerItem.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    return StickerItem(
      id: json['id'] as String,
      name: name,
      emoji: json['emoji'] as String,
      requiredStars: (json['requiredStars'] as num).toInt(),
      category: (json['category'] as String?) ?? 'Waldfreunde',
      voiceText: (json['voiceText'] as String?) ?? 'Toll! Dein Sticker: $name!',
    );
  }
}

class StoryChoice {
  final String emoji;
  final String text;

  const StoryChoice({
    required this.emoji,
    required this.text,
  });

  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      emoji: (json['emoji'] as String?) ?? '📖',
      text: (json['text'] as String?) ?? '',
    );
  }
}

class StageStory {
  final String id;
  final int stage;
  final String title;
  final String emoji;
  final List<SentenceItem> sentences;
  final String question;
  final String answerEmoji;
  final String answerText;
  final List<StoryChoice> distractorOptions;

  const StageStory({
    required this.id,
    required this.stage,
    required this.title,
    required this.emoji,
    required this.sentences,
    required this.question,
    required this.answerEmoji,
    required this.answerText,
    this.distractorOptions = const [],
  });

  factory StageStory.fromJson(Map<String, dynamic> json) {
    return StageStory(
      id: json['id'] as String,
      stage: (json['stage'] as num).toInt(),
      title: json['title'] as String,
      emoji: (json['emoji'] as String?) ?? '📖',
      sentences: (json['sentences'] as List<dynamic>)
          .map((e) => SentenceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      question: (json['question'] as String?) ?? '',
      answerEmoji: (json['answerEmoji'] as String?) ?? '⭐',
      answerText: (json['answerText'] as String?) ?? '',
      distractorOptions: ((json['distractorOptions'] as List<dynamic>?) ?? [])
          .map((e) => StoryChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RhymePairItem {
  final String id;
  final int stage;
  final String targetWord;
  final List<String> targetSyllables;
  final String targetEmoji;
  final String matchingWord;
  final List<String> matchingSyllables;
  final String matchingEmoji;
  final bool isMinimalPair;
  final List<StoryChoice> distractors;

  const RhymePairItem({
    required this.id,
    required this.stage,
    required this.targetWord,
    required this.targetSyllables,
    required this.targetEmoji,
    required this.matchingWord,
    required this.matchingSyllables,
    required this.matchingEmoji,
    this.isMinimalPair = false,
    this.distractors = const [],
  });

  factory RhymePairItem.fromJson(Map<String, dynamic> json) {
    final targetWord = json['targetWord'] as String;
    final matchingWord = json['matchingWord'] as String;
    return RhymePairItem(
      id: json['id'] as String,
      stage: (json['stage'] as num?)?.toInt() ?? 1,
      targetWord: targetWord,
      targetSyllables: ((json['targetSyllables'] as List<dynamic>?) ??
              [targetWord])
          .cast<String>(),
      targetEmoji: (json['targetEmoji'] as String?) ?? '🎵',
      matchingWord: matchingWord,
      matchingSyllables: ((json['matchingSyllables'] as List<dynamic>?) ??
              [matchingWord])
          .cast<String>(),
      matchingEmoji: (json['matchingEmoji'] as String?) ?? '⭐',
      isMinimalPair: (json['isMinimalPair'] as bool?) ?? false,
      distractors: ((json['distractors'] as List<dynamic>?) ?? [])
          .map((e) => StoryChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CurriculumData {
  final String version;
  final List<AnlautEntry> anlautTable;
  final List<LessonUnit> units;
  final List<StickerItem> stickers;
  final List<StageStory> stageStories;
  final List<RhymePairItem> rhymePairs;

  const CurriculumData({
    required this.version,
    required this.anlautTable,
    required this.units,
    required this.stickers,
    this.stageStories = const [],
    this.rhymePairs = const [],
  });

  /// Sorted list of distinct curriculum stages (e.g., `[1, 2, 3, 4, 5]`).
  List<int> get stages {
    final set = units.map((u) => u.stage).toSet().toList()..sort();
    return set.isEmpty ? const [1, 2, 3, 4, 5] : set;
  }

  List<LessonUnit> unitsForStage(int stage) {
    return units.where((u) => u.stage == stage).toList();
  }

  StageStory? storyForStage(int stage) {
    for (final s in stageStories) {
      if (s.stage == stage) return s;
    }
    return null;
  }

  List<RhymePairItem> rhymesForStage(int stage) {
    return rhymePairs.where((r) => r.stage == stage).toList();
  }

  factory CurriculumData.fromJson(Map<String, dynamic> json) {
    final units = (json['units'] as List<dynamic>)
        .map((e) => LessonUnit.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final rawStories = (json['stageStories'] as List<dynamic>?) ?? const [];
    final rawRhymes = (json['rhymePairs'] as List<dynamic>?) ?? const [];

    return CurriculumData(
      version: json['version'] as String,
      anlautTable: (json['anlautTable'] as List<dynamic>)
          .map((e) => AnlautEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      units: units,
      stickers: (json['stickers'] as List<dynamic>)
          .map((e) => StickerItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      stageStories: rawStories
          .map((e) => StageStory.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.stage.compareTo(b.stage)),
      rhymePairs: rawRhymes
          .map((e) => RhymePairItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
