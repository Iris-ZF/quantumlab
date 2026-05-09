import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_lab/engine/pfqvs.dart';
import 'package:quantum_lab/utils/complex.dart';

void main() {
  group('PFQVS', () {
    test('perlinNoise returns deterministic values for same seed', () {
      final v1 = perlinNoise(0.5, 0.1, 0.001, seed: 42);
      final v2 = perlinNoise(0.5, 0.1, 0.001, seed: 42);
      expect(v1, v2);
    });

    test('perlinNoise returns different values for different seeds', () {
      final v1 = perlinNoise(0.5, 0.1, 0.001, seed: 42);
      final v2 = perlinNoise(0.5, 0.1, 0.001, seed: 99);
      expect(v1, isNot(v2));
    });

    test('perlinInitializeState produces normalized state', () {
      final state = perlinInitializeState(3, seed: 42);
      expect(state.length, 8);
      double norm = 0;
      for (final a in state) {
        norm += a.magnitudeSquared;
      }
      expect(norm, closeTo(1.0, 1e-10));
    });

    test('perlinInitializeState is deterministic', () {
      final s1 = perlinInitializeState(2, seed: 42);
      final s2 = perlinInitializeState(2, seed: 42);
      for (int i = 0; i < s1.length; i++) {
        expect(s1[i].re, closeTo(s2[i].re, 1e-10));
        expect(s1[i].im, closeTo(s2[i].im, 1e-10));
      }
    });

    test('applyDecoherence preserves normalization', () {
      final state = perlinInitializeState(3, seed: 42);
      final decayed = applyDecoherence(state, dt: 0.1, seed: 42);
      double norm = 0;
      for (final a in decayed) {
        norm += a.magnitudeSquared;
      }
      expect(norm, closeTo(1.0, 1e-10));
    });

    test('measureImportanceSampling returns valid counts', () {
      final state = [
        Complex(1.0 / 1.4142135, 0),
        cZero,
        cZero,
        Complex(1.0 / 1.4142135, 0),
      ]; // Bell-like state
      final counts = measureImportanceSampling(state, 2, shots: 1000, seed: 42);
      final total = counts.values.fold(0, (a, b) => a + b);
      expect(total, 1000);
      // Should mostly see 00 and 11
      expect((counts['00'] ?? 0) + (counts['11'] ?? 0), greaterThan(800));
    });
  });
}
