import 'package:flutter/material.dart';

/// Types of quantum gates available in the circuit builder.
enum GateType {
  h('H', 'Hadamard', 1, Colors.blue, 'Creates superposition'),
  x('X', 'Pauli-X', 1, Colors.red, 'Bit flip (NOT gate)'),
  y('Y', 'Pauli-Y', 1, Colors.green, 'Bit + phase flip'),
  z('Z', 'Pauli-Z', 1, Colors.purple, 'Phase flip'),
  s('S', 'Phase (S)', 1, Colors.teal, 'π/2 phase rotation'),
  t('T', 'T Gate', 1, Colors.orange, 'π/4 phase rotation'),
  cnot('CNOT', 'CNOT', 2, Colors.indigo, 'Controlled-NOT'),
  swap('SWAP', 'SWAP', 2, Colors.brown, 'Swaps two qubits');

  const GateType(
    this.label,
    this.fullName,
    this.qubitCount,
    this.color,
    this.description,
  );

  final String label;
  final String fullName;
  final int qubitCount; // 1 = single-qubit, 2 = two-qubit
  final Color color;
  final String description;

  bool get isSingleQubit => qubitCount == 1;
  bool get isTwoQubit => qubitCount == 2;

  /// Gates available in the free tier.
  static const freeGates = [GateType.h, GateType.x, GateType.y, GateType.z, GateType.cnot];

  /// All gates (Pro tier).
  static const allGates = GateType.values;
}

/// A placed gate on the circuit grid.
class PlacedGate {
  final GateType type;
  final int targetQubit;
  final int timeStep;
  /// For two-qubit gates: the second qubit (control for CNOT, other for SWAP).
  final int? secondQubit;

  const PlacedGate({
    required this.type,
    required this.targetQubit,
    required this.timeStep,
    this.secondQubit,
  });

  PlacedGate copyWith({
    GateType? type,
    int? targetQubit,
    int? timeStep,
    int? secondQubit,
  }) {
    return PlacedGate(
      type: type ?? this.type,
      targetQubit: targetQubit ?? this.targetQubit,
      timeStep: timeStep ?? this.timeStep,
      secondQubit: secondQubit ?? this.secondQubit,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlacedGate &&
      type == other.type &&
      targetQubit == other.targetQubit &&
      timeStep == other.timeStep &&
      secondQubit == other.secondQubit;

  @override
  int get hashCode => Object.hash(type, targetQubit, timeStep, secondQubit);

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'targetQubit': targetQubit,
        'timeStep': timeStep,
        if (secondQubit != null) 'secondQubit': secondQubit,
      };

  factory PlacedGate.fromMap(Map<String, dynamic> map) {
    return PlacedGate(
      type: GateType.values.firstWhere((g) => g.name == map['type']),
      targetQubit: map['targetQubit'] as int,
      timeStep: map['timeStep'] as int,
      secondQubit: map['secondQubit'] as int?,
    );
  }
}
