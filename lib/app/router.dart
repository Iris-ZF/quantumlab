import 'package:go_router/go_router.dart';
import '../data/lessons/quantum_lessons.dart';
import '../data/lessons/qasm_lessons.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/circuit_builder_screen.dart';
import '../ui/screens/lesson_list_screen.dart';
import '../ui/screens/lesson_screen.dart';
import '../ui/screens/qasm_editor_screen.dart';
import '../ui/screens/pfqvs_screen.dart';
import '../ui/screens/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/builder',
      builder: (context, state) => const CircuitBuilderScreen(),
    ),
    GoRoute(
      path: '/lessons',
      builder: (context, state) => const LessonListScreen(),
    ),
    GoRoute(
      path: '/lesson/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final allLessons = [...quantumLessons, ...qasmLessons];
        final lesson = allLessons.firstWhere(
          (l) => l.id == id,
          orElse: () => quantumLessons.first,
        );
        return LessonScreen(lesson: lesson);
      },
    ),
    GoRoute(
      path: '/qasm',
      builder: (context, state) => const QasmEditorScreen(),
    ),
    GoRoute(
      path: '/pfqvs',
      builder: (context, state) => const PfqvsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
