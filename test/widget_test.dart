import 'package:fibel_app/core/i18n/app_localizations.dart';
import 'package:fibel_app/core/i18n/daz_word_bridge.dart';
import 'package:fibel_app/core/storage/progress_repository.dart';
import 'package:fibel_app/core/theme/app_theme.dart';
import 'package:fibel_app/core/widgets/parental_gate_dialog.dart';
import 'package:fibel_app/core/widgets/syllable_text_widget.dart';
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

  testWidgets('FibelApp loads HomeScreen with units, daily goal and stage chips',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: FibelApp()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fips & Fina – Lese-Welt'), findsOneWidget);
    expect(find.text('Anlauttabelle'), findsOneWidget);
    expect(find.text('Werkstatt'), findsOneWidget);
    expect(find.text('Geschichten'), findsOneWidget);
    expect(find.text('Sticker'), findsOneWidget);
    expect(find.text('Stufe 1'), findsOneWidget);
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

  testWidgets('StageStoryScreen loads stage stories and toggles syllable help',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StageStoryScreen(initialStage: 1),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lesepass & Geschichten'), findsOneWidget);
    expect(find.textContaining('Mimi und Leo am See'), findsWidgets);
    expect(find.text('Silben-Hilfe'), findsOneWidget);
  });

  testWidgets('StickerAlbumScreen shows stage certificate chips and stickers',
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
  });

  testWidgets('ParentDashboardScreen renders profiles, stats and settings',
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
    expect(
      find.textContaining('Lernstufen & Lehrkraft-Freischaltung'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Pädagogische Förderempfehlung'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Tägliches Lernziel'),
      findsOneWidget,
    );
    expect(
      find.text('Lernbericht & Urkunde erstellen'),
      findsOneWidget,
    );
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
