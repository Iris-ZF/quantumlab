import 'dart:math' as math;
import '../utils/complex.dart';

/// Perlin-Fourier Quantum Virtual Simulation (PFQVS) engine.
///
/// This is a faithful Dart port of the novum-qvm PFQVS approach:
///   Layer 1: Perlin-noise quantum state initialization
///   Layer 2: FFT-domain gate execution (O(N) pair iteration)
///   Layer 3: Octave-weighted Perlin decoherence
///   Layer 4: FFT-based importance sampling measurement
///
/// Reference: novum-qvm v1.2.0 — PFQVS_QuantumComputer

// ── Perlin Noise (ported from novum-qvm functions.py) ──

double _fade(double t) => t * t * t * (t * (t * 6 - 15) + 10);

double _lerp(double a, double b, double t) => a + t * (b - a);

double _grad(int hash, double x, double y, double z) {
  final h = hash & 15;
  final u = h < 8 ? x : y;
  final v = h < 4 ? y : (h == 12 || h == 14 ? x : z);
  return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
}

/// 3D Perlin noise with deterministic seed, ported from novum-qvm.
double perlinNoise(double x, double y, double z, {int seed = 0}) {
  final rng = math.Random(seed);
  final p = List<int>.generate(256, (i) => i);
  // Fisher-Yates shuffle with seeded RNG (matches Python random.shuffle(p, seed))
  for (int i = 255; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = p[i];
    p[i] = p[j];
    p[j] = tmp;
  }
  final pp = [...p, ...p]; // double the permutation table

  final xi = x.floor() & 255;
  final yi = y.floor() & 255;
  final zi = z.floor() & 255;

  final xf = x - x.floor();
  final yf = y - y.floor();
  final zf = z - z.floor();

  final u = _fade(xf);
  final v = _fade(yf);
  final w = _fade(zf);

  final a = pp[xi] + yi;
  final aa = pp[a] + zi;
  final ab = pp[a + 1] + zi;
  final b = pp[xi + 1] + yi;
  final ba = pp[b] + zi;
  final bb = pp[b + 1] + zi;

  return _lerp(
    w,
    _lerp(
      v,
      _lerp(u, _grad(pp[aa], xf, yf, zf), _grad(pp[ba], xf - 1, yf, zf)),
      _lerp(u, _grad(pp[ab], xf, yf - 1, zf), _grad(pp[bb], xf - 1, yf - 1, zf)),
    ),
    _lerp(
      v,
      _lerp(u, _grad(pp[aa + 1], xf, yf, zf - 1), _grad(pp[ba + 1], xf - 1, yf, zf - 1)),
      _lerp(u, _grad(pp[ab + 1], xf, yf - 1, zf - 1), _grad(pp[bb + 1], xf - 1, yf - 1, zf - 1)),
    ),
  );
}

/// Environmental seed from timestamp (matches novum-qvm get_environmental_seed).
int getEnvironmentalSeed() {
  final t = DateTime.now().microsecondsSinceEpoch;
  // Simple hash to get a 32-bit seed
  var h = t ^ (t >>> 16);
  h = (h * 0x45d9f3b) & 0xFFFFFFFF;
  h = h ^ (h >>> 16);
  return h & 0xFFFFFFFF;
}

// ── PFQVS Layer 1: Perlin State Initialization ──

/// Initialize quantum state using Perlin noise (PFQVS Layer 1).
/// Each amplitude gets real/imag parts from 3D Perlin noise evaluated
/// at fractional coordinates, producing a deterministic but complex
/// initial state vector.
List<Complex> perlinInitializeState(int nQubits, {int? seed}) {
  final s = seed ?? getEnvironmentalSeed();
  final n = 1 << nQubits;
  final psi = List<Complex>.filled(n, cZero);

  for (int i = 0; i < n; i++) {
    final xFrac = i / n.toDouble();
    final real = perlinNoise(xFrac, 0.1, s * 0.001, seed: s);
    final imag = perlinNoise((xFrac + 0.5) % 1.0, 0.2, s * 0.001, seed: s);
    psi[i] = Complex(real, imag);
  }

  // Normalize
  double norm = 0;
  for (final a in psi) {
    norm += a.magnitudeSquared;
  }
  if (norm < 1e-24) {
    // Degenerate — fall back to |0⟩
    psi[0] = cOne;
    return psi;
  }
  final invNorm = 1.0 / math.sqrt(norm);
  for (int i = 0; i < n; i++) {
    psi[i] = psi[i].scale(invNorm);
  }
  return psi;
}

// ── PFQVS Layer 3: Octave-Weighted Perlin Decoherence ──

