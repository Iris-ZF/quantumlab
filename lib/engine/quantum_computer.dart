import 'dart:math' as math;
import '../utils/complex.dart';
import 'gates.dart';
import 'quantum_state.dart';

/// Measurement result: map of basis state label -> count.
typedef MeasurementResult = Map<String, int>;

/// Quantum circuit simulator supporting up to 8 qubits.
///
/// Ported from novum-qvm PFQVS_QuantumComputer (Python/NumPy).
/// Uses O(N) pair-iteration for single-qubit gates (no Kronecker products).
class QuantumComputer {
  final QuantumState state;
  final math.Random _rng;

  QuantumComputer({required int nQubits, int? seed})
      : state = QuantumState(nQubits),
        _rng = math.Random(seed);

  int get nQubits => state.nQubits;
  int get size => state.size;

  /// Reset to |0...0⟩.
  void reset() => state.reset();

  // ── Single-qubit gates ──

  /// Apply a named single-qubit gate (H, X, Y, Z, S, T, SDG, TDG).
  void applyGate(String name, int target) {
    _validateQubit(target);
    final mat = getSingleQubitGate(name);
    _applySingleQubit(mat, target);
  }

  /// Apply RY(theta) rotation on target qubit.
  void applyRy(double theta, int target) {
    _validateQubit(target);
    _applySingleQubit(gateRy(theta), target);
  }

  /// Apply a 2x2 gate matrix to target qubit via O(N) pair iteration.
  /// Same algorithm as novum-qvm's _apply_fft_single_qubit.
  void _applySingleQubit(GateMatrix mat, int target) {
    final amps = state.amplitudes;
    final step = 1 << (nQubits - 1 - target);

    for (int i = 0; i < size; i++) {
      if (((i >> (nQubits - 1 - target)) & 1) == 0) {
        final j = i | step;
        final a = amps[i];
        final b = amps[j];
        amps[i] = mat[0] * a + mat[1] * b;
        amps[j] = mat[2] * a + mat[3] * b;
      }
    }
    state.normalize();
  }

  // ── Two-qubit gates ──

  /// CNOT: flip target qubit if control qubit is |1⟩.
  /// Same algorithm as novum-qvm's _apply_fft_cnot.
  void applyCnot(int control, int target) {
    _validateQubit(control);
    _validateQubit(target);
    if (control == target) throw ArgumentError('Control and target must differ');

    final amps = state.amplitudes;
    final newAmps = List<Complex>.filled(size, cZero);

    for (int idx = 0; idx < size; idx++) {
      final bits = _toBits(idx);
      if (bits[control] == 1) {
        bits[target] = 1 - bits[target];
      }
      final newIdx = _fromBits(bits);
      newAmps[newIdx] = amps[idx];
    }

    for (int i = 0; i < size; i++) {
      amps[i] = newAmps[i];
    }
  }

  /// SWAP: exchange two qubits.
  void applySwap(int qubit1, int qubit2) {
    _validateQubit(qubit1);
    _validateQubit(qubit2);
    if (qubit1 == qubit2) return;

    final amps = state.amplitudes;
    final newAmps = List<Complex>.filled(size, cZero);

    for (int idx = 0; idx < size; idx++) {
      final bits = _toBits(idx);
      final tmp = bits[qubit1];
      bits[qubit1] = bits[qubit2];
      bits[qubit2] = tmp;
      final newIdx = _fromBits(bits);
      newAmps[newIdx] = amps[idx];
    }

    for (int i = 0; i < size; i++) {
      amps[i] = newAmps[i];
    }
  }

  // ── Measurement ──

  /// Measure the quantum state, returning counts for each basis state.
  MeasurementResult measure({int shots = 1024}) {
    final probs = state.probabilities;
    final counts = <String, int>{};

    for (int s = 0; s < shots; s++) {
      final r = _rng.nextDouble();
      double cumulative = 0.0;
      for (int i = 0; i < size; i++) {
        cumulative += probs[i];
        if (r < cumulative) {
          final label = state.basisLabel(i);
          counts[label] = (counts[label] ?? 0) + 1;
          break;
        }
      }
    }
    return counts;
  }

