import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/lesson.dart';
import '../../providers/lesson_provider.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final Lesson lesson;
  const LessonScreen({super.key, required this.lesson});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late int _currentStep;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final savedStep = ref.read(lessonProvider).getStep(widget.lesson.id);
    _currentStep = savedStep.clamp(0, widget.lesson.steps.length - 1);
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lesson = widget.lesson;
    final totalSteps = lesson.steps.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/lessons'),
        ),
        title: Text(lesson.title, style: const TextStyle(fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: ((_currentStep + 1) / totalSteps).clamp(0.0, 1.0),
            backgroundColor: cs.surfaceContainerHighest,
            color: cs.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSteps, (i) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= _currentStep ? cs.primary : cs.outlineVariant,
                  ),
                );
              }),
            ),
          ),
          // Page content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalSteps,
              itemBuilder: (context, index) {
                return _StepContent(step: lesson.steps[index]);
              },
            ),
          ),
          // Navigation
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton.icon(
                      onPressed: _goBack,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                    ),
                  const Spacer(),
                  if (_currentStep < totalSteps - 1)
                    FilledButton.icon(
                      onPressed: _goNext,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Next'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _completeLesson,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Complete'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goNext() {
    if (_currentStep < widget.lesson.steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      ref.read(lessonProvider.notifier).completeStep(widget.lesson.id, _currentStep);
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _completeLesson() {
    ref.read(lessonProvider.notifier).completeLesson(widget.lesson.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.lesson.title} completed!'), backgroundColor: Colors.green),
    );
    context.go('/lessons');
  }
}

class _StepContent extends StatelessWidget {
  final LessonStep step;
  const _StepContent({required this.step});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _badgeColor(step.type, cs),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _badgeLabel(step.type),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onPrimary),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            step.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Content
          SelectableText(
            step.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          // QASM setup display
          if (step.qasmSetup != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code, size: 16, color: cs.primary),
                      const SizedBox(width: 6),
                      Text('Circuit', style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    step.qasmSetup!,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: cs.onSurface),
                  ),
                ],
              ),
            ),
          ],
          // Expected outcome
          if (step.expectedOutcome != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(step.expectedOutcome!, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ],
          // Hint
          if (step.hint != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Hint', style: TextStyle(color: cs.primary, fontSize: 13)),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(step.hint!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Color _badgeColor(LessonStepType type, ColorScheme cs) {
    switch (type) {
      case LessonStepType.explanation:
        return cs.primary;
      case LessonStepType.interactive:
        return Colors.orange;
      case LessonStepType.quiz:
        return Colors.purple;
      case LessonStepType.demonstration:
        return Colors.teal;
    }
  }

  String _badgeLabel(LessonStepType type) {
    switch (type) {
      case LessonStepType.explanation:
        return 'LEARN';
      case LessonStepType.interactive:
        return 'TRY IT';
      case LessonStepType.quiz:
        return 'QUIZ';
      case LessonStepType.demonstration:
        return 'DEMO';
    }
  }
}