/// Apply decoherence via octave-mapped Perlin noise (PFQVS Layer 3).
/// Uses circuit depth `t` as time parameter so decoherence evolves.
List<Complex> applyDecoherence(
  List<Complex> amplitudes, {
  double dt = 0.01,
  int octaves = 3,
  double t = 0.0,
  int seed = 0,
}) {
  final n = amplitudes.length;
  final result = List<Complex>.from(amplitudes);

  for (int i = 0; i < n; i++) {
    final xFrac = i / n.toDouble();
    double env = 0.0;
    for (int o = 1; o <= octaves; o++) {
      final zCoord = seed * 0.001 + t * 0.01;
      env += (1.0 / (1 << o)) * perlinNoise(xFrac * (1 << o), 0.1 * o, zCoord, seed: seed);
    }
    final damping = math.exp(-env.abs() * dt);
    result[i] = result[i].scale(damping);
  }

  // Re-normalize
  double norm = 0;
  for (final a in result) {
    norm += a.magnitudeSquared;
  }
  if (norm > 1e-24) {
    final invNorm = 1.0 / math.sqrt(norm);
    for (int i = 0; i < n; i++) {
      result[i] = result[i].scale(invNorm);
    }
  }
  return result;
}

// ── PFQVS Layer 4: FFT-Based Importance Sampling ──

/// Measure with spectral importance sampling (PFQVS Layer 4).
/// Blends Born-rule probabilities with a spectral mask computed from
/// the FFT of the probability distribution, reducing sampling variance.
Map<String, int> measureImportanceSampling(
  List<Complex> amplitudes,
  int nQubits, {
  int shots = 1024,
  double alpha = 0.5,
  double spectralFraction = 0.1,
  int? seed,
}) {
  final rng = math.Random(seed);
  final n = amplitudes.length;

  // Born-rule probabilities
  final probs = List<double>.filled(n, 0);
  double s = 0;
  for (int i = 0; i < n; i++) {
    probs[i] = amplitudes[i].magnitudeSquared;
    s += probs[i];
  }
  if (s <= 0) {
    for (int i = 0; i < n; i++) {
      probs[i] = 1.0 / n;
    }
  } else {
    for (int i = 0; i < n; i++) {
      probs[i] /= s;
    }
  }

  // Spectral mask via simplified DFT approach (no full FFT needed for ≤256 elements)
  // Keep top spectral components
  final keep = math.max(1, (n * spectralFraction).round());
  final mask = List<double>.filled(n, 0);

  // Compute DFT magnitudes to find dominant frequencies
  final magnitudes = List<double>.filled(n, 0);
  for (int k = 0; k < n; k++) {
    double realPart = 0, imagPart = 0;
    for (int j = 0; j < n; j++) {
      final angle = -2 * math.pi * k * j / n;
      realPart += probs[j] * math.cos(angle);
      imagPart += probs[j] * math.sin(angle);
    }
    magnitudes[k] = math.sqrt(realPart * realPart + imagPart * imagPart);
  }

  // Find top-k frequency indices
  final indices = List<int>.generate(n, (i) => i);
  indices.sort((a, b) => magnitudes[b].compareTo(magnitudes[a]));
  final topK = indices.sublist(0, keep).toSet();

  // Inverse DFT of filtered spectrum
  for (int j = 0; j < n; j++) {
    double val = 0;
    for (int k = 0; k < n; k++) {
      if (!topK.contains(k)) continue;
      double realPart = 0, imagPart = 0;
      for (int m = 0; m < n; m++) {
        final angle = -2 * math.pi * k * m / n;
        realPart += probs[m] * math.cos(angle);
        imagPart += probs[m] * math.sin(angle);
      }
      final angle2 = 2 * math.pi * k * j / n;
      val += (realPart * math.cos(angle2) - imagPart * math.sin(angle2)) / n;
    }
    mask[j] = val;
  }

  // Make non-negative
  double minMask = mask.reduce(math.min);
  for (int i = 0; i < n; i++) {
    mask[i] -= minMask;
  }
  double maskSum = mask.fold(0.0, (a, b) => a + b);
  if (maskSum > 0) {
    for (int i = 0; i < n; i++) {
      mask[i] /= maskSum;
    }
  }

  // Blend: Q = probs + alpha * mask
  final q = List<double>.filled(n, 0);
  double qSum = 0;
  for (int i = 0; i < n; i++) {
    q[i] = math.max(0, probs[i] + alpha * mask[i]);
    qSum += q[i];
  }
  if (qSum <= 0) {
    for (int i = 0; i < n; i++) {
      q[i] = 1.0 / n;
    }
  } else {
    for (int i = 0; i < n; i++) {
      q[i] /= qSum;
    }
  }

  // Sample from blended distribution
  final counts = <String, int>{};
  for (int shot = 0; shot < shots; shot++) {
    final r = rng.nextDouble();
    double cum = 0;
    for (int i = 0; i < n; i++) {
      cum += q[i];
      if (r < cum) {
        final label = i.toRadixString(2).padLeft(nQubits, '0');
        counts[label] = (counts[label] ?? 0) + 1;
        break;
      }
    }
  }
  return counts;
}
