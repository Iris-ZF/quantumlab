import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';

/// Tracks lesson progress locally and syncs with Firebase.
class LessonProgress {
  final Map<String, bool> completedLessons; // lessonId -> completed
  final Map<String, int> lessonStepProgress; // lessonId -> last completed step
  final bool allQuantumComplete;

  const LessonProgress({
    this.completedLessons = const {},
    this.lessonStepProgress = const {},
    this.allQuantumComplete = false,
  });

  LessonProgress copyWith({
    Map<String, bool>? completedLessons,
    Map<String, int>? lessonStepProgress,
    bool? allQuantumComplete,
  }) {
    return LessonProgress(
      completedLessons: completedLessons ?? this.completedLessons,
      lessonStepProgress: lessonStepProgress ?? this.lessonStepProgress,
      allQuantumComplete: allQuantumComplete ?? this.allQuantumComplete,
    );
  }

  bool isLessonComplete(String id) => completedLessons[id] == true;
  int getStep(String id) => lessonStepProgress[id] ?? 0;
}

class LessonNotifier extends Notifier<LessonProgress> {
  @override
  LessonProgress build() {
    _loadFromLocal();
    return const LessonProgress();
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final completedKeys = prefs.getStringList('completedLessons') ?? [];
    final completed = {for (final k in completedKeys) k: true};

    final stepKeys = prefs.getStringList('lessonStepKeys') ?? [];
    final steps = <String, int>{};
    for (final k in stepKeys) {
      steps[k] = prefs.getInt('step_$k') ?? 0;
    }

    final allQuantum = ['q01', 'q02', 'q03', 'q04', 'q05', 'q06', 'q07', 'q08', 'q09', 'q10']
        .every((id) => completed[id] == true);

    state = LessonProgress(
      completedLessons: completed,
      lessonStepProgress: steps,
      allQuantumComplete: allQuantum,
    );

    // Sync from Firebase if signed in
    _syncFromFirebase();
  }

  Future<void> _syncFromFirebase() async {
    final fb = FirebaseService.instance;
    if (!fb.isSignedIn) return;

    final remote = await fb.getLessonProgress();
    if (remote.isEmpty) return;

    final merged = Map<String, bool>.from(state.completedLessons);
    final mergedSteps = Map<String, int>.from(state.lessonStepProgress);

    for (final entry in remote.entries) {
      final data = entry.value;
      if (data is Map) {
        if (data['completed'] == true) merged[entry.key] = true;
        final remoteStep = data['step'] as int? ?? 0;
        final localStep = mergedSteps[entry.key] ?? 0;
        mergedSteps[entry.key] = remoteStep > localStep ? remoteStep : localStep;
      }
    }

    final allQuantum = ['q01', 'q02', 'q03', 'q04', 'q05', 'q06', 'q07', 'q08', 'q09', 'q10']
        .every((id) => merged[id] == true);

    state = LessonProgress(
      completedLessons: merged,
      lessonStepProgress: mergedSteps,
      allQuantumComplete: allQuantum,
    );
  }

  Future<void> completeStep(String lessonId, int step) async {
    final currentStep = state.lessonStepProgress[lessonId] ?? 0;
    if (step <= currentStep) return;

    final newSteps = Map<String, int>.from(state.lessonStepProgress);
    newSteps[lessonId] = step;
    state = state.copyWith(lessonStepProgress: newSteps);

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('lessonStepKeys', newSteps.keys.toList());
    await prefs.setInt('step_$lessonId', step);

    // Sync to Firebase
    FirebaseService.instance.saveLessonProgress(lessonId, {
      'step': step,
      'completed': state.completedLessons[lessonId] ?? false,
    });
  }

  Future<void> completeLesson(String lessonId) async {
    final newCompleted = Map<String, bool>.from(state.completedLessons);
    newCompleted[lessonId] = true;

    final allQuantum = ['q01', 'q02', 'q03', 'q04', 'q05', 'q06', 'q07', 'q08', 'q09', 'q10']
        .every((id) => newCompleted[id] == true);

    state = state.copyWith(
      completedLessons: newCompleted,
      allQuantumComplete: allQuantum,
    );

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('completedLessons', newCompleted.keys.where((k) => newCompleted[k] == true).toList());

    // Sync to Firebase + record XP
    FirebaseService.instance.saveLessonProgress(lessonId, {
      'completed': true,
      'step': state.lessonStepProgress[lessonId] ?? 0,
    });
    FirebaseService.instance.recordExperience('lesson_complete', data: {'lessonId': lessonId});
  }
}

final lessonProvider = NotifierProvider<LessonNotifier, LessonProgress>(LessonNotifier.new);
