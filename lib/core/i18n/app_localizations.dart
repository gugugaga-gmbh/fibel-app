/// Offline multilingual support (i18n) for UI, Parent/Teacher Dashboard,
/// and localized learning reports (`de`, `en`, `tr`, `uk`, `ar`, `es`).
enum AppLanguage {
  de(
    code: 'de',
    ttsLocale: 'de-DE',
    nativeName: 'Deutsch',
    germanName: 'Deutsch',
    flagEmoji: '🇩🇪',
    isRtl: false,
  ),
  en(
    code: 'en',
    ttsLocale: 'en-US',
    nativeName: 'English',
    germanName: 'Englisch',
    flagEmoji: '🇬🇧',
    isRtl: false,
  ),
  tr(
    code: 'tr',
    ttsLocale: 'tr-TR',
    nativeName: 'Türkçe',
    germanName: 'Türkisch',
    flagEmoji: '🇹🇷',
    isRtl: false,
  ),
  uk(
    code: 'uk',
    ttsLocale: 'uk-UA',
    nativeName: 'Українська',
    germanName: 'Ukrainisch',
    flagEmoji: '🇺🇦',
    isRtl: false,
  ),
  ar(
    code: 'ar',
    ttsLocale: 'ar-SA',
    nativeName: 'العربية',
    germanName: 'Arabisch',
    flagEmoji: '🇸🇦',
    isRtl: true,
  ),
  es(
    code: 'es',
    ttsLocale: 'es-ES',
    nativeName: 'Español',
    germanName: 'Spanisch',
    flagEmoji: '🇪🇸',
    isRtl: false,
  );

  final String code;
  final String ttsLocale;
  final String nativeName;
  final String germanName;
  final String flagEmoji;
  final bool isRtl;

  const AppLanguage({
    required this.code,
    required this.ttsLocale,
    required this.nativeName,
    required this.germanName,
    required this.flagEmoji,
    required this.isRtl,
  });

  static AppLanguage fromCode(String? code) {
    if (code == null || code.isEmpty) return AppLanguage.de;
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.de,
    );
  }
}

/// Optional heritage / bridge language (DaZ-Wort-Brücke) per child profile.
enum BridgeLanguage {
  none(
    code: 'none',
    ttsLocale: 'de-DE',
    nativeName: 'Aus (Nur Deutsch)',
    germanName: 'Keine Wort-Brücke',
    flagEmoji: '🇩🇪',
    isRtl: false,
  ),
  en(
    code: 'en',
    ttsLocale: 'en-US',
    nativeName: 'English',
    germanName: 'Englisch',
    flagEmoji: '🇬🇧',
    isRtl: false,
  ),
  tr(
    code: 'tr',
    ttsLocale: 'tr-TR',
    nativeName: 'Türkçe',
    germanName: 'Türkisch',
    flagEmoji: '🇹🇷',
    isRtl: false,
  ),
  uk(
    code: 'uk',
    ttsLocale: 'uk-UA',
    nativeName: 'Українська',
    germanName: 'Ukrainisch',
    flagEmoji: '🇺🇦',
    isRtl: false,
  ),
  ar(
    code: 'ar',
    ttsLocale: 'ar-SA',
    nativeName: 'العربية',
    germanName: 'Arabisch',
    flagEmoji: '🇸🇦',
    isRtl: true,
  ),
  es(
    code: 'es',
    ttsLocale: 'es-ES',
    nativeName: 'Español',
    germanName: 'Spanisch',
    flagEmoji: '🇪🇸',
    isRtl: false,
  );

  final String code;
  final String ttsLocale;
  final String nativeName;
  final String germanName;
  final String flagEmoji;
  final bool isRtl;

  const BridgeLanguage({
    required this.code,
    required this.ttsLocale,
    required this.nativeName,
    required this.germanName,
    required this.flagEmoji,
    required this.isRtl,
  });

  bool get isEnabled => this != BridgeLanguage.none;

  static BridgeLanguage fromCode(String? code) {
    if (code == null || code.isEmpty) return BridgeLanguage.none;
    return BridgeLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => BridgeLanguage.none,
    );
  }
}

class AppLocalizations {
  final AppLanguage language;

  const AppLocalizations([this.language = AppLanguage.de]);

  static AppLocalizations of(AppLanguage lang) => AppLocalizations(lang);