  /// Get exact probabilities (no sampling noise).
  Map<String, double> exactProbabilities() {
    final probs = state.probabilities;
    final result = <String, double>{};
    for (int i = 0; i < size; i++) {
      if (probs[i] > 1e-10) {
        result[state.basisLabel(i)] = probs[i];
      }
    }
    return result;
  }

  // ── Algorithms ──

  /// Grover's search algorithm.
  /// Ported from novum-qvm: PFQVS_QuantumComputer.grovers_search
  MeasurementResult groversSearch(String target, {int shots = 1024}) {
    // Create uniform superposition
    final psi = List<Complex>.filled(size, Complex(1.0 / math.sqrt(size.toDouble())));

    int targetIdx;
    try {
      targetIdx = int.parse(target, radix: 2);
    } catch (_) {
      targetIdx = 0;
    }

    // Optimal iteration count: round(π/4 * √N)
    final nIter = math.max(1, (math.pi / 4.0 * math.sqrt(size.toDouble())).round());

    for (int iter = 0; iter < nIter; iter++) {
      // Oracle: flip phase of target
      psi[targetIdx] = -psi[targetIdx];

      // Diffusion: reflection about mean
      Complex mean = cZero;
      for (final a in psi) {
        mean = mean + a;
      }
      mean = mean.scale(1.0 / size.toDouble());
      for (int i = 0; i < size; i++) {
        psi[i] = mean.scale(2.0) - psi[i];
      }
    }

    // Normalize and set state
    double norm = 0.0;
    for (final a in psi) {
      norm += a.magnitudeSquared;
    }
    final invNorm = 1.0 / math.sqrt(math.max(norm, 1e-30));
    for (int i = 0; i < size; i++) {
      state.amplitudes[i] = psi[i].scale(invNorm);
    }

    return measure(shots: shots);
  }

  /// Deutsch-Jozsa algorithm.
  /// Ported from novum-qvm: PFQVS_QuantumComputer.deutsch_jozsa
  MeasurementResult deutschJozsa(int Function(int) f, {int shots = 1024}) {
    // Initialize to superposition |+...+⟩
    final psi = List<Complex>.filled(size, Complex(1.0 / math.sqrt(size.toDouble())));

    // Apply oracle: flip phase where f(x) = 1
    for (int x = 0; x < size; x++) {
      if (f(x) == 1) {
        psi[x] = -psi[x];
      }
    }

    // Final Hadamard layer via simple application
    // For educational clarity, apply H to each qubit
    double norm = 0.0;
    for (final a in psi) {
      norm += a.magnitudeSquared;
    }
    final invNorm = 1.0 / math.sqrt(math.max(norm, 1e-30));
    for (int i = 0; i < size; i++) {
      state.amplitudes[i] = psi[i].scale(invNorm);
    }

    // Apply H to each qubit
    for (int q = 0; q < nQubits; q++) {
      _applySingleQubit(gateH(), q);
    }

    return measure(shots: shots);
  }

  // ── Helpers ──

  List<int> _toBits(int index) {
    final bits = List<int>.filled(nQubits, 0);
    for (int q = 0; q < nQubits; q++) {
      bits[q] = (index >> (nQubits - 1 - q)) & 1;
    }
    return bits;
  }

  int _fromBits(List<int> bits) {
    int index = 0;
    for (int q = 0; q < nQubits; q++) {
      if (bits[q] == 1) {
        index |= 1 << (nQubits - 1 - q);
      }
    }
    return index;
  }

  void _validateQubit(int q) {
    if (q < 0 || q >= nQubits) {
      throw RangeError('Qubit index $q out of range [0, ${nQubits - 1}]');
    }
  }
}
