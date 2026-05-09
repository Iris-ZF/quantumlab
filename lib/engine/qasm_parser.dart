import 'quantum_computer.dart';

/// Parsed QASM instruction.
class QasmInstruction {
  final String gate;
  final List<int> qubits;
  final double? parameter;
  final int line;

  const QasmInstruction(this.gate, this.qubits, this.line, [this.parameter]);

  @override
  String toString() => '$gate ${qubits.join(", ")}${parameter != null ? " ($parameter)" : ""}';
}

/// Result of parsing + executing QASM.
class QasmResult {
  final List<QasmInstruction> instructions;
  final List<String> errors;
  final Map<String, int>? measurements;
  final Map<String, double>? probabilities;
  final bool success;

  const QasmResult({
    required this.instructions,
    required this.errors,
    this.measurements,
    this.probabilities,
    required this.success,
  });
}

/// Parse and execute OpenQASM-style instructions on a QuantumComputer.
///
/// Supported instructions:
///   qreg q[N];       — declare N qubits
///   h q[i];          — Hadamard
///   x q[i];          — Pauli-X
///   y q[i];          — Pauli-Y
///   z q[i];          — Pauli-Z
///   s q[i];          — S gate
///   t q[i];          — T gate
///   cx q[i], q[j];   — CNOT
///   swap q[i], q[j]; — SWAP
///   measure q;       — measure all
class QasmParser {
  int _nQubits = 2;

  QasmResult parse(String source, {int shots = 1024}) {
    final instructions = <QasmInstruction>[];
    final errors = <String>[];
    _nQubits = 2;

    final lines = source.split('\n');
    for (int lineNum = 0; lineNum < lines.length; lineNum++) {
      var line = lines[lineNum].trim();
      // Strip comments
      final commentIdx = line.indexOf('//');
      if (commentIdx >= 0) line = line.substring(0, commentIdx).trim();
      if (line.isEmpty) continue;

      // Remove trailing semicolons
      line = line.replaceAll(';', '').trim();
      if (line.isEmpty) continue;

      // Skip header lines
      final lower = line.toLowerCase();
      if (lower.startsWith('openqasm') || lower.startsWith('include') || lower.startsWith('creg')) {
        continue;
      }

      // Parse qreg declaration
      if (lower.startsWith('qreg')) {
        final match = RegExp(r'qreg\s+\w+\[(\d+)\]').firstMatch(lower);
        if (match != null) {
          _nQubits = int.parse(match.group(1)!);
        } else {
          errors.add('Line ${lineNum + 1}: Invalid qreg syntax');
        }
        continue;
      }

      // Parse gate instructions
      final inst = _parseInstruction(line, lineNum + 1, errors);
      if (inst != null) instructions.add(inst);
    }

    if (errors.isNotEmpty) {
      return QasmResult(instructions: instructions, errors: errors, success: false);
    }

    // Execute
    try {
      final qc = QuantumComputer(nQubits: _nQubits);
      for (final inst in instructions) {
        _execute(qc, inst);
      }
      final counts = qc.measure(shots: shots);
      final probs = qc.exactProbabilities();
      return QasmResult(
        instructions: instructions,
        errors: [],
        measurements: counts,
        probabilities: probs,
        success: true,
      );
    } catch (e) {
      return QasmResult(
        instructions: instructions,
        errors: ['Execution error: $e'],
        success: false,
      );
    }
  }

  QasmInstruction? _parseInstruction(String line, int lineNum, List<String> errors) {
    final lower = line.toLowerCase().trim();

    // measure
    if (lower.startsWith('measure')) {
      return QasmInstruction('measure', [], lineNum);
    }

    // Single-qubit gates: h, x, y, z, s, t
    for (final gate in ['h', 'x', 'y', 'z', 's', 't']) {
      if (lower.startsWith('$gate ') || lower == gate) {
        final qubit = _extractQubit(line, lineNum, errors);
        if (qubit != null) {
          return QasmInstruction(gate.toUpperCase(), [qubit], lineNum);
        }
        return null;
      }
    }

    // Two-qubit gates: cx/cnot, swap
    if (lower.startsWith('cx ') || lower.startsWith('cnot ')) {
      final qubits = _extractTwoQubits(line, lineNum, errors);
      if (qubits != null) {
        return QasmInstruction('CX', qubits, lineNum);
      }
      return null;
    }
    if (lower.startsWith('swap ')) {
      final qubits = _extractTwoQubits(line, lineNum, errors);
      if (qubits != null) {
        return QasmInstruction('SWAP', qubits, lineNum);
      }
      return null;
    }

    errors.add('Line $lineNum: Unknown instruction "$line"');
    return null;
  }

  int? _extractQubit(String line, int lineNum, List<String> errors) {
    final match = RegExp(r'q\[(\d+)\]').firstMatch(line);
    if (match == null) {
      errors.add('Line $lineNum: Expected q[N] qubit reference');
      return null;
    }
    final q = int.parse(match.group(1)!);
    if (q >= _nQubits) {
      errors.add('Line $lineNum: Qubit $q out of range (max ${_nQubits - 1})');
      return null;
    }
    return q;
  }

  List<int>? _extractTwoQubits(String line, int lineNum, List<String> errors) {
    final matches = RegExp(r'q\[(\d+)\]').allMatches(line).toList();
    if (matches.length < 2) {
      errors.add('Line $lineNum: Expected two qubit references q[i], q[j]');
      return null;
    }
    final q1 = int.parse(matches[0].group(1)!);
    final q2 = int.parse(matches[1].group(1)!);
    if (q1 >= _nQubits || q2 >= _nQubits) {
      errors.add('Line $lineNum: Qubit index out of range (max ${_nQubits - 1})');
      return null;
    }
    return [q1, q2];
  }

  void _execute(QuantumComputer qc, QasmInstruction inst) {
    switch (inst.gate) {
      case 'H':
      case 'X':
      case 'Y':
      case 'Z':
      case 'S':
      case 'T':
        qc.applyGate(inst.gate, inst.qubits[0]);
      case 'CX':
        qc.applyCnot(inst.qubits[0], inst.qubits[1]);
      case 'SWAP':
        qc.applySwap(inst.qubits[0], inst.qubits[1]);
      case 'measure':
        break; // handled after all gates
    }
  }
}
