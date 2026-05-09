import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_lab/utils/complex.dart';
import 'package:quantum_lab/engine/quantum_computer.dart';
import 'package:quantum_lab/engine/gates.dart';
import 'package:quantum_lab/engine/quantum_state.dart';
import 'package:quantum_lab/engine/bloch.dart';

void main() {
  group('Complex arithmetic stress', () {
    test('multiplication is associative', () {
      final a = Complex(1.5, -2.3);
      final b = Complex(-0.7, 3.1);
      final c = Complex(2.0, -1.0);
      final ab_c = (a * b) * c;
      final a_bc = a * (b * c);
      expect(ab_c.re, closeTo(a_bc.re, 1e-10));
      expect(ab_c.im, closeTo(a_bc.im, 1e-10));
    });

    test('multiplication is distributive over addition', () {
      final a = Complex(1.0, 2.0);
      final b = Complex(3.0, -1.0);
      final c = Complex(-2.0, 0.5);
      final lhs = a * (b + c);
      final rhs = a * b + a * c;
      expect(lhs.re, closeTo(rhs.re, 1e-10));
      expect(lhs.im, closeTo(rhs.im, 1e-10));
    });

    test('division inverts multiplication', () {
      final a = Complex(3.0, 4.0);
      final b = Complex(1.0, -2.0);
      final result = (a * b) / b;
      expect(result.re, closeTo(a.re, 1e-10));
      expect(result.im, closeTo(a.im, 1e-10));
    });

    test('magnitude of product equals product of magnitudes', () {
      final a = Complex(3.0, 4.0);
      final b = Complex(1.0, -2.0);
      expect((a * b).magnitude, closeTo(a.magnitude * b.magnitude, 1e-10));
    });

    test('conjugate product gives magnitude squared', () {
      final a = Complex(3.0, 4.0);
      final prod = a * a.conjugate;
      expect(prod.re, closeTo(a.magnitudeSquared, 1e-10));
      expect(prod.im, closeTo(0.0, 1e-10));
    });

    test('polar construction round-trips', () {
      for (double mag = 0.1; mag <= 3.0; mag += 0.5) {
        for (double phase = -math.pi; phase <= math.pi; phase += 0.3) {
          final c = Complex.polar(mag, phase);
          expect(c.magnitude, closeTo(mag, 1e-10));
          if (mag > 1e-10) {
            // Phase might wrap around, compare via sin/cos
            expect(math.cos(c.phase), closeTo(math.cos(phase), 1e-10));
            expect(math.sin(c.phase), closeTo(math.sin(phase), 1e-10));
          }
        }
      }
    });

    test('zero element behaves correctly', () {
      final z = cZero;
      final a = Complex(5.0, -3.0);
      expect(a + z, a);
      expect((a * z).magnitude, closeTo(0.0, 1e-10));
    });

    test('negation works', () {
      final a = Complex(3.0, -2.0);
      final neg = -a;
      expect((a + neg).magnitude, closeTo(0.0, 1e-10));
    });

    test('scale works', () {
      final a = Complex(2.0, 3.0);
      final scaled = a.scale(4.0);
      expect(scaled.re, closeTo(8.0, 1e-10));
      expect(scaled.im, closeTo(12.0, 1e-10));
    });
  });

  group('Gate matrix unitarity', () {
    void checkUnitary(String name, GateMatrix mat) {
      // U†U = I: verify columns are orthonormal
      // mat = [a, b, c, d] where U = [[a,b],[c,d]]
      final a = mat[0], b = mat[1], c = mat[2], d = mat[3];

      // Column 1 norm: |a|² + |c|²  = 1
      final col1Norm = a.magnitudeSquared + c.magnitudeSquared;
      expect(col1Norm, closeTo(1.0, 1e-10), reason: '$name col1 norm');

      // Column 2 norm: |b|² + |d|² = 1
      final col2Norm = b.magnitudeSquared + d.magnitudeSquared;
      expect(col2Norm, closeTo(1.0, 1e-10), reason: '$name col2 norm');

      // Columns orthogonal: a†b + c†d = 0
      final dot = a.conjugate * b + c.conjugate * d;
      expect(dot.magnitude, closeTo(0.0, 1e-10), reason: '$name orthogonality');
    }

    test('H gate is unitary', () => checkUnitary('H', gateH()));
    test('X gate is unitary', () => checkUnitary('X', gateX()));
    test('Y gate is unitary', () => checkUnitary('Y', gateY()));
    test('Z gate is unitary', () => checkUnitary('Z', gateZ()));
    test('S gate is unitary', () => checkUnitary('S', gateS()));
    test('T gate is unitary', () => checkUnitary('T', gateT()));
    test('Sdg gate is unitary', () => checkUnitary('Sdg', gateSdg()));
    test('Tdg gate is unitary', () => checkUnitary('Tdg', gateTdg()));

    test('Ry gate is unitary for various angles', () {
      for (double theta = 0; theta <= 2 * math.pi; theta += 0.2) {
        checkUnitary('Ry($theta)', gateRy(theta));
      }
    });

    test('Rx gate is unitary for various angles', () {
      for (double theta = 0; theta <= 2 * math.pi; theta += 0.2) {
        checkUnitary('Rx($theta)', gateRx(theta));
      }
    });

    test('Rz gate is unitary for various angles', () {
      for (double theta = 0; theta <= 2 * math.pi; theta += 0.2) {
        checkUnitary('Rz($theta)', gateRz(theta));
      }
    });
  });

  group('Gate identities', () {
    void applyAndCheck(QuantumComputer qc, List<double> expected) {
      final probs = qc.state.probabilities;
      for (int i = 0; i < expected.length; i++) {
        expect(probs[i], closeTo(expected[i], 1e-8),
            reason: 'state[$i] expected ${expected[i]} got ${probs[i]}');
      }
    }

    test('X·X = I', () {
      final qc = QuantumComputer(nQubits: 1);
      qc.applyGate('X', 0);
      qc.applyGate('X', 0);
      applyAndCheck(qc, [1.0, 0.0]);
    });

    test('Y·Y = I', () {
      final qc = QuantumComputer(nQubits: 1);
      qc.applyGate('Y', 0);
      qc.applyGate('Y', 0);
      applyAndCheck(qc, [1.0, 0.0]);
    });

    test('Z·Z = I', () {
      final qc = QuantumComputer(nQubits: 1);
      qc.applyGate('Z', 0);
      qc.applyGate('Z', 0);
      applyAndCheck(qc, [1.0, 0.0]);
    });

    test('H·Z·H = X', () {
      final qc1 = QuantumComputer(nQubits: 1);
      qc1.applyGate('H', 0);
      qc1.applyGate('Z', 0);
      qc1.applyGate('H', 0);

      final qc2 = QuantumComputer(nQubits: 1);
      qc2.applyGate('X', 0);

      final p1 = qc1.state.probabilities;
      final p2 = qc2.state.probabilities;
      for (int i = 0; i < p1.length; i++) {
        expect(p1[i], closeTo(p2[i], 1e-8));
      }
    });

    test('S·S = Z', () {
      final qc1 = QuantumComputer(nQubits: 1);
      qc1.applyGate('H', 0);
      qc1.applyGate('S', 0);
      qc1.applyGate('S', 0);
      qc1.applyGate('H', 0);

      final qc2 = QuantumComputer(nQubits: 1);
      qc2.applyGate('H', 0);
      qc2.applyGate('Z', 0);
      qc2.applyGate('H', 0);

      final p1 = qc1.state.probabilities;
      final p2 = qc2.state.probabilities;
      for (int i = 0; i < p1.length; i++) {
        expect(p1[i], closeTo(p2[i], 1e-8));
      }
    });

    test('T·T = S (via phase detection)', () {
      final qc1 = QuantumComputer(nQubits: 1);
      qc1.applyGate('H', 0);
      qc1.applyGate('T', 0);
      qc1.applyGate('T', 0);

      final qc2 = QuantumComputer(nQubits: 1);
      qc2.applyGate('H', 0);
      qc2.applyGate('S', 0);

      // Compare full amplitudes
      for (int i = 0; i < 2; i++) {
        expect(qc1.state.amplitudes[i].re, closeTo(qc2.state.amplitudes[i].re, 1e-8));
        expect(qc1.state.amplitudes[i].im, closeTo(qc2.state.amplitudes[i].im, 1e-8));
      }
    });

    test('CNOT·CNOT = I', () {
      final qc = QuantumComputer(nQubits: 2);
      qc.applyGate('H', 0);
      qc.applyCnot(0, 1);
      qc.applyCnot(0, 1);
      // Should be back to H|0⟩ ⊗ |0⟩
      final probs = qc.state.probabilities;
      expect(probs[0], closeTo(0.5, 1e-8));
      expect(probs[1], closeTo(0.0, 1e-8));
      expect(probs[2], closeTo(0.5, 1e-8));
      expect(probs[3], closeTo(0.0, 1e-8));
    });

    test('SWAP·SWAP = I', () {
      final qc = QuantumComputer(nQubits: 2);
      qc.applyGate('H', 0);
      final before = List<Complex>.from(qc.state.amplitudes);
      qc.applySwap(0, 1);
      qc.applySwap(0, 1);
      for (int i = 0; i < 4; i++) {
        expect(qc.state.amplitudes[i].re, closeTo(before[i].re, 1e-8));
        expect(qc.state.amplitudes[i].im, closeTo(before[i].im, 1e-8));
      }
    });
  });

  group('QuantumState stress', () {
    test('normalization preserves state direction', () {
      final state = QuantumState(2);
      state.amplitudes[0] = Complex(3.0, 0.0);
      state.amplitudes[1] = Complex(0.0, 4.0);
      state.amplitudes[2] = cZero;
      state.amplitudes[3] = cZero;
      state.normalize();

      final probs = state.probabilities;
      final sum = probs.fold(0.0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-10));
      expect(probs[0] / probs[1], closeTo(9.0 / 16.0, 1e-8));
    });

    test('degenerate state normalization resets to |0⟩', () {
      final state = QuantumState(2);
      for (int i = 0; i < state.size; i++) {
        state.amplitudes[i] = cZero;
      }
      state.normalize();
      expect(state.amplitudes[0], cOne);
    });

    test('basisLabel generates correct labels', () {
      final state = QuantumState(3);
      expect(state.basisLabel(0), '000');
      expect(state.basisLabel(1), '001');
      expect(state.basisLabel(5), '101');
      expect(state.basisLabel(7), '111');
    });

    test('copy creates independent state', () {
      final state = QuantumState(2);
      state.amplitudes[0] = Complex(0.5, 0.5);
      final copy = state.copy();
      state.amplitudes[0] = cZero;
      expect(copy.amplitudes[0].re, closeTo(0.5, 1e-10));
    });

    test('reset returns to |0⟩', () {
      final state = QuantumState(3);
      state.amplitudes[0] = cZero;
      state.amplitudes[7] = cOne;
      state.reset();
      expect(state.amplitudes[0], cOne);
      for (int i = 1; i < state.size; i++) {
        expect(state.amplitudes[i].magnitude, closeTo(0.0, 1e-10));
      }
    });

    test('singleQubitState extracts correct reduced state', () {
      final qc = QuantumComputer(nQubits: 2, seed: 42);
      qc.applyGate('X', 0);
      final (alpha, beta) = qc.state.singleQubitState(0);
      expect(alpha.magnitudeSquared, closeTo(0.0, 1e-8));
      expect(beta.magnitudeSquared, closeTo(1.0, 1e-8));
    });
  });

  group('Multi-qubit stress tests', () {
    test('probabilities sum to 1.0 for all qubit counts 1-8', () {
      for (int n = 1; n <= 8; n++) {
        final qc = QuantumComputer(nQubits: n, seed: 42);
        // Apply H to all qubits
        for (int q = 0; q < n; q++) {
          qc.applyGate('H', q);
        }
        final probs = qc.state.probabilities;
        final sum = probs.fold(0.0, (a, b) => a + b);
        expect(sum, closeTo(1.0, 1e-8), reason: 'n=$n qubits');
      }
    });

    test('uniform superposition gives equal probabilities', () {
      for (int n = 1; n <= 6; n++) {
        final qc = QuantumComputer(nQubits: n);
        for (int q = 0; q < n; q++) {
          qc.applyGate('H', q);
        }
        final probs = qc.state.probabilities;
        final expected = 1.0 / (1 << n);
        for (int i = 0; i < probs.length; i++) {
          expect(probs[i], closeTo(expected, 1e-8),
              reason: 'n=$n state=$i');
        }
      }
    });

    test('8-qubit circuit maintains normalization through many gates', () {
      final qc = QuantumComputer(nQubits: 8, seed: 42);
      for (int q = 0; q < 8; q++) {
        qc.applyGate('H', q);
      }
      for (int q = 0; q < 7; q++) {
        qc.applyCnot(q, q + 1);
      }
      for (int q = 0; q < 8; q++) {
        qc.applyGate('T', q);
      }
      for (int q = 7; q >= 1; q--) {
        qc.applyCnot(q, q - 1);
      }
      for (int q = 0; q < 8; q++) {
        qc.applyGate('H', q);
      }
      final sum = qc.state.probabilities.fold(0.0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-6));
    });

    test('CNOT in all valid pairs on 4 qubits', () {
      for (int ctrl = 0; ctrl < 4; ctrl++) {
        for (int tgt = 0; tgt < 4; tgt++) {
          if (ctrl == tgt) continue;
          final qc = QuantumComputer(nQubits: 4);
          qc.applyGate('X', ctrl);
          qc.applyCnot(ctrl, tgt);
          final probs = qc.state.probabilities;
          final sum = probs.fold(0.0, (a, b) => a + b);
          expect(sum, closeTo(1.0, 1e-10),
              reason: 'CNOT ctrl=$ctrl tgt=$tgt');
        }
      }
    });

    test('SWAP is symmetric', () {
      final qc1 = QuantumComputer(nQubits: 3);
      qc1.applyGate('X', 0);
      qc1.applyGate('H', 1);
      qc1.applySwap(0, 2);

      final qc2 = QuantumComputer(nQubits: 3);
      qc2.applyGate('X', 0);
      qc2.applyGate('H', 1);
      qc2.applySwap(2, 0);

      for (int i = 0; i < 8; i++) {
        expect(qc1.state.amplitudes[i].re,
            closeTo(qc2.state.amplitudes[i].re, 1e-10));
        expect(qc1.state.amplitudes[i].im,
            closeTo(qc2.state.amplitudes[i].im, 1e-10));
      }
    });

    test('all four Bell states are correct', () {
      // |Φ+⟩ = (|00⟩ + |11⟩)/√2
      final qc1 = QuantumComputer(nQubits: 2);
      qc1.applyGate('H', 0);
      qc1.applyCnot(0, 1);
      expect(qc1.state.probabilities[0], closeTo(0.5, 1e-8));
      expect(qc1.state.probabilities[3], closeTo(0.5, 1e-8));

      // |Φ-⟩ = (|00⟩ - |11⟩)/√2
      final qc2 = QuantumComputer(nQubits: 2);
      qc2.applyGate('H', 0);
      qc2.applyCnot(0, 1);
      qc2.applyGate('Z', 0);
      expect(qc2.state.probabilities[0], closeTo(0.5, 1e-8));
      expect(qc2.state.probabilities[3], closeTo(0.5, 1e-8));

      // |Ψ+⟩ = (|01⟩ + |10⟩)/√2
      final qc3 = QuantumComputer(nQubits: 2);
      qc3.applyGate('H', 0);
      qc3.applyCnot(0, 1);
      qc3.applyGate('X', 0);
      expect(qc3.state.probabilities[1], closeTo(0.5, 1e-8));
      expect(qc3.state.probabilities[2], closeTo(0.5, 1e-8));

      // |Ψ-⟩ = (|01⟩ - |10⟩)/√2
      final qc4 = QuantumComputer(nQubits: 2);
      qc4.applyGate('H', 0);
      qc4.applyCnot(0, 1);
      qc4.applyGate('X', 0);
      qc4.applyGate('Z', 0);
      expect(qc4.state.probabilities[1], closeTo(0.5, 1e-8));
      expect(qc4.state.probabilities[2], closeTo(0.5, 1e-8));
    });
  });

  group('Measurement stress', () {
    test('measurement counts sum to shots', () {
      for (int shots in [1, 10, 100, 1000, 5000]) {
        final qc = QuantumComputer(nQubits: 2, seed: 42);
        qc.applyGate('H', 0);
        qc.applyCnot(0, 1);
        final counts = qc.measure(shots: shots);
        final total = counts.values.fold(0, (a, b) => a + b);
        expect(total, shots, reason: 'shots=$shots');
      }
    });

    test('deterministic state always measures the same', () {
      final qc = QuantumComputer(nQubits: 3, seed: 42);
      qc.applyGate('X', 1); // |010⟩
      final counts = qc.measure(shots: 500);
      expect(counts.length, 1);
      expect(counts['010'], 500);
    });

    test('measurement labels have correct length', () {
      for (int n = 1; n <= 6; n++) {
        final qc = QuantumComputer(nQubits: n, seed: 42);
        qc.applyGate('H', 0);
        final counts = qc.measure(shots: 100);
        for (final key in counts.keys) {
          expect(key.length, n, reason: 'n=$n label=$key');
        }
      }
    });

    test('exactProbabilities filters near-zero values', () {
      final qc = QuantumComputer(nQubits: 3);
      qc.applyGate('X', 0); // |100⟩
      final probs = qc.exactProbabilities();
      expect(probs.length, 1);
      expect(probs['100'], closeTo(1.0, 1e-8));
    });

    test('seeded measurement is reproducible', () {
      for (int trial = 0; trial < 5; trial++) {
        final qc1 = QuantumComputer(nQubits: 2, seed: 123);
        qc1.applyGate('H', 0);
        final c1 = qc1.measure(shots: 100);

        final qc2 = QuantumComputer(nQubits: 2, seed: 123);
        qc2.applyGate('H', 0);
        final c2 = qc2.measure(shots: 100);

        expect(c1, c2, reason: 'trial=$trial');
      }
    });
  });

  group('Algorithm stress', () {
    test('Grover search works for all 2-qubit targets', () {
      for (int target = 0; target < 4; target++) {
        final label = target.toRadixString(2).padLeft(2, '0');
        final qc = QuantumComputer(nQubits: 2, seed: 42);
        final counts = qc.groversSearch(label, shots: 1000);
        final targetCount = counts[label] ?? 0;
        // With 2 qubits Grover amplifies the target significantly
        expect(targetCount, greaterThan(200),
            reason: 'target=$label should be amplified (got $targetCount/1000)');
      }
    });

    test('Grover search works for 3-qubit targets', () {
      for (int target in [0, 3, 5, 7]) {
        final label = target.toRadixString(2).padLeft(3, '0');
        final qc = QuantumComputer(nQubits: 3, seed: 42);
        final counts = qc.groversSearch(label, shots: 1000);
        final maxEntry = counts.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        expect(maxEntry.key, label, reason: 'target=$label');
        expect(maxEntry.value, greaterThan(400), reason: 'target=$label amplification');
      }
    });

    test('Deutsch-Jozsa correctly classifies multiple balanced functions', () {
      final balancedFunctions = <int Function(int)>[
        (x) => x % 2,
        (x) => (x >> 1) % 2,
        (x) => (x & 1) ^ ((x >> 1) & 1),
      ];

      for (int i = 0; i < balancedFunctions.length; i++) {
        final qc = QuantumComputer(nQubits: 2, seed: 42);
        final counts = qc.deutschJozsa(balancedFunctions[i], shots: 500);
        final zeroCount = counts['00'] ?? 0;
        expect(zeroCount, lessThan(50),
            reason: 'balanced function $i should not give |00⟩');
      }
    });

    test('Deutsch-Jozsa correctly classifies constant functions', () {
      for (final constVal in [0, 1]) {
        final qc = QuantumComputer(nQubits: 2, seed: 42);
        final counts = qc.deutschJozsa((_) => constVal, shots: 500);
        final zeroCount = counts['00'] ?? 0;
        expect(zeroCount, greaterThan(400),
            reason: 'constant f(x)=$constVal should give |00⟩');
      }
    });
  });

  group('BlochCoords stress', () {
    test('|0⟩ maps to north pole', () {
      final coords = BlochCoords.fromState(cOne, cZero);
      expect(coords.x, closeTo(0.0, 1e-10));
      expect(coords.y, closeTo(0.0, 1e-10));
      expect(coords.z, closeTo(1.0, 1e-10));
    });

    test('|1⟩ maps to south pole', () {
      final coords = BlochCoords.fromState(cZero, cOne);
      expect(coords.x, closeTo(0.0, 1e-10));
      expect(coords.y, closeTo(0.0, 1e-10));
      expect(coords.z, closeTo(-1.0, 1e-10));
    });

    test('|+⟩ maps to +X axis', () {
      final s = Complex(1.0 / math.sqrt(2.0));
      final coords = BlochCoords.fromState(s, s);
      expect(coords.x, closeTo(1.0, 1e-8));
      expect(coords.y, closeTo(0.0, 1e-8));
      expect(coords.z, closeTo(0.0, 1e-8));
    });

    test('|-⟩ maps to -X axis', () {
      final s = Complex(1.0 / math.sqrt(2.0));
      final coords = BlochCoords.fromState(s, -s);
      expect(coords.x, closeTo(-1.0, 1e-8));
      expect(coords.z, closeTo(0.0, 1e-8));
    });

    test('|+i⟩ maps to +Y axis', () {
      final s = Complex(1.0 / math.sqrt(2.0));
      final si = Complex(0, 1.0 / math.sqrt(2.0));
      final coords = BlochCoords.fromState(s, si);
      expect(coords.y, closeTo(1.0, 1e-8));
      expect(coords.z, closeTo(0.0, 1e-8));
    });

    test('all Bloch vectors have unit length', () {
      final rng = math.Random(42);
      for (int i = 0; i < 100; i++) {
        final alpha = Complex(rng.nextDouble() - 0.5, rng.nextDouble() - 0.5);
        final beta = Complex(rng.nextDouble() - 0.5, rng.nextDouble() - 0.5);
        final coords = BlochCoords.fromState(alpha, beta);
        final length = math.sqrt(
            coords.x * coords.x + coords.y * coords.y + coords.z * coords.z);
        expect(length, closeTo(1.0, 1e-6), reason: 'trial $i');
      }
    });

    test('Bloch coords after each gate from |0⟩', () {
      // H|0⟩ → |+⟩ → (1,0,0)
      final qc = QuantumComputer(nQubits: 1);
      qc.applyGate('H', 0);
      final (a1, b1) = qc.state.singleQubitState(0);
      final c1 = BlochCoords.fromState(a1, b1);
      expect(c1.x, closeTo(1.0, 1e-6));

      // X|0⟩ → |1⟩ → (0,0,-1)
      final qc2 = QuantumComputer(nQubits: 1);
      qc2.applyGate('X', 0);
      final (a2, b2) = qc2.state.singleQubitState(0);
      final c2 = BlochCoords.fromState(a2, b2);
      expect(c2.z, closeTo(-1.0, 1e-6));
    });
  });

  group('Edge cases', () {
    test('single qubit is minimum', () {
      final qc = QuantumComputer(nQubits: 1);
      expect(qc.nQubits, 1);
      expect(qc.size, 2);
    });

    test('8 qubits is maximum practical size', () {
      final qc = QuantumComputer(nQubits: 8);
      expect(qc.size, 256);
      qc.applyGate('H', 0);
      final probs = qc.state.probabilities;
      expect(probs.length, 256);
    });

    test('qubit out of range throws', () {
      final qc = QuantumComputer(nQubits: 2);
      expect(() => qc.applyGate('H', 2), throwsRangeError);
      expect(() => qc.applyGate('H', -1), throwsRangeError);
    });

    test('CNOT same qubit throws', () {
      final qc = QuantumComputer(nQubits: 2);
      expect(() => qc.applyCnot(0, 0), throwsArgumentError);
    });

    test('unknown gate throws', () {
      final qc = QuantumComputer(nQubits: 1);
      expect(() => qc.applyGate('UNKNOWN', 0), throwsArgumentError);
    });

    test('SWAP same qubit is no-op', () {
      final qc = QuantumComputer(nQubits: 2);
      qc.applyGate('X', 0);
      final before = List<Complex>.from(qc.state.amplitudes);
      qc.applySwap(0, 0);
      for (int i = 0; i < 4; i++) {
        expect(qc.state.amplitudes[i].re, closeTo(before[i].re, 1e-10));
      }
    });

    test('reset works mid-computation', () {
      final qc = QuantumComputer(nQubits: 3);
      qc.applyGate('H', 0);
      qc.applyCnot(0, 1);
      qc.reset();
      expect(qc.state.amplitudes[0], cOne);
      for (int i = 1; i < 8; i++) {
        expect(qc.state.amplitudes[i].magnitude, closeTo(0.0, 1e-10));
      }
    });

    test('many sequential gates maintain normalization', () {
      final qc = QuantumComputer(nQubits: 4);
      final gates = ['H', 'X', 'Y', 'Z', 'S', 'T'];
      final rng = math.Random(42);

      for (int i = 0; i < 200; i++) {
        final gate = gates[rng.nextInt(gates.length)];
        final qubit = rng.nextInt(4);
        qc.applyGate(gate, qubit);

        if (i % 20 == 0) {
          final sum = qc.state.probabilities.fold(0.0, (a, b) => a + b);
          expect(sum, closeTo(1.0, 1e-4),
              reason: 'normalization after $i gates');
        }
      }

      final finalSum = qc.state.probabilities.fold(0.0, (a, b) => a + b);
      expect(finalSum, closeTo(1.0, 1e-4));
    });
  });
}
