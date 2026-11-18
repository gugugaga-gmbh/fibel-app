import 'package:fibel_app/core/i18n/app_localizations.dart';
import 'package:fibel_app/core/i18n/daz_word_bridge.dart';
import 'package:fibel_app/core/storage/progress_repository.dart';
import 'package:fibel_app/core/theme/app_theme.dart';
import 'package:fibel_app/core/widgets/bedtime_pause_overlay.dart';
import 'package:fibel_app/core/widgets/parental_gate_dialog.dart';
import 'package:fibel_app/core/widgets/syllable_text_widget.dart';
import 'package:fibel_app/features/mission/daily_mission_screen.dart';
import 'package:fibel_app/features/parents/parent_dashboard_screen.dart';
import 'package:fibel_app/features/phonics/anlaut_table_screen.dart';
import 'package:fibel_app/features/reading/stage_story_screen.dart';
import 'package:fibel_app/features/rewards/sticker_album_screen.dart';
import 'package:fibel_app/features/writing/anlaut_keyboard_screen.dart';
import 'package:fibel_app/main.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SyllableTextWidget renders alternating blue and red syllables',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyllableTextWidget(
            syllables: ['To', 'ma', 'te'],
          ),
        ),
      ),
    );

    final toText = tester.widget<Text>(find.text('To'));
    final maText = tester.widget<Text>(find.text('ma'));
    final teText = tester.widget<Text>(find.text('te'));

    expect(toText.style?.color, AppColors.syllableBlue);
    expect(maText.style?.color, AppColors.syllableRed);
    expect(teText.style?.color, AppColors.syllableBlue);
  });

  testWidgets('ParentalGateDialog shows math challenge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ParentalGateDialog(),
        ),
      ),
    );

    expect(find.text('Elternbereich'), findsOneWidget);
    expect(find.textContaining('= ?'), findsOneWidget);
  });

  testWidgets('FibelApp loads HomeScreen with units, Abenteuer-Runde and stage chips',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: FibelApp()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fips & Fina – Lese-Welt'), findsOneWidget);
    expect(find.text('Abenteuer-Runde'), findsOneWidget);
    expect(find.text('Anlauttabelle'), findsOneWidget);
    expect(find.text('Werkstatt'), findsOneWidget);
    expect(find.text('Geschichten'), findsOneWidget);
    expect(find.text('Sticker'), findsOneWidget);
    expect(find.text('Stufe 1'), findsOneWidget);
    expect(find.textContaining('Stufe 5'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('Maus'), findsNothing); // rendered as '🐭 Maus'
    expect(find.textContaining('Maus'), findsOneWidget);
  });

  testWidgets(
      'AnlautKeyboardScreen allows typing and includes Wort-Rätsel & Hör-Diktat tabs',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AnlautKeyboardScreen(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Anlaut-Werkstatt'), findsOneWidget);
    expect(find.text('Wort-Rätsel ⭐'), findsOneWidget);
    expect(find.text('Hör-Diktat 🎧⭐'), findsOneWidget);
    expect(find.text('A a'), findsOneWidget);
    await tester.tap(find.text('A a'));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('AnlautTableScreen includes Reim-Detektiv tab', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AnlautTableScreen(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reim-Detektiv ⭐'), findsOneWidget);
    await tester.tap(find.text('Reim-Detektiv ⭐'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reim-Detektiv:'), findsOneWidget);
  });

  testWidgets('StageStoryScreen loads Stage 1 and Stage 5 stories',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StageStoryScreen(initialStage: 5),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lesepass & Geschichten'), findsOneWidget);
    expect(find.textContaining('Die Reise der Lese-Profis'), findsWidgets);
    expect(find.text('Silben-Hilfe'), findsOneWidget);
  });

  testWidgets('StickerAlbumScreen shows stage certificate chips up to Stage 5',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StickerAlbumScreen(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mein Sticker-Album'), findsOneWidget);
    expect(find.text('Urkunde Stufe 1'), findsOneWidget);
    expect(find.text('Urkunde Stufe 5'), findsOneWidget);
  });

  testWidgets(
      'ParentDashboardScreen renders profiles, Leitner Schatzkiste, Stage 5 and Schlafenszeit-Pause',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ParentDashboardScreen(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Eltern- & Lehrkräftebereich'), findsOneWidget);
    expect(find.text('Kinder-Profile'), findsOneWidget);
    expect(find.text('Sprache & DaZ-Wort-Brücke'), findsOneWidget);

    final listScrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.textContaining('Pädagogische Förderempfehlung'),
      250,
      scrollable: listScrollable,
    );
    expect(
      find.textContaining('Pädagogische Förderempfehlung'),
      findsOneWidget,
    );
    expect(find.textContaining('🌱 Üben:'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('Lernstufen & Lehrkraft-Freischaltung'),
      250,
      scrollable: listScrollable,
    );
    expect(
      find.textContaining('Lernstufen & Lehrkraft-Freischaltung'),
      findsOneWidget,
    );
    expect(find.textContaining('Stufe 5'), findsWidgets);

    await tester.scrollUntilVisible(
      find.textContaining('Schlafenszeit-Pause'),
      250,
      scrollable: listScrollable,
    );
    expect(find.textContaining('Schlafenszeit-Pause'), findsOneWidget);
    expect(find.textContaining('Tägliches Lernziel'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Lernbericht & Urkunde erstellen'),
      250,
      scrollable: listScrollable,
    );
    expect(find.text('Lernbericht & Urkunde erstellen'), findsOneWidget);
  });

  testWidgets('DailyMissionScreen renders 3-station guided adventure',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DailyMissionScreen(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fips & Finas Abenteuer-Runde 🧭'), findsOneWidget);
    expect(find.text('1. Hören'), findsOneWidget);
    expect(find.text('2. Silben'), findsOneWidget);
    expect(find.text('3. Lesen'), findsOneWidget);
    expect(find.text('Schatz'), findsOneWidget);
    expect(find.text('Anfang'), findsOneWidget);
    expect(find.text('Mitte'), findsOneWidget);
    expect(find.text('Ende'), findsOneWidget);
  });

  testWidgets(
      'BedtimePauseWrapper shows gentle bedtime pause when limit reached and unlocks +5 min via parent keypad',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: BedtimePauseWrapper(
            child: Scaffold(
              body: Text('Lernwelt aktiv'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lernwelt aktiv'), findsOneWidget);
    expect(find.text('Schlafenszeit-Pause!'), findsNothing);

    // Activate 10m limit and exhaust 10m today
    final notifier = container.read(progressProvider.notifier);
    await notifier.updateScreenTimeLimitMinutes(10);
    await notifier.recordActiveLearningSeconds(600);
    await tester.pumpAndSettle();

    expect(find.text('Schlafenszeit-Pause!'), findsOneWidget);
    expect(find.text('Eltern: +5 Minuten freigeben'), findsOneWidget);

    await tester.ensureVisible(find.text('Eltern: +5 Minuten freigeben'));
    await tester.tap(find.text('Eltern: +5 Minuten freigeben'));
    await tester.pumpAndSettle();

    // Parse math prompt "Eltern-Aufgabe: A + B = ?"
    final promptText = tester
        .widget<Text>(find.textContaining('Eltern-Aufgabe:'))
        .data!;
    final match = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(promptText)!;
    final sum = int.parse(match.group(1)!) + int.parse(match.group(2)!);
    for (final ch in sum.toString().split('')) {
      final btn = find.widgetWithText(OutlinedButton, ch);
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pump();
    }
    final allowBtn = find.text('+5 Min. erlauben');
    await tester.ensureVisible(allowBtn);
    await tester.tap(allowBtn);
    await tester.pumpAndSettle();

    expect(find.text('Schlafenszeit-Pause!'), findsNothing);
    expect(find.text('Lernwelt aktiv'), findsOneWidget);
  });

  testWidgets(
      'DazWordBridgeChip is hidden when BridgeLanguage.none and visible when enabled',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: DazWordBridgeChip(germanWord: 'Maus'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('fare'), findsNothing);

    await container
        .read(progressProvider.notifier)
        .updateActiveProfile(profileBridgeLanguage: BridgeLanguage.tr);
    await tester.pumpAndSettle();

    expect(find.text('fare'), findsOneWidget);
    expect(find.text('🇹🇷'), findsOneWidget);
  });
}
