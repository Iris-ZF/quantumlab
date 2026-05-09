import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/lessons/quantum_lessons.dart';
import '../../data/lessons/qasm_lessons.dart';
import '../../models/lesson.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/auth_provider.dart';

class LessonListScreen extends ConsumerWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final progress = ref.watch(lessonProvider);
    final auth = ref.watch(authProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Learn Quantum'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Quantum Basics'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('QASM'),
                    if (!progress.allQuantumComplete) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.lock_outline, size: 14, color: cs.onSurfaceVariant),
                    ],
                  ],
                ),
              ),
            ],
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
          ),
        ),
        body: TabBarView(
          children: [
            _LessonList(lessons: quantumLessons, progress: progress, isPro: auth.isPro),
            progress.allQuantumComplete
                ? _LessonList(lessons: qasmLessons, progress: progress, isPro: auth.isPro)
                : _LockedQasmView(progress: progress),
          ],
        ),
      ),
    );
  }
}

class _LessonList extends StatelessWidget {
  final List<Lesson> lessons;
  final LessonProgress progress;
  final bool isPro;

  const _LessonList({required this.lessons, required this.progress, required this.isPro});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        final isComplete = progress.isLessonComplete(lesson.id);
        final isAccessible = lesson.isFree || isPro;
        final stepProgress = progress.getStep(lesson.id);
        final totalSteps = lesson.steps.length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (!isAccessible) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${lesson.title} requires Pro'),
                    action: SnackBarAction(label: 'Upgrade', onPressed: () => context.go('/settings')),
                  ),
                );
                return;
              }
              context.go('/lesson/${lesson.id}');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Number badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? Colors.green
                          : isAccessible
                              ? cs.primaryContainer
                              : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: isComplete
                          ? const Icon(Icons.check, color: Colors.white, size: 22)
                          : Text(
                              '${lesson.number}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isAccessible ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isAccessible ? cs.onSurface : cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lesson.subtitle,
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                        if (stepProgress > 0 && !isComplete) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: stepProgress / totalSteps,
                              minHeight: 3,
                              backgroundColor: cs.surfaceContainerHighest,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isAccessible)
                    Icon(Icons.lock_outline, color: cs.onSurfaceVariant.withValues(alpha: 0.5), size: 20),
                  if (isAccessible && !isComplete)
                    Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms, duration: 300.ms).slideX(begin: 0.05, end: 0, delay: (50 * index).ms, duration: 300.ms, curve: Curves.easeOut);
      },
    );
  }
}

class _LockedQasmView extends StatelessWidget {
  final LessonProgress progress;
  const _LockedQasmView({required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completed = progress.completedLessons.entries
        .where((e) => e.key.startsWith('q') && !e.key.startsWith('qasm') && e.value)
        .length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: cs.outlineVariant),
            const SizedBox(height: 20),
            Text(
              'Complete All Quantum Lessons',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Finish all 10 quantum lessons to unlock the QASM programming course.',
              style: TextStyle(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '$completed / 10 complete',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completed / 10,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
