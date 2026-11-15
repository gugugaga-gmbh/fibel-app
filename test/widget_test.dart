import 'package:fibel_app/core/theme/app_theme.dart';
import 'package:fibel_app/core/widgets/parental_gate_dialog.dart';
import 'package:fibel_app/core/widgets/syllable_text_widget.dart';
import 'package:fibel_app/features/parents/parent_dashboard_screen.dart';
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
    expect(find.text('Sticker'), findsOneWidget);
    expect(find.text('Stufe 1'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('Maus'), findsNothing); // rendered as '🐭 Maus'
    expect(find.textContaining('Maus'), findsOneWidget);
  });

  testWidgets('AnlautKeyboardScreen allows typing with Anlaut keys',
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
    expect(find.text('A a'), findsOneWidget);
    await tester.tap(find.text('A a'));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
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
    expect(find.textContaining('Lernstufen & Lehrkraft-Freischaltung'),
        findsOneWidget);
  });
}
