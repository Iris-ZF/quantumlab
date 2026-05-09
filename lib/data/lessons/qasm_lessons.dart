import 'package:flutter/material.dart';
import '../../models/lesson.dart';

/// 5 QASM lessons — unlocked after completing all 10 quantum lessons.
const qasmLessons = <Lesson>[
  // ── QASM 1: Introduction to OpenQASM ──
  Lesson(
    id: 'qasm01',
    number: 1,
    title: 'Introduction to OpenQASM',
    subtitle: 'The quantum assembly language',
    icon: Icons.code,
    category: 'qasm',
    steps: [
      LessonStep(
        title: 'What is OpenQASM?',
        content: 'OpenQASM (Open Quantum Assembly Language) is a text-based language for describing '
            'quantum circuits. It was developed by IBM and is the standard format used by Qiskit, '
            'many quantum hardware providers, and research papers.\n\n'
            'Think of it like assembly language for quantum computers — '
            'low-level but universal and precise.',
      ),
      LessonStep(
        title: 'Basic Structure',
        content: 'An OpenQASM 2.0 program has this structure:\n\n'
            '  OPENQASM 2.0;\n'
            '  include "qelib1.inc";\n\n'
            '  qreg q[2];    // Declare 2 qubits\n'
            '  creg c[2];    // Declare 2 classical bits\n\n'
            '  h q[0];       // Apply H to qubit 0\n'
            '  cx q[0], q[1]; // CNOT: control=q0, target=q1\n\n'
            '  measure q -> c; // Measure all qubits\n\n'
            'Lines end with semicolons. Comments use //.',
      ),
      LessonStep(
        title: 'Your First QASM Program',
        type: LessonStepType.interactive,
        content: 'Open the QASM Editor and type:\n\n'
            '  qreg q[1];\n'
            '  h q[0];\n\n'
            'Then press Run. This creates a superposition on one qubit.\n'
            'You should see 50% |0⟩ and 50% |1⟩.',
        qasmSetup: 'qreg q[1];\nh q[0];',
        expectedOutcome: '50% |0⟩ and 50% |1⟩',
        hint: 'Type the QASM code exactly as shown, then tap Run.',
      ),
    ],
  ),

  // ── QASM 2: Single-Qubit Gates in QASM ──
  Lesson(
    id: 'qasm02',
    number: 2,
    title: 'Single-Qubit Gates in QASM',
    subtitle: 'h, x, y, z, s, t instructions',
    icon: Icons.text_snippet,
    category: 'qasm',
    steps: [
      LessonStep(
        title: 'Gate Syntax',
        content: 'Single-qubit gates follow the pattern:\n\n'
            '  gatename q[index];\n\n'
            'Available gates:\n'
            '  h q[0];    // Hadamard\n'
            '  x q[0];    // Pauli-X (NOT)\n'
            '  y q[0];    // Pauli-Y\n'
            '  z q[0];    // Pauli-Z\n'
            '  s q[0];    // S gate (π/2 phase)\n'
            '  t q[0];    // T gate (π/4 phase)\n\n'
            'Gates are applied in order, top to bottom.',
      ),
      LessonStep(
        title: 'Sequential Gates',
        type: LessonStepType.demonstration,
        content: 'Multiple gates on the same qubit execute left-to-right:\n\n'
            '  h q[0];   // |0⟩ → |+⟩\n'
            '  z q[0];   // |+⟩ → |-⟩\n'
            '  h q[0];   // |-⟩ → |1⟩\n\n'
            'This sequence transforms |0⟩ to |1⟩ using only H and Z!',
        qasmSetup: 'qreg q[1];\nh q[0];\nz q[0];\nh q[0];',
      ),
      LessonStep(
        title: 'Write: HZH = X',
        type: LessonStepType.interactive,
        content: 'In the QASM editor, write a program that applies H, Z, H to qubit 0.\n'
            'Verify it produces |1⟩ with 100% — this proves H·Z·H = X.',
        qasmSetup: 'qreg q[1];\n// Write your gates here:\n',
        expectedOutcome: '|1⟩ with 100% probability',
        hint: 'Add three lines: h q[0]; then z q[0]; then h q[0];',
      ),
    ],
  ),

  // ── QASM 3: Multi-Qubit Gates ──
  Lesson(
    id: 'qasm03',
    number: 3,
    title: 'Multi-Qubit Gates in QASM',
    subtitle: 'cx, swap, and entangled circuits',
    icon: Icons.account_tree,
    category: 'qasm',
    steps: [
      LessonStep(
        title: 'CNOT Syntax',
        content: 'The CNOT (controlled-X) gate uses the cx instruction:\n\n'
            '  cx q[control], q[target];\n\n'
            'If control is |1⟩, target gets flipped.\n\n'
            'Example — Bell state:\n'
            '  qreg q[2];\n'
            '  h q[0];\n'
            '  cx q[0], q[1];',
      ),
      LessonStep(
        title: 'SWAP Syntax',
        content: 'SWAP exchanges two qubit states:\n\n'
            '  swap q[0], q[1];\n\n'
            'Useful when qubits need to be adjacent for hardware constraints.',
      ),
      LessonStep(
        title: 'Write: GHZ State',
        type: LessonStepType.interactive,
        content: 'Write QASM for a 3-qubit GHZ state:\n'
            '  1. Declare 3 qubits\n'
            '  2. Apply H to q[0]\n'
            '  3. Apply CNOT from q[0] to q[1]\n'
            '  4. Apply CNOT from q[0] to q[2]\n\n'
            'Expected: only |000⟩ and |111⟩ at 50% each.',
        qasmSetup: 'qreg q[3];\n// Build the GHZ state:\n',
        expectedOutcome: 'Only |000⟩ and |111⟩, each ~50%',
        hint: 'h q[0]; then cx q[0], q[1]; then cx q[0], q[2];',
      ),
    ],
  ),

  // ── QASM 4: Building Algorithms ──
  Lesson(
    id: 'qasm04',
    number: 4,
    title: 'Building Algorithms in QASM',
    subtitle: 'Deutsch-Jozsa in assembly',
    icon: Icons.construction,
    category: 'qasm',
    steps: [
      LessonStep(
        title: 'Deutsch-Jozsa in QASM',
        content: 'Let\'s implement Deutsch-Jozsa for a balanced function:\n\n'
            '  qreg q[2];\n'
            '  // Step 1: Superposition\n'
            '  h q[0];\n'
            '  h q[1];\n'
            '  // Step 2: Oracle (balanced: CX acts as f)\n'
            '  cx q[0], q[1];\n'
            '  // Step 3: Final Hadamard\n'
            '  h q[0];\n'
            '  h q[1];\n\n'
            'If the result is NOT |00⟩, the function is balanced.',
      ),
      LessonStep(
        title: 'Run Deutsch-Jozsa',
        type: LessonStepType.demonstration,
        content: 'The oracle here uses CNOT as a balanced function. The result should show '
            'that |00⟩ has zero probability — confirming the function is balanced.',
        qasmSetup: 'qreg q[2];\n// Superposition\nh q[0];\nh q[1];\n// Oracle (balanced)\ncx q[0], q[1];\n// Final Hadamard\nh q[0];\nh q[1];',
      ),
      LessonStep(
        title: 'Write: Constant Oracle',
        type: LessonStepType.interactive,
        content: 'Modify the Deutsch-Jozsa QASM to use a CONSTANT function (no oracle gates). '
            'Verify that |00⟩ dominates the output.',
        qasmSetup: 'qreg q[2];\nh q[0];\nh q[1];\n// Add constant oracle here (hint: no gates needed!)\nh q[0];\nh q[1];',
        expectedOutcome: '|00⟩ with ~100% probability',
        hint: 'A constant function f(x)=0 means no phase flips — just remove the oracle!',
      ),
    ],
  ),

  // ── QASM 5: Advanced Patterns ──
  Lesson(
    id: 'qasm05',
    number: 5,
    title: 'Advanced QASM Patterns',
    subtitle: 'Teleportation & error detection',
    icon: Icons.science,
    category: 'qasm',
    steps: [
      LessonStep(
        title: 'Quantum Teleportation Setup',
        content: 'Quantum teleportation transfers a qubit state using entanglement + classical communication.\n\n'
            'The circuit:\n'
            '  qreg q[3];\n'
            '  // Prepare state to teleport (e.g., H on q0)\n'
            '  h q[0];\n'
            '  // Create Bell pair between q1 and q2\n'
            '  h q[1];\n'
            '  cx q[1], q[2];\n'
            '  // Bell measurement on q0, q1\n'
            '  cx q[0], q[1];\n'
            '  h q[0];\n\n'
            'After measurement + correction, q2 has the original state of q0.',
      ),
      LessonStep(
        title: 'Teleportation Circuit',
        type: LessonStepType.demonstration,
        content: 'This circuit prepares a superposition on q0, creates a Bell pair on q1-q2, '
            'then performs the teleportation protocol. The state of q0 is "moved" to q2.',
        qasmSetup: 'qreg q[3];\n// State to teleport\nh q[0];\n// Bell pair\nh q[1];\ncx q[1], q[2];\n// Bell measurement\ncx q[0], q[1];\nh q[0];',
      ),
      LessonStep(
        title: 'Bit-Flip Error Detection',
        content: 'Simple 3-qubit repetition code:\n\n'
            '  qreg q[3];\n'
            '  // Encode |ψ⟩ into 3 qubits\n'
            '  cx q[0], q[1];\n'
            '  cx q[0], q[2];\n'
            '  // Simulate bit-flip error on q1\n'
            '  x q[1];\n'
            '  // Syndrome detection\n'
            '  cx q[0], q[1];\n'
            '  cx q[0], q[2];\n\n'
            'Measurement of q1 and q2 reveals which qubit was flipped.',
      ),
      LessonStep(
        title: 'Write: Your Own Circuit',
        type: LessonStepType.interactive,
        content: 'Use everything you\'ve learned to write a QASM circuit of your own.\n\n'
            'Ideas:\n'
            '  - 4-qubit GHZ state\n'
            '  - Quantum full adder (Toffoli from CNOT + T gates)\n'
            '  - Grover oracle for a specific bitstring\n\n'
            'The QASM editor supports h, x, y, z, s, t, cx, swap.',
        qasmSetup: '// Your quantum program:\nqreg q[4];\n\n',
        hint: 'Start with a superposition (H gates) and build from there.',
      ),
    ],
  ),
];
