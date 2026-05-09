import '../models/circuit.dart';
import '../models/gate.dart';

/// Export circuit as Qiskit Python code.
String exportQiskit(Circuit circuit) {
  final buf = StringBuffer();
  buf.writeln('from qiskit import QuantumCircuit');
  buf.writeln();
  buf.writeln('qc = QuantumCircuit(${circuit.nQubits})');
  buf.writeln();

  for (final gate in circuit.orderedGates) {
    switch (gate.type) {
      case GateType.h:
        buf.writeln('qc.h(${gate.targetQubit})');
      case GateType.x:
        buf.writeln('qc.x(${gate.targetQubit})');
      case GateType.y:
        buf.writeln('qc.y(${gate.targetQubit})');
      case GateType.z:
        buf.writeln('qc.z(${gate.targetQubit})');
      case GateType.s:
        buf.writeln('qc.s(${gate.targetQubit})');
      case GateType.t:
        buf.writeln('qc.t(${gate.targetQubit})');
      case GateType.cnot:
        if (gate.secondQubit != null) {
          buf.writeln('qc.cx(${gate.secondQubit}, ${gate.targetQubit})');
        }
      case GateType.swap:
        if (gate.secondQubit != null) {
          buf.writeln('qc.swap(${gate.targetQubit}, ${gate.secondQubit})');
        }
    }
  }

  buf.writeln();
  buf.writeln('qc.measure_all()');
  buf.writeln('print(qc.draw())');
  return buf.toString();
}

/// Export circuit as Cirq Python code.
String exportCirq(Circuit circuit) {
  final buf = StringBuffer();
  buf.writeln('import cirq');
  buf.writeln();
  buf.writeln('qubits = cirq.LineQubit.range(${circuit.nQubits})');
  buf.writeln('circuit = cirq.Circuit()');
  buf.writeln();

  for (final gate in circuit.orderedGates) {
    switch (gate.type) {
      case GateType.h:
        buf.writeln('circuit.append(cirq.H(qubits[${gate.targetQubit}]))');
      case GateType.x:
        buf.writeln('circuit.append(cirq.X(qubits[${gate.targetQubit}]))');
      case GateType.y:
        buf.writeln('circuit.append(cirq.Y(qubits[${gate.targetQubit}]))');
      case GateType.z:
        buf.writeln('circuit.append(cirq.Z(qubits[${gate.targetQubit}]))');
      case GateType.s:
        buf.writeln('circuit.append(cirq.S(qubits[${gate.targetQubit}]))');
      case GateType.t:
        buf.writeln('circuit.append(cirq.T(qubits[${gate.targetQubit}]))');
      case GateType.cnot:
        if (gate.secondQubit != null) {
          buf.writeln('circuit.append(cirq.CNOT(qubits[${gate.secondQubit}], qubits[${gate.targetQubit}]))');
        }
      case GateType.swap:
        if (gate.secondQubit != null) {
          buf.writeln('circuit.append(cirq.SWAP(qubits[${gate.targetQubit}], qubits[${gate.secondQubit}]))');
        }
    }
  }

  buf.writeln();
  buf.writeln('circuit.append(cirq.measure(*qubits, key="result"))');
  buf.writeln('print(circuit)');
  return buf.toString();
}

/// Export circuit as OpenQASM 2.0.
String exportQasm(Circuit circuit) {
  final buf = StringBuffer();
  buf.writeln('OPENQASM 2.0;');
  buf.writeln('include "qelib1.inc";');
  buf.writeln();
  buf.writeln('qreg q[${circuit.nQubits}];');
  buf.writeln('creg c[${circuit.nQubits}];');
  buf.writeln();

  for (final gate in circuit.orderedGates) {
    switch (gate.type) {
      case GateType.h:
        buf.writeln('h q[${gate.targetQubit}];');
      case GateType.x:
        buf.writeln('x q[${gate.targetQubit}];');
      case GateType.y:
        buf.writeln('y q[${gate.targetQubit}];');
      case GateType.z:
        buf.writeln('z q[${gate.targetQubit}];');
      case GateType.s:
        buf.writeln('s q[${gate.targetQubit}];');
      case GateType.t:
        buf.writeln('t q[${gate.targetQubit}];');
      case GateType.cnot:
        if (gate.secondQubit != null) {
          buf.writeln('cx q[${gate.secondQubit}], q[${gate.targetQubit}];');
        }
      case GateType.swap:
        if (gate.secondQubit != null) {
          buf.writeln('swap q[${gate.targetQubit}], q[${gate.secondQubit}];');
        }
    }
  }

  buf.writeln();
  buf.writeln('measure q -> c;');
  return buf.toString();
}
