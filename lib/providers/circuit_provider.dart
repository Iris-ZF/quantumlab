import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/circuit.dart';
import '../models/gate.dart';
import '../engine/quantum_computer.dart';
import '../services/firebase_service.dart';

/// Simulation results computed from the current circuit.
class SimulationResult {
  final Map<String, double> probabilities;
  final MeasurementResult? lastMeasurement;
  final List<double> rawProbabilities;

  const SimulationResult({
    required this.probabilities,
    this.lastMeasurement,
    required this.rawProbabilities,
  });

  static const empty = SimulationResult(
    probabilities: {},
    rawProbabilities: [],
  );
}

/// Combined state for the circuit builder.
class CircuitState {
  final Circuit circuit;
  final SimulationResult simulation;
  final int selectedQubit; // For Bloch sphere display
  final GateType? selectedGate; // Currently selected gate for placement

  const CircuitState({
    required this.circuit,
    required this.simulation,
    this.selectedQubit = 0,
    this.selectedGate,
  });

  CircuitState copyWith({
    Circuit? circuit,
    SimulationResult? simulation,
    int? selectedQubit,
    GateType? selectedGate,
    bool clearSelectedGate = false,
  }) {
    return CircuitState(
      circuit: circuit ?? this.circuit,
      simulation: simulation ?? this.simulation,
      selectedQubit: selectedQubit ?? this.selectedQubit,
      selectedGate: clearSelectedGate ? null : (selectedGate ?? this.selectedGate),
    );
  }
}

/// Main circuit state manager.
class CircuitNotifier extends Notifier<CircuitState> {
  final List<Circuit> _undoStack = [];
  static const _maxUndoDepth = 30;

  @override
  CircuitState build() {
    return CircuitState(
      circuit: Circuit(nQubits: 2),
      simulation: SimulationResult.empty,
    );
  }

  void _pushUndo() {
    _undoStack.add(state.circuit);
    if (_undoStack.length > _maxUndoDepth) _undoStack.removeAt(0);
  }

  bool get canUndo => _undoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isEmpty) return;
    final prev = _undoStack.removeLast();
    state = state.copyWith(circuit: prev);
    _simulate();
  }

  /// Re-simulate the circuit and update results.
  void _simulate() {
    final circuit = state.circuit;
    final qc = QuantumComputer(nQubits: circuit.nQubits, seed: 42);

    for (final gate in circuit.orderedGates) {
      switch (gate.type) {
        case GateType.h:
        case GateType.x:
        case GateType.y:
        case GateType.z:
        case GateType.s:
        case GateType.t:
          qc.applyGate(gate.type.label, gate.targetQubit);
        case GateType.cnot:
          if (gate.secondQubit != null) {
            qc.applyCnot(gate.secondQubit!, gate.targetQubit);
          }
        case GateType.swap:
          if (gate.secondQubit != null) {
            qc.applySwap(gate.targetQubit, gate.secondQubit!);
          }
      }
    }

    final probs = qc.exactProbabilities();
    final rawProbs = qc.state.probabilities;

    state = state.copyWith(
      simulation: SimulationResult(
        probabilities: probs,
        rawProbabilities: rawProbs,
      ),
    );
  }

  /// Add a single-qubit gate at position.
  void addGate(GateType type, int qubit, int timeStep) {
    _pushUndo();
    final gate = PlacedGate(type: type, targetQubit: qubit, timeStep: timeStep);
    state = state.copyWith(circuit: state.circuit.addGate(gate));
    _simulate();
  }

  /// Add a two-qubit gate.
  void addTwoQubitGate(GateType type, int qubit1, int qubit2, int timeStep) {
    _pushUndo();
    final gate = PlacedGate(
      type: type,
      targetQubit: qubit1,
      timeStep: timeStep,
      secondQubit: qubit2,
    );
    state = state.copyWith(circuit: state.circuit.addGate(gate));
    _simulate();
  }

  /// Remove gate at grid position.
  void removeGateAt(int qubit, int timeStep) {
    _pushUndo();
    state = state.copyWith(circuit: state.circuit.removeGateAt(qubit, timeStep));
    _simulate();
  }

  /// Select a gate type for placement.
  void selectGate(GateType? gate) {
    if (gate == null) {
      state = state.copyWith(clearSelectedGate: true);
    } else {
      state = state.copyWith(selectedGate: gate);
    }
  }

  /// Select qubit for Bloch sphere display.
  void selectQubit(int qubit) {
    state = state.copyWith(selectedQubit: qubit);
  }

  /// Change number of qubits.
  void setQubits(int n) {
    _pushUndo();
    final clamped = n.clamp(1, 8);
    state = state.copyWith(
      circuit: state.circuit.withQubits(clamped),
      selectedQubit: state.selectedQubit.clamp(0, clamped - 1),
    );
    _simulate();
  }

  /// Clear the circuit.
  void clear() {
    _pushUndo();
    state = state.copyWith(
      circuit: state.circuit.cleared(),
      simulation: SimulationResult.empty,
    );
  }

  /// Save circuit to Firebase history.
  Future<void> saveToHistory() async {
    await FirebaseService.instance.saveCircuitToHistory(state.circuit.toMap());
  }

  /// Load circuit from a saved map.
  void loadCircuit(Map<String, dynamic> data) {
    _pushUndo();
    final circuit = Circuit.fromMap(data);
    state = state.copyWith(circuit: circuit);
    _simulate();
  }

  /// Run a measurement with sampling.
  void runMeasurement({int shots = 1024}) {
    final circuit = state.circuit;
    final qc = QuantumComputer(nQubits: circuit.nQubits);

    for (final gate in circuit.orderedGates) {
      switch (gate.type) {
        case GateType.h:
        case GateType.x:
        case GateType.y:
        case GateType.z:
        case GateType.s:
        case GateType.t:
          qc.applyGate(gate.type.label, gate.targetQubit);
        case GateType.cnot:
          if (gate.secondQubit != null) {
            qc.applyCnot(gate.secondQubit!, gate.targetQubit);
          }
        case GateType.swap:
          if (gate.secondQubit != null) {
            qc.applySwap(gate.targetQubit, gate.secondQubit!);
          }
      }
    }

    final counts = qc.measure(shots: shots);
    final probs = qc.exactProbabilities();
    final rawProbs = qc.state.probabilities;

    state = state.copyWith(
      simulation: SimulationResult(
        probabilities: probs,
        lastMeasurement: counts,
        rawProbabilities: rawProbs,
      ),
    );
  }
}

final circuitProvider = NotifierProvider<CircuitNotifier, CircuitState>(
  CircuitNotifier.new,
);