  String tr(String key) {
    final map = _strings[language] ?? _strings[AppLanguage.de]!;
    return map[key] ?? _strings[AppLanguage.de]![key] ?? key;
  }

  String welcomeChild(String name) => switch (language) {
        AppLanguage.de =>
          'Hallo $name! Wähle einen Buchstaben zum Lernen aus.',
        AppLanguage.en =>
          'Hello $name! Pick a letter to start learning German.',
        AppLanguage.tr =>
          'Merhaba $name! Öğrenmek için bir harf seç.',
        AppLanguage.uk =>
          'Привіт, $name! Обери літеру для навчання.',
        AppLanguage.ar =>
          'مرحباً $name! اختر حرفاً للتعلم.',
        AppLanguage.es =>
          '¡Hola $name! Elige una letra para aprender.',
      };

  String profileSwitchedGreeting(String name) => switch (language) {
        AppLanguage.de => 'Hallo $name! Schön, dass du da bist!',
        AppLanguage.en => 'Hallo $name! Schön, dass du da bist!',
        AppLanguage.tr => 'Hallo $name! Schön, dass du da bist!',
        AppLanguage.uk => 'Hallo $name! Schön, dass du da bist!',
        AppLanguage.ar => 'Hallo $name! Schön, dass du da bist!',
        AppLanguage.es => 'Hallo $name! Schön, dass du da bist!',
      };

