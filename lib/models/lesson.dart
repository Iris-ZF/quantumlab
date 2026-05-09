import 'package:flutter/material.dart';

/// A single step within a lesson.
class LessonStep {
  final String title;
  final String content; // Markdown-style explanation text
  final LessonStepType type;
  /// Pre-loaded QASM for the interactive circuit (if applicable).
  final String? qasmSetup;
  /// Expected measurement outcome description for validation.
  final String? expectedOutcome;
  /// Hint text shown on request.
  final String? hint;

  const LessonStep({
    required this.title,
    required this.content,
    this.type = LessonStepType.explanation,
    this.qasmSetup,
    this.expectedOutcome,
    this.hint,
  });
}

enum LessonStepType {
  explanation,   // Text + optional illustration
  interactive,   // User builds a circuit and verifies
  quiz,          // Multiple choice question
  demonstration, // Pre-built circuit the user runs
}

/// A complete lesson.
class Lesson {
  final String id;
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isFree;
  final List<LessonStep> steps;
  final String category; // 'quantum' or 'qasm'

  const Lesson({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.steps,
    this.isFree = false,
    this.category = 'quantum',
  });
}
