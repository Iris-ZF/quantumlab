import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_lab/engine/qasm_parser.dart';

void main() {
  late QasmParser parser;

  setUp(() => parser = QasmParser());

  group('QASM parser edge cases', () {
    test('empty input succeeds with no instructions', () {
      final result = parser.parse('');
      expect(result.success, isTrue);
      expect(result.instructions, isEmpty);
    });

    test('comments-only input succeeds', () {
      final result = parser.parse('''
        // just comments
        // nothing else
      ''');
      expect(result.success, isTrue);
      expect(result.instructions, isEmpty);
    });

    test('whitespace-only input succeeds', () {
      final result = parser.parse('   \n\n   \n  ');
      expect(result.success, isTrue);
      expect(result.instructions, isEmpty);
    });

    test('header-only input succeeds', () {
      final result = parser.parse('''
        OPENQASM 2.0;
        include "qelib1.inc";
        qreg q[4];
        creg c[4];
      ''');
      expect(result.success, isTrue);
      expect(result.instructions, isEmpty);
    });

    test('multiple qreg declarations uses last one', () {
      final result = parser.parse('''
        qreg q[2];
        qreg q[4];
        h q[3];
      ''');
      expect(result.success, isTrue);
      expect(result.instructions.length, 1);
    });

    test('all single-qubit gates parse correctly', () {
      for (final gate in ['h', 'x', 'y', 'z', 's', 't']) {
        final result = parser.parse('''
          qreg q[1];
          $gate q[0];
        ''');
        expect(result.success, isTrue, reason: 'gate=$gate');
        expect(result.instructions.length, 1, reason: 'gate=$gate');
        expect(result.instructions[0].gate, gate.toUpperCase(), reason: 'gate=$gate');
      }
    });

    test('cx and cnot both work', () {
      final result1 = parser.parse('''
        qreg q[2];
        cx q[0], q[1];
      ''');
      expect(result1.success, isTrue);
      expect(result1.instructions[0].gate, 'CX');

      final result2 = parser.parse('''
        qreg q[2];
        cnot q[0], q[1];
      ''');
      expect(result2.success, isTrue);
      expect(result2.instructions[0].gate, 'CX');
    });

    test('measure instruction is recognized', () {
      final result = parser.parse('''
        qreg q[2];
        h q[0];
        measure q;
      ''');
      expect(result.success, isTrue);
      expect(result.instructions.length, 2);
      expect(result.instructions[1].gate, 'measure');
    });
  });

  group('QASM parser error handling', () {
    test('unknown gate name', () {
      final result = parser.parse('''
        qreg q[2];
        hadamard q[0];
      ''');
      expect(result.success, isFalse);
      expect(result.errors.any((e) => e.contains('Unknown')), isTrue);
    });

    test('qubit index out of range', () {
      final result = parser.parse('''
        qreg q[2];
        h q[5];
      ''');
      expect(result.success, isFalse);
      expect(result.errors.any((e) => e.contains('out of range')), isTrue);
    });

    test('missing qubit reference for single gate', () {
      final result = parser.parse('''
        qreg q[2];
        h;
      ''');
      expect(result.success, isFalse);
    });

    test('missing second qubit for cx', () {
      final result = parser.parse('''
        qreg q[2];
        cx q[0];
      ''');
      expect(result.success, isFalse);
      expect(result.errors.any((e) => e.contains('two qubit')), isTrue);
    });

    test('invalid qreg syntax', () {
      final result = parser.parse('qreg;');
      expect(result.errors.any((e) => e.contains('Invalid qreg')), isTrue);
    });

    test('multiple errors are collected', () {
      final result = parser.parse('''
        qreg q[2];
        foo q[0];
        bar q[1];
        baz q[0];
      ''');
      expect(result.success, isFalse);
      expect(result.errors.length, 3);
    });

    test('error messages include line numbers', () {
      final result = parser.parse('''
        qreg q[1];
        h q[5];
      ''');
      expect(result.success, isFalse);
      expect(result.errors.first, contains('Line'));
    });
  });

  group('QASM parser execution', () {
    test('single H gate produces 50/50', () {
      final result = parser.parse('''
        qreg q[1];
        h q[0];
      ''', shots: 1000);
      expect(result.success, isTrue);
      expect(result.probabilities, isNotNull);
      expect(result.probabilities!['0']!, closeTo(0.5, 0.05));
      expect(result.probabilities!['1']!, closeTo(0.5, 0.05));
    });

    test('X gate produces |1⟩', () {
      final result = parser.parse('''
        qreg q[1];
        x q[0];
      ''', shots: 100);
      expect(result.success, isTrue);
      expect(result.measurements!['1'], 100);
    });

    test('Bell state only produces 00 and 11', () {
      final result = parser.parse('''
        qreg q[2];
        h q[0];
        cx q[0], q[1];
      ''', shots: 1000);
      expect(result.success, isTrue);
      for (final key in result.measurements!.keys) {
        expect(key == '00' || key == '11', isTrue, reason: 'unexpected state: $key');
      }
    });

    test('GHZ state only produces 000 and 111', () {
      final result = parser.parse('''
        qreg q[3];
        h q[0];
        cx q[0], q[1];
        cx q[0], q[2];
      ''', shots: 1000);
      expect(result.success, isTrue);
      for (final key in result.measurements!.keys) {
        expect(key == '000' || key == '111', isTrue, reason: 'unexpected: $key');
      }
    });

    test('swap reverses qubit states', () {
      final result = parser.parse('''
        qreg q[2];
        x q[0];
        swap q[0], q[1];
      ''', shots: 100);
      expect(result.success, isTrue);
      expect(result.measurements!['01'], 100);
    });

    test('H-Z-H equals X', () {
      final result = parser.parse('''
        qreg q[1];
        h q[0];
        z q[0];
        h q[0];
      ''', shots: 100);
      expect(result.success, isTrue);
      expect(result.measurements!['1'], 100);
    });

    test('measurement counts match shot count', () {
      for (final shots in [1, 50, 500, 2000]) {
        final result = parser.parse('''
          qreg q[2];
          h q[0];
          h q[1];
        ''', shots: shots);
        expect(result.success, isTrue);
        final total = result.measurements!.values.fold(0, (a, b) => a + b);
        expect(total, shots, reason: 'shots=$shots');
      }
    });
  });

  group('QASM parser large circuits', () {
    test('50 gates in sequence', () {
      final buf = StringBuffer('qreg q[2];\n');
      for (int i = 0; i < 50; i++) {
        buf.writeln('h q[0];');
      }
      final result = parser.parse(buf.toString());
      expect(result.success, isTrue);
      expect(result.instructions.length, 50);
    });

    test('circuit with all gate types', () {
      final result = parser.parse('''
        OPENQASM 2.0;
        include "qelib1.inc";
        qreg q[3];

        h q[0];
        x q[1];
        y q[2];
        z q[0];
        s q[1];
        t q[2];
        cx q[0], q[1];
        swap q[1], q[2];
        measure q;
      ''', shots: 100);
      expect(result.success, isTrue);
      expect(result.instructions.length, 9);
      final total = result.measurements!.values.fold(0, (a, b) => a + b);
      expect(total, 100);
    });

    test('maximum qubit circuit (8 qubits)', () {
      final buf = StringBuffer('qreg q[8];\n');
      for (int i = 0; i < 8; i++) {
        buf.writeln('h q[$i];');
      }
      final result = parser.parse(buf.toString(), shots: 100);
      expect(result.success, isTrue);
      expect(result.instructions.length, 8);
      final total = result.measurements!.values.fold(0, (a, b) => a + b);
      expect(total, 100);
    });

    test('chained CNOT chain on 6 qubits', () {
      final buf = StringBuffer('qreg q[6];\nh q[0];\n');
      for (int i = 0; i < 5; i++) {
        buf.writeln('cx q[$i], q[${i + 1}];');
      }
      final result = parser.parse(buf.toString(), shots: 500);
      expect(result.success, isTrue);
      // Should produce GHZ-like state
      for (final key in result.measurements!.keys) {
        expect(key == '000000' || key == '111111', isTrue, reason: 'unexpected: $key');
      }
    });
  });

  group('QASM parser robustness', () {
    test('handles extra whitespace', () {
      final result = parser.parse('''
        qreg   q[2]  ;
        h   q[0]  ;
        cx   q[0] ,  q[1]  ;
      ''');
      expect(result.success, isTrue);
      expect(result.instructions.length, 2);
    });

    test('handles missing semicolons gracefully', () {
      final result = parser.parse('''
        qreg q[2]
        h q[0]
        cx q[0], q[1]
      ''');
      expect(result.success, isTrue);
      expect(result.instructions.length, 2);
    });

    test('handles mixed case gate names', () {
      final result = parser.parse('''
        qreg q[2];
        H q[0];
        CX q[0], q[1];
      ''');
      expect(result.success, isTrue);
      expect(result.instructions.length, 2);
    });

    test('inline comments after gates', () {
      final result = parser.parse('''
        qreg q[2];
        h q[0]; // create superposition
        cx q[0], q[1]; // entangle
      ''');
      expect(result.success, isTrue);
      expect(result.instructions.length, 2);
    });
  });
}
