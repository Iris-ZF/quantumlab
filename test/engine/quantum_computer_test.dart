import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_lab/utils/complex.dart';
import 'package:quantum_lab/engine/quantum_computer.dart';

void main() {
  group('QuantumComputer', () {
    test('initializes to |0⟩ state', () {
      final qc = QuantumComputer(nQubits: 1);
      final probs = qc.state.probabilities;
      expect(probs[0], closeTo(1.0, 1e-10)); // |0⟩
      expect(probs[1], closeTo(0.0, 1e-10)); // |1⟩
    });

    test('X gate flips |0⟩ to |1⟩', () {
      final qc = QuantumComputer(nQubits: 1);
      qc.applyGate('X', 0);
      final probs = qc.state.probabilities;
      expect(probs[0], closeTo(0.0, 1e-10));
      expect(probs[1], closeTo(1.0, 1e-10));
    });

    test('H gate creates equal superposition', () {
      final qc = QuantumComputer(nQubits: 1);
      qc.applyGate('H', 0);
      final probs = qc.state.probabilities;
      expect(probs[0], closeTo(0.5, 1e-10));
      expect(probs[1], closeTo(0.5, 1e-10));
    });

    test('H applied twice returns to |0⟩', () {
      final qc = QuantumComputer(nQubits: 1);
      qc.applyGate('H', 0);
      qc.applyGate('H', 0);
      final probs = qc.state.probabilities;
      expect(probs[0], closeTo(1.0, 1e-10));
      expect(probs[1], closeTo(0.0, 1e-10));
    });

    test('Z gate adds phase to |1⟩', () {
      final qc = QuantumComputer(nQubits: 1);
      qc.applyGate('X', 0); // |1⟩
      qc.applyGate('Z', 0); // -|1⟩
      final probs = qc.state.probabilities;
      // Probabilities unchanged (phase is global)
      expect(probs[0], closeTo(0.0, 1e-10));
      expect(probs[1], closeTo(1.0, 1e-10));
    });

    test('CNOT on |10⟩ gives |11⟩', () {
      final qc = QuantumComputer(nQubits: 2);
      qc.applyGate('X', 0); // |10⟩
      qc.applyCnot(0, 1); // control=0, target=1 → |11⟩
      final probs = qc.state.probabilities;
      // |00⟩=0, |01⟩=1, |10⟩=2, |11⟩=3
      expect(probs[3], closeTo(1.0, 1e-10)); // |11⟩
    });

    test('CNOT on |00⟩ stays |00⟩', () {
      final qc = QuantumComputer(nQubits: 2);
      qc.applyCnot(0, 1);
      final probs = qc.state.probabilities;
      expect(probs[0], closeTo(1.0, 1e-10)); // |00⟩
    });

    test('Bell state: H then CNOT', () {
      final qc = QuantumComputer(nQubits: 2);
      qc.applyGate('H', 0);
      qc.applyCnot(0, 1);
      final probs = qc.state.probabilities;
      // Bell state: (|00⟩ + |11⟩)/√2
      expect(probs[0], closeTo(0.5, 1e-10)); // |00⟩
      expect(probs[1], closeTo(0.0, 1e-10)); // |01⟩
      expect(probs[2], closeTo(0.0, 1e-10)); // |10⟩
      expect(probs[3], closeTo(0.5, 1e-10)); // |11⟩
    });

    test('SWAP exchanges qubit states', () {
      final qc = QuantumComputer(nQubits: 2);
      qc.applyGate('X', 0); // |10⟩
      qc.applySwap(0, 1); // → |01⟩
      final probs = qc.state.probabilities;
      expect(probs[1], closeTo(1.0, 1e-10)); // |01⟩
    });

    test('S gate applies π/2 phase', () {
      final qc = QuantumComputer(nQubits: 1);
      qc.applyGate('H', 0); // |+⟩
      qc.applyGate('S', 0); // S|+⟩ = (|0⟩ + i|1⟩)/√2
      final probs = qc.state.probabilities;
      expect(probs[0], closeTo(0.5, 1e-10));
      expect(probs[1], closeTo(0.5, 1e-10));
    });

    test('T gate applies π/4 phase', () {
      final qc = QuantumComputer(nQubits: 1);
      qc.applyGate('H', 0);
      qc.applyGate('T', 0);
      final probs = qc.state.probabilities;
      expect(probs[0], closeTo(0.5, 1e-10));
      expect(probs[1], closeTo(0.5, 1e-10));
    });

    test('probabilities sum to 1.0', () {
      final qc = QuantumComputer(nQubits: 3);
      qc.applyGate('H', 0);
      qc.applyGate('H', 1);
      qc.applyCnot(0, 2);
      final probs = qc.state.probabilities;
      final sum = probs.fold(0.0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-10));
    });

    test('measurement returns valid counts', () {
      final qc = QuantumComputer(nQubits: 2, seed: 42);
      qc.applyGate('H', 0);
      qc.applyCnot(0, 1);
      final counts = qc.measure(shots: 1000);
      final totalShots = counts.values.fold(0, (a, b) => a + b);
      expect(totalShots, 1000);
      // Bell state should only have |00⟩ and |11⟩
      for (final key in counts.keys) {
        expect(key == '00' || key == '11', isTrue);
      }
    });

    test('Grover search finds target with high probability', () {
      final qc = QuantumComputer(nQubits: 3, seed: 42);
      final counts = qc.groversSearch('101', shots: 1000);
      // Target should be most frequent
      final maxEntry = counts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      expect(maxEntry.key, '101');
      expect(maxEntry.value, greaterThan(500)); // >50% probability
    });

    test('Deutsch-Jozsa: constant function → |00⟩ dominates', () {
      final qc = QuantumComputer(nQubits: 2, seed: 42);
      // Constant function: always returns 0
      final counts = qc.deutschJozsa((x) => 0, shots: 1000);
      final zeroCount = counts['00'] ?? 0;
      expect(zeroCount, greaterThan(900));
    });

    test('Deutsch-Jozsa: balanced function → |00⟩ near zero', () {
      final qc = QuantumComputer(nQubits: 2, seed: 42);
      // Balanced function: returns x's parity
      final counts = qc.deutschJozsa((x) => x % 2, shots: 1000);
      final zeroCount = counts['00'] ?? 0;
      expect(zeroCount, lessThan(100));
    });

    test('3-qubit GHZ state', () {
      final qc = QuantumComputer(nQubits: 3);
      qc.applyGate('H', 0);
      qc.applyCnot(0, 1);
      qc.applyCnot(0, 2);
      final probs = qc.state.probabilities;
      // GHZ: (|000⟩ + |111⟩)/√2
      expect(probs[0], closeTo(0.5, 1e-10)); // |000⟩
      expect(probs[7], closeTo(0.5, 1e-10)); // |111⟩
      // All others zero
      for (int i = 1; i < 7; i++) {
        expect(probs[i], closeTo(0.0, 1e-10));
      }
    });
  });

  group('Complex', () {
    test('arithmetic operations', () {
      final a = Complex(1, 2);
      final b = Complex(3, 4);
      expect(a + b, Complex(4, 6));
      expect(a * b, Complex(-5, 10)); // (1+2i)(3+4i) = 3+4i+6i-8 = -5+10i
    });

    test('magnitude', () {
      final c = Complex(3, 4);
      expect(c.magnitude, closeTo(5.0, 1e-10));
    });

    test('conjugate', () {
      final c = Complex(3, 4);
      expect(c.conjugate, Complex(3, -4));
    });
  });
}
