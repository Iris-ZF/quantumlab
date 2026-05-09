import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_lab/models/circuit.dart';
import 'package:quantum_lab/models/gate.dart';

void main() {
  group('Circuit', () {
    test('default circuit has 2 qubits and no gates', () {
      final c = Circuit();
      expect(c.nQubits, 2);
      expect(c.gates, isEmpty);
      expect(c.depth, 0);
    });

    test('addGate creates a new circuit with the gate', () {
      final c = Circuit(nQubits: 2);
      final gate = PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0);
      final c2 = c.addGate(gate);
      expect(c2.gates.length, 1);
      expect(c.gates, isEmpty);
    });

    test('removeGate creates a new circuit without the gate', () {
      final gate = PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0);
      final c = Circuit(nQubits: 2, gates: [gate]);
      final c2 = c.removeGate(gate);
      expect(c2.gates, isEmpty);
      expect(c.gates.length, 1);
    });

    test('removeGateAt removes by position', () {
      final gate = PlacedGate(type: GateType.x, targetQubit: 1, timeStep: 2);
      final c = Circuit(nQubits: 2, gates: [gate]);
      final c2 = c.removeGateAt(1, 2);
      expect(c2.gates, isEmpty);
    });

    test('removeGateAt with no gate at position returns same circuit', () {
      final c = Circuit(nQubits: 2);
      final c2 = c.removeGateAt(0, 0);
      expect(c2.gates, isEmpty);
    });

    test('gateAt finds gate by position', () {
      final gate = PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 3);
      final c = Circuit(nQubits: 2, gates: [gate]);
      expect(c.gateAt(0, 3), gate);
      expect(c.gateAt(1, 3), isNull);
      expect(c.gateAt(0, 0), isNull);
    });

    test('gateAt finds two-qubit gate on second qubit', () {
      final gate = PlacedGate(
        type: GateType.cnot,
        targetQubit: 0,
        timeStep: 1,
        secondQubit: 1,
      );
      final c = Circuit(nQubits: 2, gates: [gate]);
      expect(c.gateAt(0, 1), gate);
      expect(c.gateAt(1, 1), gate);
    });

    test('depth calculates correctly', () {
      final gates = [
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
        PlacedGate(type: GateType.x, targetQubit: 1, timeStep: 2),
        PlacedGate(type: GateType.z, targetQubit: 0, timeStep: 5),
      ];
      final c = Circuit(nQubits: 2, gates: gates);
      expect(c.depth, 6);
    });

    test('columns is at least depth + 4', () {
      final c = Circuit(nQubits: 2);
      expect(c.columns, 4);
      final gate = PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 10);
      final c2 = c.addGate(gate);
      expect(c2.columns, 15);
    });

    test('orderedGates sorts by timeStep', () {
      final gates = [
        PlacedGate(type: GateType.z, targetQubit: 0, timeStep: 3),
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
        PlacedGate(type: GateType.x, targetQubit: 0, timeStep: 1),
      ];
      final c = Circuit(nQubits: 1, gates: gates);
      final ordered = c.orderedGates;
      expect(ordered[0].type, GateType.h);
      expect(ordered[1].type, GateType.x);
      expect(ordered[2].type, GateType.z);
    });

    test('withQubits removes out-of-range gates', () {
      final gates = [
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
        PlacedGate(type: GateType.x, targetQubit: 3, timeStep: 1),
      ];
      final c = Circuit(nQubits: 4, gates: gates);
      final c2 = c.withQubits(2);
      expect(c2.nQubits, 2);
      expect(c2.gates.length, 1);
      expect(c2.gates[0].type, GateType.h);
    });

    test('withQubits removes two-qubit gates with out-of-range second qubit', () {
      final gate = PlacedGate(
        type: GateType.cnot,
        targetQubit: 0,
        timeStep: 0,
        secondQubit: 3,
      );
      final c = Circuit(nQubits: 4, gates: [gate]);
      final c2 = c.withQubits(2);
      expect(c2.gates, isEmpty);
    });

    test('cleared removes all gates, keeps qubits', () {
      final gates = [
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
        PlacedGate(type: GateType.x, targetQubit: 1, timeStep: 1),
      ];
      final c = Circuit(nQubits: 3, gates: gates);
      final c2 = c.cleared();
      expect(c2.nQubits, 3);
      expect(c2.gates, isEmpty);
    });

    test('copyWith works', () {
      final c = Circuit(nQubits: 2, name: 'test');
      final c2 = c.copyWith(nQubits: 4, name: 'updated');
      expect(c2.nQubits, 4);
      expect(c2.name, 'updated');
      expect(c.nQubits, 2);
    });
  });

  group('PlacedGate', () {
    test('equality', () {
      final g1 = PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 1);
      final g2 = PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 1);
      expect(g1, g2);
      expect(g1.hashCode, g2.hashCode);
    });

    test('inequality on different type', () {
      final g1 = PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 1);
      final g2 = PlacedGate(type: GateType.x, targetQubit: 0, timeStep: 1);
      expect(g1, isNot(g2));
    });

    test('inequality on different position', () {
      final g1 = PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 1);
      final g2 = PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 2);
      expect(g1, isNot(g2));
    });

    test('copyWith works', () {
      final g = PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 1);
      final g2 = g.copyWith(targetQubit: 2);
      expect(g2.targetQubit, 2);
      expect(g2.type, GateType.h);
      expect(g2.timeStep, 1);
    });

    test('two-qubit gate equality includes secondQubit', () {
      final g1 = PlacedGate(type: GateType.cnot, targetQubit: 0, timeStep: 0, secondQubit: 1);
      final g2 = PlacedGate(type: GateType.cnot, targetQubit: 0, timeStep: 0, secondQubit: 1);
      final g3 = PlacedGate(type: GateType.cnot, targetQubit: 0, timeStep: 0, secondQubit: 2);
      expect(g1, g2);
      expect(g1, isNot(g3));
    });
  });

  group('GateType', () {
    test('all gate types exist', () {
      expect(GateType.values.length, 8);
    });

    test('freeGates is a subset of allGates', () {
      for (final gate in GateType.freeGates) {
        expect(GateType.allGates.contains(gate), isTrue);
      }
    });

    test('single qubit gates have qubitCount 1', () {
      for (final gate in [GateType.h, GateType.x, GateType.y, GateType.z, GateType.s, GateType.t]) {
        expect(gate.isSingleQubit, isTrue);
        expect(gate.isTwoQubit, isFalse);
      }
    });

    test('two qubit gates have qubitCount 2', () {
      for (final gate in [GateType.cnot, GateType.swap]) {
        expect(gate.isTwoQubit, isTrue);
        expect(gate.isSingleQubit, isFalse);
      }
    });

    test('all gates have non-empty labels and descriptions', () {
      for (final gate in GateType.values) {
        expect(gate.label, isNotEmpty);
        expect(gate.fullName, isNotEmpty);
        expect(gate.description, isNotEmpty);
      }
    });
  });

  group('Serialization', () {
    test('PlacedGate round-trips through toMap/fromMap', () {
      final gate = PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 2);
      final restored = PlacedGate.fromMap(gate.toMap());
      expect(restored, gate);
    });

    test('PlacedGate two-qubit round-trips', () {
      final gate = PlacedGate(type: GateType.cnot, targetQubit: 0, timeStep: 1, secondQubit: 3);
      final restored = PlacedGate.fromMap(gate.toMap());
      expect(restored, gate);
      expect(restored.secondQubit, 3);
    });

    test('Circuit round-trips through toMap/fromMap', () {
      final circuit = Circuit(nQubits: 3, name: 'Test Circuit', gates: [
        PlacedGate(type: GateType.h, targetQubit: 0, timeStep: 0),
        PlacedGate(type: GateType.cnot, targetQubit: 1, timeStep: 1, secondQubit: 0),
        PlacedGate(type: GateType.x, targetQubit: 2, timeStep: 2),
      ]);
      final restored = Circuit.fromMap(circuit.toMap());
      expect(restored.nQubits, 3);
      expect(restored.name, 'Test Circuit');
      expect(restored.gates.length, 3);
      expect(restored.gates[0].type, GateType.h);
      expect(restored.gates[1].type, GateType.cnot);
      expect(restored.gates[1].secondQubit, 0);
      expect(restored.gates[2].type, GateType.x);
    });

    test('Circuit fromMap handles missing fields gracefully', () {
      final circuit = Circuit.fromMap({});
      expect(circuit.nQubits, 2);
      expect(circuit.name, 'Untitled Circuit');
      expect(circuit.gates, isEmpty);
    });

    test('all gate types round-trip through serialization', () {
      for (final gateType in GateType.values) {
        final gate = PlacedGate(
          type: gateType,
          targetQubit: 0,
          timeStep: 0,
          secondQubit: gateType.isTwoQubit ? 1 : null,
        );
        final restored = PlacedGate.fromMap(gate.toMap());
        expect(restored.type, gateType);
      }
    });
  });
}