  static const Map<AppLanguage, Map<String, String>> _strings = {
    AppLanguage.de: {
      'who_is_learning': 'Wer lernt gerade?',
      'switch_or_add_profile': 'Tippe auf dein Profilbild zum Starten!',
      'parent_area': 'Eltern- & Lehrkräftebereich',
      'child_profiles': 'Kinder-Profile',
      'new_profile': 'Neues Profil',
      'edit_profile': 'Profil bearbeiten',
      'class_comparison': 'Geschwister- & Klassen-Übersicht',
      'language_and_daz': 'Sprache & DaZ-Wort-Brücke',
      'parent_language_label': 'Sprache für Elternbereich & Lernbericht:',
      'bridge_language_label': 'DaZ-Wort-Brücke (Übersetzungshilfe für Kinder):',
      'bridge_language_hint':
          'Zeigt neben deutschen Wörtern die Bedeutung in der Herkunftssprache des Kindes an und liest sie auf Wunsch vor.',
      'emoji_pin_label': 'Kindersicherung: 2-Emoji-Schlüssel (optional)',
      'emoji_pin_hint':
          'Ideal für Geschwister & Schulklassen: Das Kind tippt beim Profilwechsel seine 2 geheimen Bilder an.',
      'enter_emoji_pin': 'Tippe deine 2 geheimen Bilder an:',
      'wrong_emoji_pin': 'Fast! Versuche deine 2 Bilder noch einmal.',
      'group_label': 'Gruppe / Klasse (optional, z. B. Klasse 1a)',
      'favorite_color': 'Lieblingsfarbe für Profil-Karte:',
      'export_single_profile': 'Aktives Profil exportieren',
      'import_merge_profile': 'Profil hinzufügen (Merge-Import)',
      'weekly_activity': 'Aktivität der letzten 7 Tage',
      'report_header': '=== FIPS & FINA – LERNBERICHT & LESE-PASS ===',
      'report_child': 'Kind',
      'report_group': 'Gruppe/Klasse',
      'report_stars': 'Sterne gesamt',
      'report_bonus': 'davon Bonus-Sterne',
      'report_daily': 'Tagesziel',
      'report_streak': 'Lernserie',
      'report_days': 'Tage',
      'report_competencies': '--- KOMPETENZBEREICHE ---',
      'report_mod_phonics': '1. Laute hören (Anlaut-Zug)',
      'report_mod_tracing': '2. Schreiben (Linienhaus)',
      'report_mod_syllables': '3. Silben schwingen',
      'report_mod_reading': '4. Wörter & Sätze lesen',
      'report_mod_stories': '5. Lesepass-Geschichten',
      'report_stages': '--- STUFEN-FORTSCHRITT & URKUNDEN ---',
      'report_stage': 'Stufe',
      'report_cert_earned': '🏆 Urkunde erreicht',
      'report_cert_in_progress': '⏳ In Arbeit',
      'report_review_rec': 'Übungs-Empfehlung (Laute)',
    },
    AppLanguage.en: {
      'who_is_learning': 'Who is learning right now?',
      'switch_or_add_profile': 'Tap your profile card to start!',
      'parent_area': 'Parents & Teachers Area',
      'child_profiles': 'Child Profiles',
      'new_profile': 'New Profile',
      'edit_profile': 'Edit Profile',
      'class_comparison': 'Siblings & Classroom Overview',
      'language_and_daz': 'Language & Word Bridge (DaZ)',
      'parent_language_label': 'Parent Dashboard & Report Language:',
      'bridge_language_label': 'Word Bridge (Translation helper for children):',
      'bridge_language_hint':
          'Displays and speaks a translation helper next to German words while keeping all phonics and syllable exercises in German.',
      'emoji_pin_label': 'Child Lock: 2-Emoji Secret Key (optional)',
      'emoji_pin_hint':
          'Great for classrooms & siblings: The child taps their 2 secret emojis when switching profiles.',
      'enter_emoji_pin': 'Tap your 2 secret pictures:',
      'wrong_emoji_pin': 'Almost! Try your 2 pictures again.',
      'group_label': 'Group / Class (optional, e.g. Class 1a)',
      'favorite_color': 'Favorite Profile Color:',
      'export_single_profile': 'Export Active Profile',
      'import_merge_profile': 'Add Profile (Merge Import)',
      'weekly_activity': 'Last 7 Days Activity',
      'report_header': '=== FIPS & FINA – LEARNING REPORT & READING PASS ===',
      'report_child': 'Child',
      'report_group': 'Group/Class',
      'report_stars': 'Total Stars',
      'report_bonus': 'Bonus Stars',
      'report_daily': 'Daily Goal',
      'report_streak': 'Streak',
      'report_days': 'days',
      'report_competencies': '--- COMPETENCY AREAS ---',
      'report_mod_phonics': '1. Phonics (Sound Train)',
      'report_mod_tracing': '2. Letter Tracing & Writing',
      'report_mod_syllables': '3. Syllables & Clapping',
      'report_mod_reading': '4. Words & Sentences Reading',
      'report_mod_stories': '5. Reading Pass Stories',
      'report_stages': '--- STAGE PROGRESS & CERTIFICATES ---',
      'report_stage': 'Stage',
      'report_cert_earned': '🏆 Certificate earned',
      'report_cert_in_progress': '⏳ In progress',
      'report_review_rec': 'Recommended for review (Sounds)',
    },
    AppLanguage.tr: {
      'who_is_learning': 'Şimdi kim öğreniyor?',
      'switch_or_add_profile': 'Başlamak için profiline dokun!',
      'parent_area': 'Ebeveyn ve Öğretmen Alanı',
      'child_profiles': 'Çocuk Profilleri',
      'new_profile': 'Yeni Profil',
      'edit_profile': 'Profili Düzenle',
      'class_comparison': 'Kardeş ve Sınıf Özeti',
      'language_and_daz': 'Dil ve Kelime Köprüsü (DaZ)',
      'parent_language_label': 'Ebeveyn Alanı ve Rapor Dili:',
      'bridge_language_label': 'Kelime Köprüsü (Çocuklar için çeviri yardımı):',
      'bridge_language_hint':
          'Almanca kelimelerin yanında çocuğun ana dilindeki anlamını gösterir ve seslendirir.',
      'emoji_pin_label': 'Çocuk Kilidi: 2 Emoji Anahtarı (isteğe bağlı)',
      'emoji_pin_hint':
          'Sınıflar ve kardeşler için idealdir: Çocuk profilini açarken 2 gizli resmi seçer.',
      'enter_emoji_pin': '2 gizli resmine dokun:',
      'wrong_emoji_pin': 'Tekrar dene! 2 gizli resmini seç.',
      'group_label': 'Grup / Sınıf (örn. 1a Sınıfı)',
      'favorite_color': 'Favori Profil Rengi:',
      'export_single_profile': 'Aktif Profili Dışa Aktar',
      'import_merge_profile': 'Profil Ekle (Birleştir)',
      'weekly_activity': 'Son 7 Günlük Etkinlik',
      'report_header': '=== FIPS & FINA – ÖĞRENME RAPORU ===',
      'report_child': 'Çocuk',
      'report_group': 'Grup/Sınıf',
      'report_stars': 'Toplam Yıldız',
      'report_bonus': 'Bonus Yıldız',
      'report_daily': 'Günlük Hedef',
      'report_streak': 'Seri',
      'report_days': 'gün',
      'report_competencies': '--- YETKİNLİK ALANLARI ---',
      'report_mod_phonics': '1. Sesleri Duyma (Ses Treni)',
      'report_mod_tracing': '2. Harf Yazma (Çizgi Evi)',
      'report_mod_syllables': '3. Hece Çalışması',
      'report_mod_reading': '4. Kelime ve Cümle Okuma',
      'report_mod_stories': '5. Okuma Pasaportu Hikayeleri',
      'report_stages': '--- SEVİYE İLERLEMESİ VE SERTİFİKALAR ---',
      'report_stage': 'Seviye',
      'report_cert_earned': '🏆 Sertifika kazanıldı',
      'report_cert_in_progress': '⏳ Devam ediyor',
      'report_review_rec': 'Tekrar Önerisi (Harfler)',
    },
    AppLanguage.uk: {
      'who_is_learning': 'Хто зараз навчається?',
      'switch_or_add_profile': 'Натисни на свій профіль, щоб почати!',
      'parent_area': 'Розділ для батьків та вчителів',
      'child_profiles': 'Профілі дітей',
      'new_profile': 'Новий профіль',
      'edit_profile': 'Редагувати профіль',
      'class_comparison': 'Огляд дітей та класу',
      'language_and_daz': 'Мова та Мовний місток (DaZ)',
      'parent_language_label': 'Мова для батьків та звіту:',
      'bridge_language_label': 'Мовний місток (переклад слів для дитини):',
      'bridge_language_hint':
          'Показує та озвучує переклад німецьких слів рідною мовою дитини.',
      'emoji_pin_label': 'Ключ із 2 емодзі (необов’язково)',
      'emoji_pin_hint':
          'Зручно для школи та родини: дитина обирає 2 секретні картинки для входу.',
      'enter_emoji_pin': 'Натисни свої 2 секретні картинки:',
      'wrong_emoji_pin': 'Спробуй ще раз обрати 2 картинки.',
      'group_label': 'Група / Клас (напр. 1-А клас)',
      'favorite_color': 'Улюблений колір профілю:',
      'export_single_profile': 'Експортувати активний профіль',
      'import_merge_profile': 'Додати профіль (Імпорт)',
      'weekly_activity': 'Активність за останні 7 днів',
      'report_header': '=== FIPS & FINA – ЗВІТ ПРО НАВЧАННЯ ===',
      'report_child': 'Дитина',
      'report_group': 'Група/Клас',
      'report_stars': 'Усього зірок',
      'report_bonus': 'бонусних зірок',
      'report_daily': 'Денна ціль',
      'report_streak': 'Серія',
      'report_days': 'днів',
      'report_competencies': '--- НАВИЧКИ ---',
      'report_mod_phonics': '1. Слухання звуків',
      'report_mod_tracing': '2. Письмо літер',
      'report_mod_syllables': '3. Склади',
      'report_mod_reading': '4. Читання слів і речень',
      'report_mod_stories': '5. Історії для читання',
      'report_stages': '--- ПРОГРЕС ЗА РІВНЯМИ ---',
      'report_stage': 'Рівень',
      'report_cert_earned': '🏆 Сертифікат отримано',
      'report_cert_in_progress': '⏳ У процесі',
      'report_review_rec': 'Рекомендовано повторити (Звуки)',
    },
    AppLanguage.ar: {
      'who_is_learning': 'من يتعلم الآن؟',
      'switch_or_add_profile': 'اضغط على ملفك الشخصي للبدء!',
      'parent_area': 'قسم الوالدين والمعلمين',
      'child_profiles': 'ملفات الأطفال',
      'new_profile': 'ملف جديد',
      'edit_profile': 'تعديل الملف',
      'class_comparison': 'نظرة عامة على الإخوة والفصل',
      'language_and_daz': 'اللغة وجسر الكلمات (DaZ)',
      'parent_language_label': 'لغة قسم الوالدين والتقرير:',
      'bridge_language_label': 'جسر الكلمات (مساعدة الترجمة للطفل):',
      'bridge_language_hint':
          'يعرض وينطق معنى الكلمات الألمانية بلغة الطفل الأم لدعم الفهم.',
      'emoji_pin_label': 'قفل الطفل: مفتاح من رمزين (اختياري)',
      'emoji_pin_hint':
          'مثالي للفصول الدراسية والإخوة: يختار الطفل صورتين سريتين لفتح ملفه.',
      'enter_emoji_pin': 'اضغط على الصورتين السريتين:',
      'wrong_emoji_pin': 'حاول مرة أخرى باختيار الصورتين.',
      'group_label': 'المجموعة / الفصل (مثل الصف 1أ)',
      'favorite_color': 'اللون المفضل للملف:',
      'export_single_profile': 'تصدير الملف الحالي',
      'import_merge_profile': 'إضافة ملف (دمج)',
      'weekly_activity': 'النشاط خلال آخر 7 أيام',
      'report_header': '=== FIPS & FINA – تقرير التعلم ===',
      'report_child': 'الطفل',
      'report_group': 'المجموعة/الفصل',
      'report_stars': 'إجمالي النجوم',
      'report_bonus': 'نجوم إضافية',
      'report_daily': 'الهدف اليومي',
      'report_streak': 'سلسلة الأيام',
      'report_days': 'أيام',
      'report_competencies': '--- مجالات الكفاءة ---',
      'report_mod_phonics': '1. سماع الأصوات',
      'report_mod_tracing': '2. كتابة الحروف',
      'report_mod_syllables': '3. المقاطع الصوتية',
      'report_mod_reading': '4. قراءة الكلمات والجمل',
      'report_mod_stories': '5. قصص القراءة',
      'report_stages': '--- تقدم المراحل والشهادات ---',
      'report_stage': 'المرحلة',
      'report_cert_earned': '🏆 تم الحصول على الشهادة',
      'report_cert_in_progress': '⏳ قيد العمل',
      'report_review_rec': 'توصية للمراجعة (الحروف)',
    },
    AppLanguage.es: {
      'who_is_learning': '¿Quién aprende ahora?',
      'switch_or_add_profile': '¡Toca tu perfil para empezar!',
      'parent_area': 'Área de Padres y Maestros',
      'child_profiles': 'Perfiles de Niños',
      'new_profile': 'Nuevo Perfil',
      'edit_profile': 'Editar Perfil',
      'class_comparison': 'Resumen de Hermanos y Clase',
      'language_and_daz': 'Idioma y Puente de Palabras (DaZ)',
      'parent_language_label': 'Idioma para Padres e Informe:',
      'bridge_language_label': 'Puente de Palabras (Ayuda de traducción):',
      'bridge_language_hint':
          'Muestra y pronuncia el significado de las palabras alemanas en el idioma familiar del niño.',
      'emoji_pin_label': 'Clave infantil de 2 Emojis (opcional)',
      'emoji_pin_hint':
          'Ideal para clases y hermanos: El niño toca sus 2 dibujos secretos al cambiar de perfil.',
      'enter_emoji_pin': 'Toca tus 2 dibujos secretos:',
      'wrong_emoji_pin': '¡Casi! Intenta tus 2 dibujos otra vez.',
      'group_label': 'Grupo / Clase (ej. Clase 1a)',
      'favorite_color': 'Color favorito del perfil:',
      'export_single_profile': 'Exportar perfil activo',
      'import_merge_profile': 'Añadir perfil (Importar)',
      'weekly_activity': 'Actividad de los últimos 7 días',
      'report_header': '=== FIPS & FINA – INFORME DE APRENDIZAJE ===',
      'report_child': 'Niño/a',
      'report_group': 'Grupo/Clase',
      'report_stars': 'Estrellas totales',
      'report_bonus': 'Estrellas extra',
      'report_daily': 'Meta diaria',
      'report_streak': 'Racha',
      'report_days': 'días',
      'report_competencies': '--- ÁREAS DE COMPETENCIA ---',
      'report_mod_phonics': '1. Escuchar sonidos',
      'report_mod_tracing': '2. Trazar y escribir letras',
      'report_mod_syllables': '3. Sílabas y palmadas',
      'report_mod_reading': '4. Leer palabras y frases',
      'report_mod_stories': '5. Cuentos del pasaporte lector',
      'report_stages': '--- PROGRESO DE ETAPAS Y DIPLOMAS ---',
      'report_stage': 'Etapa',
      'report_cert_earned': '🏆 Diploma obtenido',
      'report_cert_in_progress': '⏳ En progreso',
      'report_review_rec': 'Recomendación de repaso (Sonidos)',
    },
  };
}
