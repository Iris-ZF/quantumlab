import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_lab/engine/qasm_parser.dart';

void main() {
  group('QasmParser', () {
    late QasmParser parser;

    setUp(() => parser = QasmParser());

    test('parses basic single-qubit gates', () {
      final result = parser.parse('''
        qreg q[1];
        h q[0];
      ''');
      expect(result.success, isTrue);
      expect(result.instructions.length, 1);
      expect(result.instructions[0].gate, 'H');
    });

    test('Bell state circuit produces correct results', () {
      final result = parser.parse('''
        qreg q[2];
        h q[0];
        cx q[0], q[1];
      ''', shots: 1000);
      expect(result.success, isTrue);
      expect(result.measurements, isNotNull);
      // Bell state: only 00 and 11
      for (final key in result.measurements!.keys) {
        expect(key == '00' || key == '11', isTrue);
      }
    });

    test('reports errors for unknown gates', () {
      final result = parser.parse('''
        qreg q[1];
        foo q[0];
      ''');
      expect(result.success, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('reports errors for out-of-range qubits', () {
      final result = parser.parse('''
        qreg q[2];
        h q[5];
      ''');
      expect(result.success, isFalse);
    });

    test('handles comments and empty lines', () {
      final result = parser.parse('''
        // This is a comment
        qreg q[1];

        h q[0]; // inline comment
      ''');
      expect(result.success, isTrue);
      expect(result.instructions.length, 1);
    });

    test('handles OPENQASM header', () {
      final result = parser.parse('''
        OPENQASM 2.0;
        include "qelib1.inc";
        qreg q[2];
        h q[0];
        cx q[0], q[1];
      ''');
      expect(result.success, isTrue);
      expect(result.instructions.length, 2);
    });

    test('swap gate works', () {
      final result = parser.parse('''
        qreg q[2];
        x q[0];
        swap q[0], q[1];
      ''', shots: 100);
      expect(result.success, isTrue);
      // |10⟩ → SWAP → |01⟩
      final maxEntry = result.measurements!.entries.reduce((a, b) => a.value > b.value ? a : b);
      expect(maxEntry.key, '01');
    });
  });
}
