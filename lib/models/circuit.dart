import 'gate.dart';

/// A quantum circuit: a collection of gates placed on qubit wires at time steps.
class Circuit {
  final int nQubits;
  final List<PlacedGate> gates;
  final String name;

  Circuit({
    this.nQubits = 2,
    List<PlacedGate>? gates,
    this.name = 'Untitled Circuit',
  }) : gates = gates ?? [];

  /// Max time step used in the circuit.
  int get depth {
    if (gates.isEmpty) return 0;
    return gates.map((g) => g.timeStep).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Number of available time step columns (always at least depth + 1 for placing new gates).
  int get columns => depth + 4;

  /// Get gate at a specific grid position.
  PlacedGate? gateAt(int qubit, int timeStep) {
    for (final g in gates) {
      if (g.timeStep == timeStep) {
        if (g.targetQubit == qubit) return g;
        if (g.secondQubit == qubit) return g;
      }
    }
    return null;
  }

  /// Add a gate to the circuit.
  Circuit addGate(PlacedGate gate) {
    return Circuit(
      nQubits: nQubits,
      gates: [...gates, gate],
      name: name,
    );
  }

  /// Remove a gate from the circuit.
  Circuit removeGate(PlacedGate gate) {
    return Circuit(
      nQubits: nQubits,
      gates: gates.where((g) => g != gate).toList(),
      name: name,
    );
  }

  /// Remove gate at position.
  Circuit removeGateAt(int qubit, int timeStep) {
    final gate = gateAt(qubit, timeStep);
    if (gate == null) return this;
    return removeGate(gate);
  }

  /// Get gates ordered by time step for simulation.
  List<PlacedGate> get orderedGates {
    final sorted = List<PlacedGate>.from(gates);
    sorted.sort((a, b) => a.timeStep.compareTo(b.timeStep));
    return sorted;
  }

  /// Change qubit count.
  Circuit withQubits(int n) {
    // Remove gates that reference out-of-range qubits
    final validGates = gates.where((g) {
      if (g.targetQubit >= n) return false;
      if (g.secondQubit != null && g.secondQubit! >= n) return false;
      return true;
    }).toList();
    return Circuit(nQubits: n, gates: validGates, name: name);
  }

  /// Clear all gates.
  Circuit cleared() => Circuit(nQubits: nQubits, name: name);

  Circuit copyWith({int? nQubits, List<PlacedGate>? gates, String? name}) {
    return Circuit(
      nQubits: nQubits ?? this.nQubits,
      gates: gates ?? this.gates,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() => {
        'nQubits': nQubits,
        'name': name,
        'gates': gates.map((g) => g.toMap()).toList(),
      };

  factory Circuit.fromMap(Map<String, dynamic> map) {
    final gatesList = (map['gates'] as List?)
            ?.map((g) => PlacedGate.fromMap(g as Map<String, dynamic>))
            .toList() ??
        [];
    return Circuit(
      nQubits: map['nQubits'] as int? ?? 2,
      gates: gatesList,
      name: map['name'] as String? ?? 'Untitled Circuit',
    );
  }
}
