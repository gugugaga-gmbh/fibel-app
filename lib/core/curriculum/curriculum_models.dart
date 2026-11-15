import 'dart:ui';

enum SoundPosition { start, middle, end }

class AnlautEntry {
  final String letter;
  final String lowercase;
  final String word;
  final String emoji;
  final String phoneme;

  const AnlautEntry({
    required this.letter,
    required this.lowercase,
    required this.word,
    required this.emoji,
    required this.phoneme,
  });

  factory AnlautEntry.fromJson(Map<String, dynamic> json) {
    return AnlautEntry(
      letter: json['letter'] as String,
      lowercase: json['lowercase'] as String,
      word: json['word'] as String,
      emoji: json['emoji'] as String,
      phoneme: json['phoneme'] as String,
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

  const SentenceItem({
    required this.text,
    required this.words,
  });

  factory SentenceItem.fromJson(Map<String, dynamic> json) {
    return SentenceItem(
      text: json['text'] as String,
      words: (json['words'] as List<dynamic>)
          .map((e) => SyllableWord.fromJson(e as Map<String, dynamic>))
          .toList(),
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
  final String letter;
  final String lowercase;
  final String phoneme;
  final String anchorWord;
  final String anchorEmoji;
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
    required this.letter,
    required this.lowercase,
    required this.phoneme,
    required this.anchorWord,
    required this.anchorEmoji,
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

  factory LessonUnit.fromJson(Map<String, dynamic> json) {
    return LessonUnit(
      id: json['id'] as String,
      order: (json['order'] as num).toInt(),
      letter: json['letter'] as String,
      lowercase: json['lowercase'] as String,
      phoneme: json['phoneme'] as String,
      anchorWord: json['anchorWord'] as String,
      anchorEmoji: json['anchorEmoji'] as String,
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

  const StickerItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.requiredStars,
  });

  factory StickerItem.fromJson(Map<String, dynamic> json) {
    return StickerItem(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      requiredStars: (json['requiredStars'] as num).toInt(),
    );
  }
}

class CurriculumData {
  final String version;
  final List<AnlautEntry> anlautTable;
  final List<LessonUnit> units;
  final List<StickerItem> stickers;

  const CurriculumData({
    required this.version,
    required this.anlautTable,
    required this.units,
    required this.stickers,
  });

  factory CurriculumData.fromJson(Map<String, dynamic> json) {
    final units = (json['units'] as List<dynamic>)
        .map((e) => LessonUnit.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return CurriculumData(
      version: json['version'] as String,
      anlautTable: (json['anlautTable'] as List<dynamic>)
          .map((e) => AnlautEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      units: units,
      stickers: (json['stickers'] as List<dynamic>)
          .map((e) => StickerItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
