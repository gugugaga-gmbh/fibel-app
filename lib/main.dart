import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/curriculum/curriculum_models.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/parents/parent_dashboard_screen.dart';
import 'features/phonics/anlaut_table_screen.dart';
import 'features/reading/stage_story_screen.dart';
import 'features/reading/word_sentence_builder_screen.dart';
import 'features/rewards/sticker_album_screen.dart';
import 'features/syllables/syllable_practice_screen.dart';
import 'features/writing/anlaut_keyboard_screen.dart';
import 'features/writing/letter_tracing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Andika'], ofl);
  });
  runApp(const ProviderScope(child: FibelApp()));
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/anlaut',
      builder: (context, state) => const AnlautTableScreen(),
    ),
    GoRoute(
      path: '/werkstatt',
      builder: (context, state) => const AnlautKeyboardScreen(),
    ),
    GoRoute(
      path: '/stories',
      builder: (context, state) {
        final initialStage = state.extra as int?;
        return StageStoryScreen(initialStage: initialStage);
      },
    ),
    GoRoute(
      path: '/stickers',
      builder: (context, state) => const StickerAlbumScreen(),
    ),
    GoRoute(
      path: '/parents',
      builder: (context, state) => const ParentDashboardScreen(),
    ),
    GoRoute(
      path: '/unit/:id/phonics',
      builder: (context, state) {
        final unit = state.extra as LessonUnit?;
        return AnlautTableScreen(unit: unit);
      },
    ),
    GoRoute(
      path: '/unit/:id/tracing',
      builder: (context, state) {
        final unit = state.extra as LessonUnit;
        return LetterTracingScreen(unit: unit);
      },
    ),
    GoRoute(
      path: '/unit/:id/syllables',
      builder: (context, state) {
        final unit = state.extra as LessonUnit;
        return SyllablePracticeScreen(unit: unit);
      },
    ),
    GoRoute(
      path: '/unit/:id/reading',
      builder: (context, state) {
        final unit = state.extra as LessonUnit;
        return WordSentenceBuilderScreen(unit: unit);
      },
    ),
  ],
);

class FibelApp extends StatelessWidget {
  const FibelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fips & Fina – Lesen & Schreiben',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      routerConfig: _router,
    );
  }
}
