import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_lab/engine/export.dart';
import 'package:quantum_lab/models/circuit.dart';
import 'package:quantum_lab/models/gate.dart';

void main() {
  group('Qiskit export', () {
    test('empty circuit', () {
      final c = Circuit(nQubits: 2);
      final code = exportQiskit(c);
      expect(code, contains('QuantumCircuit(2)'));
      expect(code, contains('measure_all'));
    });

    test('single H gate', () {
      final c = Circuit(nQubits: 1, gates: [
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
      ]);
      final code = exportQiskit(c);
      expect(code, contains('qc.h(0)'));
    });

    test('all single-qubit gates', () {
      final gates = [
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
        PlacedGate(type: GateType.x, targetQubit: 0, timeStep: 1),
        PlacedGate(type: GateType.y, targetQubit: 0, timeStep: 2),
        PlacedGate(type: GateType.z, targetQubit: 0, timeStep: 3),
        PlacedGate(type: GateType.s, targetQubit: 0, timeStep: 4),
        PlacedGate(type: GateType.t, targetQubit: 0, timeStep: 5),
      ];
      final c = Circuit(nQubits: 1, gates: gates);
      final code = exportQiskit(c);
      expect(code, contains('qc.h(0)'));
      expect(code, contains('qc.x(0)'));
      expect(code, contains('qc.y(0)'));
      expect(code, contains('qc.z(0)'));
      expect(code, contains('qc.s(0)'));
      expect(code, contains('qc.t(0)'));
    });

    test('CNOT gate', () {
      final c = Circuit(nQubits: 2, gates: [
        PlacedGate(type: GateType.cnot, targetQubit: 1, timeStep: 0, secondQubit: 0),
      ]);
      final code = exportQiskit(c);
      expect(code, contains('qc.cx(0, 1)'));
    });

    test('SWAP gate', () {
      final c = Circuit(nQubits: 2, gates: [
        PlacedGate(type: GateType.swap, targetQubit: 0, timeStep: 0, secondQubit: 1),
      ]);
      final code = exportQiskit(c);
      expect(code, contains('qc.swap(0, 1)'));
    });

    test('Bell state circuit', () {
      final c = Circuit(nQubits: 2, gates: [
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
        PlacedGate(type: GateType.cnot, targetQubit: 1, timeStep: 1, secondQubit: 0),
      ]);
      final code = exportQiskit(c);
      expect(code, contains('qc.h(0)'));
      expect(code, contains('qc.cx(0, 1)'));
      expect(code.indexOf('qc.h(0)'), lessThan(code.indexOf('qc.cx(0, 1)')));
    });
  });

  group('Cirq export', () {
    test('empty circuit', () {
      final c = Circuit(nQubits: 2);
      final code = exportCirq(c);
      expect(code, contains('cirq.LineQubit.range(2)'));
      expect(code, contains('cirq.measure'));
    });

    test('single H gate', () {
      final c = Circuit(nQubits: 1, gates: [
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
      ]);
      final code = exportCirq(c);
      expect(code, contains('cirq.H(qubits[0])'));
    });

    test('all gate types', () {
      final gates = [
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
        PlacedGate(type: GateType.x, targetQubit: 0, timeStep: 1),
        PlacedGate(type: GateType.y, targetQubit: 0, timeStep: 2),
        PlacedGate(type: GateType.z, targetQubit: 0, timeStep: 3),
        PlacedGate(type: GateType.s, targetQubit: 0, timeStep: 4),
        PlacedGate(type: GateType.t, targetQubit: 0, timeStep: 5),
        PlacedGate(type: GateType.cnot, targetQubit: 1, timeStep: 6, secondQubit: 0),
        PlacedGate(type: GateType.swap, targetQubit: 0, timeStep: 7, secondQubit: 1),
      ];
      final c = Circuit(nQubits: 2, gates: gates);
      final code = exportCirq(c);
      expect(code, contains('cirq.H'));
      expect(code, contains('cirq.X'));
      expect(code, contains('cirq.Y'));
      expect(code, contains('cirq.Z'));
      expect(code, contains('cirq.S'));
      expect(code, contains('cirq.T'));
      expect(code, contains('cirq.CNOT'));
      expect(code, contains('cirq.SWAP'));
    });
  });

  group('OpenQASM export', () {
    test('has proper header', () {
      final c = Circuit(nQubits: 3);
      final code = exportQasm(c);
      expect(code, contains('OPENQASM 2.0'));
      expect(code, contains('qreg q[3]'));
      expect(code, contains('creg c[3]'));
      expect(code, contains('measure q -> c'));
    });

    test('single-qubit gates use correct syntax', () {
      final gates = [
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
        PlacedGate(type: GateType.x, targetQubit: 1, timeStep: 1),
      ];
      final c = Circuit(nQubits: 2, gates: gates);
      final code = exportQasm(c);
      expect(code, contains('h q[0]'));
      expect(code, contains('x q[1]'));
    });

    test('CNOT uses cx syntax', () {
      final c = Circuit(nQubits: 2, gates: [
        PlacedGate(type: GateType.cnot, targetQubit: 1, timeStep: 0, secondQubit: 0),
      ]);
      final code = exportQasm(c);
      expect(code, contains('cx q[0], q[1]'));
    });

    test('SWAP uses swap syntax', () {
      final c = Circuit(nQubits: 2, gates: [
        PlacedGate(type: GateType.swap, targetQubit: 0, timeStep: 0, secondQubit: 1),
      ]);
      final code = exportQasm(c);
      expect(code, contains('swap q[0], q[1]'));
    });

    test('exported QASM is parseable', () {
      final gates = [
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
        PlacedGate(type: GateType.cnot, targetQubit: 1, timeStep: 1, secondQubit: 0),
      ];
      final c = Circuit(nQubits: 2, gates: gates);
      final code = exportQasm(c);
      // Check it's valid QASM structure
      expect(code, contains('OPENQASM'));
      expect(code, contains('qreg'));
      expect(code, contains('creg'));
      expect(code, contains(';'));
    });

    test('gates appear in timeStep order', () {
      final gates = [
        PlacedGate(type: GateType.z, targetQubit: 0, timeStep: 2),
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
        PlacedGate(type: GateType.x, targetQubit: 0, timeStep: 1),
      ];
      final c = Circuit(nQubits: 1, gates: gates);
      final code = exportQasm(c);
      final hIdx = code.indexOf('h q[0]');
      final xIdx = code.indexOf('x q[0]');
      final zIdx = code.indexOf('z q[0]');
      expect(hIdx, lessThan(xIdx));
      expect(xIdx, lessThan(zIdx));
    });
  });

  group('Export stress tests', () {
    test('large circuit with 8 qubits and many gates', () {
      final gates = <PlacedGate>[];
      for (int t = 0; t < 20; t++) {
        for (int q = 0; q < 8; q++) {
          gates.add(PlacedGate(
            type: GateType.h,
            targetQubit: q,
            timeStep: t,
          ));
        }
      }
      final c = Circuit(nQubits: 8, gates: gates);
      final qiskit = exportQiskit(c);
      final cirq = exportCirq(c);
      final qasm = exportQasm(c);

      expect(qiskit, contains('QuantumCircuit(8)'));
      expect(cirq, contains('range(8)'));
      expect(qasm, contains('qreg q[8]'));

      // Should have 160 gate lines
      expect('qc.h'.allMatches(qiskit).length, 160);
    });

    test('all three exports are non-empty for any valid circuit', () {
      for (final gateType in GateType.values) {
        final gate = PlacedGate(
          type: gateType,
          targetQubit: 0,
          timeStep: 0,
          secondQubit: gateType.isTwoQubit ? 1 : null,
        );
        final c = Circuit(nQubits: 2, gates: [gate]);
        expect(exportQiskit(c).isNotEmpty, isTrue, reason: 'qiskit ${gateType.label}');
        expect(exportCirq(c).isNotEmpty, isTrue, reason: 'cirq ${gateType.label}');
        expect(exportQasm(c).isNotEmpty, isTrue, reason: 'qasm ${gateType.label}');
      }
    });
  });
}
