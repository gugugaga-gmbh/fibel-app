import 'package:fibel_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fips & Fina E2E Flows', () {
    testWidgets('Full learning flow: Anlauttabelle, Laut-Zug, Silben & Sticker',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const ProviderScope(child: FibelApp()));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pumpAndSettle();

      // 1. HomeScreen displays title and unit M
      expect(find.text('Fips & Fina – Lese-Welt'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);

      // 2. Open Anlauttabelle and return
      await tester.tap(find.text('Anlauttabelle'));
      await tester.pumpAndSettle();
      expect(find.text('Apfel'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 3. Open Unit M -> Laut-Zug (Phonics)
      await tester.tap(find.text('M'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1. Laute hören'));
      await tester.pumpAndSettle();

      // Answer all 3 sound positions for M: Maus (start), Oma (middle), Baum (end)
      await tester.tap(find.text('Anfang'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mitte'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ende'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Super gehört!'),
        findsOneWidget,
      );
      await tester.tap(find.text('Zurück zur Übersicht'));
      await tester.pumpAndSettle();

      // 4. Open Unit M -> Silben schwingen
      await tester.tap(find.text('M'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3. Silben schwingen'));
      await tester.pumpAndSettle();

      for (final combo in ['Ma', 'Me', 'Mi', 'Mo', 'Mu']) {
        await tester.ensureVisible(find.text(combo));
        await tester.tap(find.text(combo));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.textContaining('alle Silben geübt'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // 5. Open Sticker-Album and verify 2 stars unlocked 'Schlauer Fips'
      await tester.tap(find.text('Sticker'));
      await tester.pumpAndSettle();

      expect(find.text('Schlauer Fips'), findsOneWidget);
      expect(find.text('Freigeschaltet!'), findsWidgets);
    });

    testWidgets('Tracing screen toggles uppercase/lowercase and accepts strokes',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const ProviderScope(child: FibelApp()));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('M'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2. Nachspuren & Schreiben'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Groß: M'), findsOneWidget);
      expect(find.text('Klein: m'), findsOneWidget);

      // Toggle to lowercase
      await tester.tap(find.text('Klein: m'));
      await tester.pump(const Duration(milliseconds: 200));

      // Draw a stroke on the tracing canvas
      final canvasFinder = find.byType(GestureDetector).last;
      await tester.drag(canvasFinder, const Offset(0, 120));
      await tester.pump(const Duration(milliseconds: 200));

      // Reset button works
      await tester.tap(find.text('Neu versuchen'));
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
