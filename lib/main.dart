import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/curriculum/curriculum_models.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/phonics/anlaut_table_screen.dart';
import 'features/reading/word_sentence_builder_screen.dart';
import 'features/rewards/sticker_album_screen.dart';
import 'features/syllables/syllable_practice_screen.dart';
import 'features/writing/letter_tracing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      path: '/stickers',
      builder: (context, state) => const StickerAlbumScreen(),
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
