import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_lab/engine/pfqvs.dart';
import 'package:quantum_lab/utils/complex.dart';

void main() {
  group('Perlin noise properties', () {
    test('deterministic for same inputs', () {
      for (int seed = 0; seed < 10; seed++) {
        final v1 = perlinNoise(0.3, 0.5, 0.7, seed: seed);
        final v2 = perlinNoise(0.3, 0.5, 0.7, seed: seed);
        expect(v1, v2, reason: 'seed=$seed');
      }
    });

    test('varies with position', () {
      final values = <double>[];
      for (double x = 0; x < 1.0; x += 0.1) {
        values.add(perlinNoise(x, 0.1, 0.001, seed: 42));
      }
      final unique = values.toSet();
      expect(unique.length, greaterThan(5));
    });

    test('output is finite', () {
      for (int i = 0; i < 1000; i++) {
        final x = (i * 0.037) % 10.0;
        final y = (i * 0.053) % 10.0;
        final z = (i * 0.071) % 10.0;
        final v = perlinNoise(x, y, z, seed: i % 50);
        expect(v.isFinite, isTrue, reason: 'finite at i=$i');
        expect(v.isNaN, isFalse, reason: 'not NaN at i=$i');
      }
    });

    test('continuity: nearby inputs produce nearby outputs', () {
      const seed = 42;
      for (double x = 0.0; x < 5.0; x += 0.5) {
        final v1 = perlinNoise(x, 0.1, 0.001, seed: seed);
        final v2 = perlinNoise(x + 0.001, 0.1, 0.001, seed: seed);
        expect((v1 - v2).abs(), lessThan(0.1),
            reason: 'continuity at x=$x');
      }
    });

    test('different seeds produce some different noise values', () {
      int differentCount = 0;
      for (int s1 = 0; s1 < 10; s1++) {
        for (int s2 = s1 + 1; s2 < 10; s2++) {
          final v1 = perlinNoise(0.5, 0.5, 0.5, seed: s1);
          final v2 = perlinNoise(0.5, 0.5, 0.5, seed: s2);
          if ((v1 - v2).abs() > 1e-10) differentCount++;
        }
      }
      expect(differentCount, greaterThan(0));
    });
  });

  group('Perlin state initialization stress', () {
    test('normalized for all qubit counts 1-8', () {
      for (int n = 1; n <= 8; n++) {
        final state = perlinInitializeState(n, seed: 42);
        expect(state.length, 1 << n, reason: 'n=$n length');
        double norm = 0;
        for (final a in state) {
          norm += a.magnitudeSquared;
        }
        expect(norm, closeTo(1.0, 1e-10), reason: 'n=$n normalization');
      }
    });

    test('deterministic for same seed', () {
      for (int seed = 0; seed < 20; seed++) {
        final s1 = perlinInitializeState(3, seed: seed);
        final s2 = perlinInitializeState(3, seed: seed);
        for (int i = 0; i < s1.length; i++) {
          expect(s1[i].re, closeTo(s2[i].re, 1e-15), reason: 'seed=$seed i=$i');
          expect(s1[i].im, closeTo(s2[i].im, 1e-15), reason: 'seed=$seed i=$i');
        }
      }
    });

    test('different seeds produce different states', () {
      final s1 = perlinInitializeState(3, seed: 1);
      final s2 = perlinInitializeState(3, seed: 2);
      bool anyDifferent = false;
      for (int i = 0; i < s1.length; i++) {
        if ((s1[i].re - s2[i].re).abs() > 1e-10 ||
            (s1[i].im - s2[i].im).abs() > 1e-10) {
          anyDifferent = true;
          break;
        }
      }
      expect(anyDifferent, isTrue);
    });

    test('no NaN or infinity in initialized states', () {
      for (int seed = 0; seed < 50; seed++) {
        final state = perlinInitializeState(4, seed: seed);
        for (int i = 0; i < state.length; i++) {
          expect(state[i].re.isNaN, isFalse, reason: 'NaN at seed=$seed i=$i');
          expect(state[i].re.isInfinite, isFalse, reason: 'Inf at seed=$seed i=$i');
          expect(state[i].im.isNaN, isFalse, reason: 'NaN im at seed=$seed i=$i');
          expect(state[i].im.isInfinite, isFalse, reason: 'Inf im at seed=$seed i=$i');
        }
      }
    });

    test('amplitudes are non-trivial (not all zero except one)', () {
      final state = perlinInitializeState(3, seed: 42);
      int nonZeroCount = 0;
      for (final a in state) {
        if (a.magnitudeSquared > 1e-10) nonZeroCount++;
      }
      expect(nonZeroCount, greaterThan(1));
    });

    test('environmental seed produces valid output', () {
      final seed = getEnvironmentalSeed();
      expect(seed, isNonNegative);
      final state = perlinInitializeState(3, seed: seed);
      double norm = 0;
      for (final a in state) {
        norm += a.magnitudeSquared;
      }
      expect(norm, closeTo(1.0, 1e-10));
    });
  });

  group('Decoherence stress', () {
    test('preserves normalization for various dt values', () {
      final state = perlinInitializeState(3, seed: 42);
      for (final dt in [0.001, 0.01, 0.05, 0.1, 0.5, 1.0]) {
        final decayed = applyDecoherence(state, dt: dt, seed: 42);
        double norm = 0;
        for (final a in decayed) {
          norm += a.magnitudeSquared;
        }
        expect(norm, closeTo(1.0, 1e-8), reason: 'dt=$dt');
      }
    });

    test('preserves normalization for various octave counts', () {
      final state = perlinInitializeState(3, seed: 42);
      for (int octaves = 1; octaves <= 6; octaves++) {
        final decayed = applyDecoherence(state, octaves: octaves, seed: 42);
        double norm = 0;
        for (final a in decayed) {
          norm += a.magnitudeSquared;
        }
        expect(norm, closeTo(1.0, 1e-8), reason: 'octaves=$octaves');
      }
    });

    test('preserves normalization for various time steps', () {
      final state = perlinInitializeState(4, seed: 42);
      for (double t = 0; t < 100; t += 10) {
        final decayed = applyDecoherence(state, t: t, seed: 42);
        double norm = 0;
        for (final a in decayed) {
          norm += a.magnitudeSquared;
        }
        expect(norm, closeTo(1.0, 1e-8), reason: 't=$t');
      }
    });

    test('dt=0 leaves state unchanged', () {
      final state = perlinInitializeState(3, seed: 42);
      final decayed = applyDecoherence(state, dt: 0.0, seed: 42);
      for (int i = 0; i < state.length; i++) {
        expect(decayed[i].re, closeTo(state[i].re, 1e-10));
        expect(decayed[i].im, closeTo(state[i].im, 1e-10));
      }
    });

    test('decoherence is deterministic', () {
      final state = perlinInitializeState(3, seed: 42);
      final d1 = applyDecoherence(state, dt: 0.1, seed: 42, t: 5.0);
      final d2 = applyDecoherence(state, dt: 0.1, seed: 42, t: 5.0);
      for (int i = 0; i < state.length; i++) {
        expect(d1[i].re, closeTo(d2[i].re, 1e-15));
        expect(d1[i].im, closeTo(d2[i].im, 1e-15));
      }
    });

    test('no NaN or infinity after decoherence', () {
      for (int seed = 0; seed < 30; seed++) {
        final state = perlinInitializeState(4, seed: seed);
        final decayed = applyDecoherence(state, dt: 0.5, seed: seed, octaves: 4);
        for (int i = 0; i < decayed.length; i++) {
          expect(decayed[i].re.isNaN, isFalse, reason: 'NaN at seed=$seed i=$i');
          expect(decayed[i].re.isInfinite, isFalse, reason: 'Inf at seed=$seed i=$i');
        }
      }
    });

    test('sequential decoherence steps maintain normalization', () {
      var state = perlinInitializeState(3, seed: 42);
      for (int step = 0; step < 50; step++) {
        state = applyDecoherence(state, dt: 0.05, seed: 42, t: step.toDouble());
        double norm = 0;
        for (final a in state) {
          norm += a.magnitudeSquared;
        }
        expect(norm, closeTo(1.0, 1e-6), reason: 'step=$step');
      }
    });
  });

  group('Importance sampling stress', () {
    test('total counts equal shots', () {
      for (final shots in [1, 10, 100, 500, 2000]) {
        final state = perlinInitializeState(2, seed: 42);
        final counts = measureImportanceSampling(state, 2, shots: shots, seed: 42);
        final total = counts.values.fold(0, (a, b) => a + b);
        expect(total, shots, reason: 'shots=$shots');
      }
    });

    test('labels have correct length', () {
      for (int n = 1; n <= 5; n++) {
        final state = perlinInitializeState(n, seed: 42);
        final counts = measureImportanceSampling(state, n, shots: 100, seed: 42);
        for (final key in counts.keys) {
          expect(key.length, n, reason: 'n=$n key=$key');
        }
      }
    });

    test('deterministic measurement', () {
      final state = perlinInitializeState(3, seed: 42);
      final c1 = measureImportanceSampling(state, 3, shots: 100, seed: 99);
      final c2 = measureImportanceSampling(state, 3, shots: 100, seed: 99);
      expect(c1, c2);
    });

    test('works with Bell-like state', () {
      final s = 1.0 / math.sqrt(2.0);
      final state = [Complex(s), cZero, cZero, Complex(s)];
      final counts = measureImportanceSampling(state, 2, shots: 1000, seed: 42);
      final total = counts.values.fold(0, (a, b) => a + b);
      expect(total, 1000);
      expect((counts['00'] ?? 0) + (counts['11'] ?? 0), greaterThan(800));
    });

    test('works with uniform state', () {
      final n = 4;
      final amp = Complex(1.0 / math.sqrt(16.0));
      final state = List<Complex>.filled(16, amp);
      final counts = measureImportanceSampling(state, n, shots: 1000, seed: 42);
      final total = counts.values.fold(0, (a, b) => a + b);
      expect(total, 1000);
      expect(counts.length, greaterThan(8));
    });

    test('alpha=0 approximates standard sampling', () {
      final s = 1.0 / math.sqrt(2.0);
      final state = [Complex(s), cZero, cZero, Complex(s)];
      final counts = measureImportanceSampling(
        state, 2,
        shots: 1000,
        alpha: 0.0,
        seed: 42,
      );
      final total = counts.values.fold(0, (a, b) => a + b);
      expect(total, 1000);
      // Should only see 00 and 11
      for (final key in counts.keys) {
        expect(key == '00' || key == '11', isTrue, reason: 'unexpected: $key');
      }
    });

    test('works with different alpha values', () {
      final state = perlinInitializeState(3, seed: 42);
      for (final alpha in [0.0, 0.1, 0.25, 0.5, 0.75, 1.0]) {
        final counts = measureImportanceSampling(
          state, 3,
          shots: 500,
          alpha: alpha,
          seed: 42,
        );
        final total = counts.values.fold(0, (a, b) => a + b);
        expect(total, 500, reason: 'alpha=$alpha');
      }
    });

    test('works with different spectralFraction values', () {
      final state = perlinInitializeState(3, seed: 42);
      for (final sf in [0.05, 0.1, 0.25, 0.5, 0.75, 1.0]) {
        final counts = measureImportanceSampling(
          state, 3,
          shots: 500,
          spectralFraction: sf,
          seed: 42,
        );
        final total = counts.values.fold(0, (a, b) => a + b);
        expect(total, 500, reason: 'sf=$sf');
      }
    });

    test('handles zero-amplitude state gracefully', () {
      final state = List<Complex>.filled(4, cZero);
      final counts = measureImportanceSampling(state, 2, shots: 100, seed: 42);
      final total = counts.values.fold(0, (a, b) => a + b);
      expect(total, 100);
    });

    test('handles single non-zero amplitude', () {
      final state = [cZero, cZero, cOne, cZero];
      final counts = measureImportanceSampling(state, 2, shots: 100, seed: 42);
      expect(counts['10'], 100);
    });

    test('no NaN counts', () {
      for (int seed = 0; seed < 20; seed++) {
        final state = perlinInitializeState(3, seed: seed);
        final counts = measureImportanceSampling(state, 3, shots: 100, seed: seed);
        for (final v in counts.values) {
          expect(v.isNaN, isFalse);
          expect(v, greaterThanOrEqualTo(0));
        }
      }
    });
  });

  group('End-to-end PFQVS pipeline', () {
    test('full pipeline: init → decohere → measure', () {
      for (int n = 1; n <= 5; n++) {
        var state = perlinInitializeState(n, seed: 42);
        state = applyDecoherence(state, dt: 0.05, seed: 42);
        final counts = measureImportanceSampling(state, n, shots: 500, seed: 42);
        final total = counts.values.fold(0, (a, b) => a + b);
        expect(total, 500, reason: 'n=$n');
        for (final key in counts.keys) {
          expect(key.length, n, reason: 'n=$n key=$key');
        }
      }
    });

    test('pipeline with evolving time', () {
      var state = perlinInitializeState(3, seed: 42);
      for (int t = 0; t < 20; t++) {
        state = applyDecoherence(state, dt: 0.02, seed: 42, t: t.toDouble());
      }
      double norm = 0;
      for (final a in state) {
        norm += a.magnitudeSquared;
      }
      expect(norm, closeTo(1.0, 1e-6));

      final counts = measureImportanceSampling(state, 3, shots: 1000, seed: 42);
      final total = counts.values.fold(0, (a, b) => a + b);
      expect(total, 1000);
    });
  });
}
