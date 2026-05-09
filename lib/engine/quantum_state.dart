import 'dart:math' as math;
import '../utils/complex.dart';

/// Quantum state vector for n qubits.
///
/// Convention: qubit 0 is most-significant bit in basis state labels.
/// For n qubits, the state vector has 2^n amplitudes.
class QuantumState {
  final int nQubits;
  final int size; // 2^nQubits
  final List<Complex> amplitudes;

  QuantumState(this.nQubits)
      : size = 1 << nQubits,
        amplitudes = List<Complex>.filled(1 << nQubits, cZero) {
    // Initialize to |0...0⟩
    amplitudes[0] = cOne;
  }

  QuantumState.fromAmplitudes(this.nQubits, List<Complex> amps)
      : size = 1 << nQubits,
        amplitudes = List<Complex>.from(amps) {
    assert(amps.length == size);
  }

  /// Normalize the state vector.
  void normalize() {
    double norm = 0.0;
    for (final a in amplitudes) {
      norm += a.magnitudeSquared;
    }
    if (norm < 1e-30) {
      // Degenerate state — reset to |0⟩
      for (int i = 0; i < size; i++) {
        amplitudes[i] = cZero;
      }
      amplitudes[0] = cOne;
      return;
    }
    final invNorm = 1.0 / math.sqrt(norm);
    for (int i = 0; i < size; i++) {
      amplitudes[i] = amplitudes[i].scale(invNorm);
    }
  }

  /// Get probability of measuring each basis state.
  List<double> get probabilities {
    final probs = List<double>.filled(size, 0.0);
    for (int i = 0; i < size; i++) {
      probs[i] = amplitudes[i].magnitudeSquared;
    }
    return probs;
  }

  /// Format basis state index as binary string.
  String basisLabel(int index) => index.toRadixString(2).padLeft(nQubits, '0');

  /// Reset to |0...0⟩.
  void reset() {
    for (int i = 0; i < size; i++) {
      amplitudes[i] = cZero;
    }
    amplitudes[0] = cOne;
  }

  /// Create a deep copy.
  QuantumState copy() => QuantumState.fromAmplitudes(nQubits, amplitudes);

  /// Extract single-qubit reduced state (partial trace over other qubits).
  /// Returns [alpha, beta] for the reduced density matrix diagonal,
  /// useful for Bloch sphere visualization.
  (Complex, Complex) singleQubitState(int qubit) {
    // Sum probabilities where target qubit is |0⟩ vs |1⟩
    Complex alpha = cZero;
    Complex beta = cZero;

    for (int i = 0; i < size; i++) {
      if (((i >> (nQubits - 1 - qubit)) & 1) == 0) {
        alpha = alpha + amplitudes[i];
      } else {
        beta = beta + amplitudes[i];
      }
    }

    // Normalize the reduced state
    final norm = math.sqrt(alpha.magnitudeSquared + beta.magnitudeSquared);
    if (norm < 1e-15) return (cOne, cZero);
    return (alpha.scale(1.0 / norm), beta.scale(1.0 / norm));
  }
}
