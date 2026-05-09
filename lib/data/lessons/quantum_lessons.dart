import 'package:flutter/material.dart';
import '../../models/lesson.dart';

/// All 10 quantum computing lessons.
const quantumLessons = <Lesson>[
  // ── LESSON 1: Classical Bits & Qubits ──
  Lesson(
    id: 'q01',
    number: 1,
    title: 'Classical Bits & Qubits',
    subtitle: 'From 0s and 1s to quantum superposition',
    icon: Icons.memory,
    isFree: true,
    steps: [
      LessonStep(
        title: 'What is a Bit?',
        content: 'A classical bit is the fundamental unit of information. It can be in one of two states:\n\n'
            '  0  (off, false)\n  1  (on, true)\n\n'
            'Every computer program, every photo, every message you send is encoded as sequences of 0s and 1s. '
            'A byte is 8 bits, giving 2^8 = 256 possible values.',
      ),
      LessonStep(
        title: 'Enter the Qubit',
        content: 'A qubit (quantum bit) is the quantum version of a classical bit. Like a classical bit, when you '
            'measure a qubit, you get either 0 or 1.\n\n'
            'But here\'s the key difference: before measurement, a qubit can exist in a superposition — '
            'a combination of both |0⟩ and |1⟩ simultaneously.\n\n'
            'We write the qubit state as:\n'
            '  |ψ⟩ = α|0⟩ + β|1⟩\n\n'
            'where α and β are complex numbers called amplitudes. The probability of measuring 0 is |α|² and '
            'measuring 1 is |β|².',
      ),
      LessonStep(
        title: 'The |0⟩ State',
        type: LessonStepType.demonstration,
        content: 'Let\'s start with the simplest qubit state: |0⟩.\n\n'
            'This is a qubit with α = 1 and β = 0. When measured, it always gives 0.\n\n'
            'Look at the histogram below — the probability of measuring |0⟩ is 100%.',
        qasmSetup: '// A single qubit in state |0⟩\n// No gates applied — this is the default state\nqreg q[1];',
      ),
      LessonStep(
        title: 'Try It Yourself',
        type: LessonStepType.interactive,
        content: 'Open the Circuit Builder and create a 1-qubit circuit. Without placing any gates, run the '
            'simulation.\n\nYou should see |0⟩ with 100% probability.\n\n'
            'Key takeaway: Every qubit starts in the |0⟩ state.',
        expectedOutcome: 'You should see |0⟩ with 100% probability.',
        hint: 'Just tap "Run" without adding any gates.',
      ),
      LessonStep(
        title: 'Quiz: Bits vs Qubits',
        type: LessonStepType.quiz,
        content: 'What makes a qubit fundamentally different from a classical bit?\n\n'
            'A) Qubits are faster\n'
            'B) Qubits can be in a superposition of 0 and 1 before measurement\n'
            'C) Qubits use less energy\n'
            'D) Qubits can store more than 2 values after measurement\n\n'
            'Answer: B — Before measurement, a qubit can be in a superposition α|0⟩ + β|1⟩. '
            'After measurement, it collapses to either 0 or 1, just like a classical bit.',
      ),
    ],
  ),

  // ── LESSON 2: The Hadamard Gate ──
  Lesson(
    id: 'q02',
    number: 2,
    title: 'The Hadamard Gate',
    subtitle: 'Creating superposition states',
    icon: Icons.blur_on,
    isFree: true,
    steps: [
      LessonStep(
        title: 'Your First Quantum Gate',
        content: 'The Hadamard gate (H) is the most important gate in quantum computing. '
            'It transforms a definite state into an equal superposition.\n\n'
            'Applied to |0⟩:\n'
            '  H|0⟩ = (|0⟩ + |1⟩) / √2 = |+⟩\n\n'
            'Applied to |1⟩:\n'
            '  H|1⟩ = (|0⟩ - |1⟩) / √2 = |-⟩\n\n'
            'The H gate matrix:\n'
            '  H = (1/√2) × [[1,  1],\n'
            '                  [1, -1]]',
      ),
      LessonStep(
        title: 'Superposition in Action',
        type: LessonStepType.demonstration,
        content: 'Watch what happens when we apply H to |0⟩:\n\n'
            'The qubit enters an equal superposition. Measuring it gives 0 or 1 each with 50% probability.\n\n'
            'This is fundamentally different from randomness — the qubit is in BOTH states simultaneously '
            'until measured.',
        qasmSetup: 'qreg q[1];\nh q[0];',
      ),
      LessonStep(
        title: 'H is Its Own Inverse',
        type: LessonStepType.demonstration,
        content: 'A remarkable property of the Hadamard gate: applying it twice returns you to the original state!\n\n'
            '  H(H|0⟩) = H|+⟩ = |0⟩\n\n'
            'This is because H × H = I (the identity matrix). Try it below — two H gates cancel out.',
        qasmSetup: 'qreg q[1];\nh q[0];\nh q[0];',
      ),
      LessonStep(
        title: 'Build a Superposition',
        type: LessonStepType.interactive,
        content: 'Open the Circuit Builder:\n'
            '1. Create a 1-qubit circuit\n'
            '2. Place an H gate on qubit 0\n'
            '3. Run the simulation\n\n'
            'You should see |0⟩ and |1⟩ each with ≈50% probability.',
        expectedOutcome: '50% |0⟩ and 50% |1⟩',
        hint: 'Drag the H gate from the palette onto the qubit wire.',
      ),
    ],
  ),

  // ── LESSON 3: Measurement & Probability ──
  Lesson(
    id: 'q03',
    number: 3,
    title: 'Measurement & Probability',
    subtitle: 'Collapsing the quantum state',
    icon: Icons.bar_chart,
    isFree: true,
    steps: [
      LessonStep(
        title: 'The Born Rule',
        content: 'When we measure a qubit in state |ψ⟩ = α|0⟩ + β|1⟩, we get:\n\n'
            '  Outcome 0 with probability |α|²\n'
            '  Outcome 1 with probability |β|²\n\n'
            'Since total probability must be 1:\n'
            '  |α|² + |β|² = 1\n\n'
            'This is called the Born Rule, named after Max Born (1926). '
            'It connects the abstract amplitudes to physically observable probabilities.',
      ),
      LessonStep(
        title: 'Measurement Collapses the State',
        content: 'After measurement, the superposition is destroyed. The qubit "collapses" into whichever '
            'state was observed.\n\n'
            'If you measure |+⟩ and get 0, the qubit is now in state |0⟩. '
            'If you measure again, you\'ll get 0 with certainty.\n\n'
            'This is why quantum computation must be done BEFORE measurement — '
            'you can\'t "peek" at a qubit without changing it.',
      ),
      LessonStep(
        title: 'Statistical Measurement',
        type: LessonStepType.demonstration,
        content: 'In real quantum computers (and our simulator), we run the circuit many times ("shots") '
            'to estimate probabilities.\n\n'
            'With 1024 shots on a |+⟩ state, you\'ll get approximately:\n'
            '  |0⟩: ~512 counts (~50%)\n'
            '  |1⟩: ~512 counts (~50%)\n\n'
            'But not exactly 512 — there\'s statistical noise, just like flipping a fair coin.',
        qasmSetup: 'qreg q[1];\nh q[0];',
      ),
      LessonStep(
        title: 'Multiple Qubits',
        type: LessonStepType.demonstration,
        content: 'With 2 qubits, we have 4 possible outcomes: |00⟩, |01⟩, |10⟩, |11⟩.\n\n'
            'Applying H to both qubits creates an equal superposition of ALL four states:\n'
            '  |ψ⟩ = ½(|00⟩ + |01⟩ + |10⟩ + |11⟩)\n\n'
            'Each outcome has 25% probability.',
        qasmSetup: 'qreg q[2];\nh q[0];\nh q[1];',
      ),
      LessonStep(
        title: 'Quiz: Probability',
        type: LessonStepType.quiz,
        content: 'If a qubit is in state |ψ⟩ = (√3/2)|0⟩ + (1/2)|1⟩, what is the probability of measuring |1⟩?\n\n'
            'A) 1/2\n'
            'B) 1/4\n'
            'C) 3/4\n'
            'D) √3/2\n\n'
            'Answer: B — The probability is |β|² = |1/2|² = 1/4 = 25%.',
      ),
    ],
  ),

  // ── LESSON 4: Pauli Gates ──
  Lesson(
    id: 'q04',
    number: 4,
    title: 'Pauli Gates (X, Y, Z)',
    subtitle: 'Rotations on the Bloch sphere',
    icon: Icons.rotate_right,
    steps: [
      LessonStep(
        title: 'The Pauli-X Gate (NOT)',
        content: 'The X gate is the quantum NOT gate. It flips |0⟩ to |1⟩ and vice versa:\n\n'
            '  X|0⟩ = |1⟩\n  X|1⟩ = |0⟩\n\n'
            'Matrix:\n  X = [[0, 1],\n       [1, 0]]\n\n'
            'On the Bloch sphere, X is a 180° rotation around the X-axis.',
      ),
      LessonStep(
        title: 'X Gate Demo',
        type: LessonStepType.demonstration,
        content: 'Watch the X gate flip |0⟩ to |1⟩. The Bloch sphere arrow moves from the north pole to the south pole.',
        qasmSetup: 'qreg q[1];\nx q[0];',
      ),
      LessonStep(
        title: 'The Pauli-Y Gate',
        content: 'The Y gate combines a bit flip with a phase flip:\n\n'
            '  Y|0⟩ = i|1⟩\n  Y|1⟩ = -i|0⟩\n\n'
            'Matrix:\n  Y = [[0, -i],\n       [i,  0]]\n\n'
            'On the Bloch sphere, Y is a 180° rotation around the Y-axis.',
      ),
      LessonStep(
        title: 'The Pauli-Z Gate',
        content: 'The Z gate flips the phase of |1⟩ without changing |0⟩:\n\n'
            '  Z|0⟩ = |0⟩\n  Z|1⟩ = -|1⟩\n\n'
            'Matrix:\n  Z = [[1,  0],\n       [0, -1]]\n\n'
            'Z doesn\'t change measurement probabilities (it only affects phase), but phases matter in '
            'multi-qubit circuits and interference.',
      ),
      LessonStep(
        title: 'Z Gate on Superposition',
        type: LessonStepType.demonstration,
        content: 'Apply H then Z to see phase in action:\n'
            '  H|0⟩ = |+⟩ = (|0⟩ + |1⟩)/√2\n'
            '  Z|+⟩ = |-⟩ = (|0⟩ - |1⟩)/√2\n\n'
            'The probabilities are still 50/50, but the PHASE has changed. '
            'If we apply another H, we get |1⟩ instead of |0⟩!',
        qasmSetup: 'qreg q[1];\nh q[0];\nz q[0];\nh q[0];',
      ),
      LessonStep(
        title: 'Build: X Gate Circuit',
        type: LessonStepType.interactive,
        content: 'Create a 1-qubit circuit and apply the X gate. Verify that measurement gives |1⟩ with 100% probability.',
        expectedOutcome: '|1⟩ with 100% probability',
        hint: 'Place a single X gate on qubit 0.',
      ),
    ],
  ),

  // ── LESSON 5: The Bloch Sphere ──
  Lesson(
    id: 'q05',
    number: 5,
    title: 'The Bloch Sphere',
    subtitle: 'Visualizing single-qubit states',
    icon: Icons.public,
    steps: [
      LessonStep(
        title: 'Geometry of a Qubit',
        content: 'Any single-qubit state can be written as:\n\n'
            '  |ψ⟩ = cos(θ/2)|0⟩ + e^(iφ)sin(θ/2)|1⟩\n\n'
            'where θ ∈ [0, π] and φ ∈ [0, 2π).\n\n'
            'This maps every qubit state to a point on a sphere:\n'
            '  x = sin(θ)cos(φ)\n'
            '  y = sin(θ)sin(φ)\n'
            '  z = cos(θ)\n\n'
            'This is the Bloch sphere. |0⟩ is the north pole (z=1), |1⟩ is the south pole (z=-1).',
      ),
      LessonStep(
        title: 'Key Points on the Sphere',
        content: 'North pole:  |0⟩         → (0, 0, 1)\n'
            'South pole:  |1⟩         → (0, 0, -1)\n'
            '+X axis:     |+⟩ = H|0⟩  → (1, 0, 0)\n'
            '-X axis:     |-⟩ = H|1⟩  → (-1, 0, 0)\n'
            '+Y axis:     |+i⟩        → (0, 1, 0)\n'
            '-Y axis:     |-i⟩        → (0, -1, 0)\n\n'
            'Gates are rotations on this sphere:\n'
            '  X → 180° around X-axis\n'
            '  Y → 180° around Y-axis\n'
            '  Z → 180° around Z-axis\n'
            '  H → 180° around the X+Z axis',
      ),
      LessonStep(
        title: 'Explore the Sphere',
        type: LessonStepType.interactive,
        content: 'In the Circuit Builder, try each gate one at a time on a single qubit and watch '
            'the Bloch sphere arrow move:\n\n'
            '1. Start with no gates (arrow at north pole = |0⟩)\n'
            '2. Apply X (arrow flips to south pole = |1⟩)\n'
            '3. Clear and apply H (arrow moves to +X axis = |+⟩)\n'
            '4. Clear and apply H then S (arrow moves toward +Y axis)',
        hint: 'Use the Bloch Sphere tab to see the arrow move as you add gates.',
      ),
    ],
  ),

  // ── LESSON 6: Phase Gates ──
  Lesson(
    id: 'q06',
    number: 6,
    title: 'Phase Gates (S, T)',
    subtitle: 'Precision phase rotations',
    icon: Icons.tune,
    steps: [
      LessonStep(
        title: 'What is Phase?',
        content: 'In |ψ⟩ = α|0⟩ + β|1⟩, the relative phase between α and β determines '
            'how the qubit interferes in circuits.\n\n'
            'Phase is invisible to single measurements, but crucial for quantum algorithms.',
      ),
      LessonStep(
        title: 'The S Gate (√Z)',
        content: 'The S gate applies a π/2 (90°) phase rotation:\n\n'
            '  S|0⟩ = |0⟩\n  S|1⟩ = i|1⟩\n\n'
            'Matrix:\n  S = [[1, 0],\n       [0, i]]\n\n'
            'On the Bloch sphere, S is a 90° rotation around the Z-axis. '
            'Note: S² = Z, so S is the "square root of Z".',
      ),
      LessonStep(
        title: 'The T Gate (√S)',
        content: 'The T gate applies a π/4 (45°) phase rotation:\n\n'
            '  T|0⟩ = |0⟩\n  T|1⟩ = e^(iπ/4)|1⟩\n\n'
            'Matrix:\n  T = [[1, 0],\n       [0, e^(iπ/4)]]\n\n'
            'T is the "π/8 gate" (the overall phase factor). It\'s critical for quantum error correction '
            'and is one of the hardest gates to implement on real quantum hardware.',
      ),
      LessonStep(
        title: 'Phase Changes Direction',
        type: LessonStepType.demonstration,
        content: 'Starting from |+⟩, the S gate rotates the state on the equator of the Bloch sphere:\n\n'
            '  H|0⟩ = |+⟩  (pointing along +X)\n'
            '  S|+⟩ = |+i⟩ (pointing along +Y)\n\n'
            'The probabilities are still 50/50, but the state has moved on the sphere.',
        qasmSetup: 'qreg q[1];\nh q[0];\ns q[0];',
      ),
    ],
  ),

  // ── LESSON 7: Entanglement (CNOT) ──
  Lesson(
    id: 'q07',
    number: 7,
    title: 'Entanglement (CNOT)',
    subtitle: 'Multi-qubit systems & Bell states',
    icon: Icons.link,
    steps: [
      LessonStep(
        title: 'The CNOT Gate',
        content: 'The Controlled-NOT (CNOT or CX) is the fundamental two-qubit gate.\n\n'
            'It has a control qubit and a target qubit:\n'
            '  If control = |0⟩: target unchanged\n'
            '  If control = |1⟩: target is flipped (X applied)\n\n'
            '  CNOT|00⟩ = |00⟩\n  CNOT|01⟩ = |01⟩\n  CNOT|10⟩ = |11⟩\n  CNOT|11⟩ = |10⟩',
      ),
      LessonStep(
        title: 'Creating Entanglement',
        content: 'The most powerful concept in quantum computing: entanglement.\n\n'
            'Apply H to qubit 0, then CNOT with qubit 0 as control:\n'
            '  1. |00⟩\n'
            '  2. H on q0: (|0⟩+|1⟩)/√2 ⊗ |0⟩ = (|00⟩+|10⟩)/√2\n'
            '  3. CNOT: (|00⟩+|11⟩)/√2\n\n'
            'This is a Bell state! The qubits are now entangled — measuring one instantly determines the other.',
      ),
      LessonStep(
        title: 'Bell State Demo',
        type: LessonStepType.demonstration,
        content: 'This circuit creates the Bell state |Φ+⟩ = (|00⟩+|11⟩)/√2.\n\n'
            'Notice: the only measurement outcomes are |00⟩ and |11⟩, each with 50%. '
            'You NEVER see |01⟩ or |10⟩ — the qubits are perfectly correlated.',
        qasmSetup: 'qreg q[2];\nh q[0];\ncx q[0], q[1];',
      ),
      LessonStep(
        title: 'Build a Bell State',
        type: LessonStepType.interactive,
        content: 'Create a 2-qubit circuit:\n'
            '1. Place H on qubit 0\n'
            '2. Place CNOT with control=q0, target=q1\n'
            '3. Run and verify only |00⟩ and |11⟩ appear',
        expectedOutcome: 'Only |00⟩ and |11⟩, each ~50%',
        hint: 'Place H first, then CNOT. The CNOT will automatically use the next qubit.',
      ),
      LessonStep(
        title: 'GHZ State (3 Qubits)',
        type: LessonStepType.demonstration,
        content: 'Extend entanglement to 3 qubits:\n  H on q0, CNOT q0→q1, CNOT q0→q2\n\n'
            'Result: (|000⟩ + |111⟩)/√2 — the GHZ state.\n'
            'All three qubits are entangled. Measuring any one determines the others.',
        qasmSetup: 'qreg q[3];\nh q[0];\ncx q[0], q[1];\ncx q[0], q[2];',
      ),
    ],
  ),

  // ── LESSON 8: SWAP & Circuit Identities ──
  Lesson(
    id: 'q08',
    number: 8,
    title: 'SWAP & Circuit Identities',
    subtitle: 'Equivalent circuits & simplification',
    icon: Icons.swap_horiz,
    steps: [
      LessonStep(
        title: 'The SWAP Gate',
        content: 'SWAP exchanges the states of two qubits:\n\n'
            '  SWAP|01⟩ = |10⟩\n  SWAP|10⟩ = |01⟩\n\n'
            'SWAP can be decomposed into 3 CNOT gates:\n'
            '  SWAP = CNOT(1,0) · CNOT(0,1) · CNOT(1,0)',
      ),
      LessonStep(
        title: 'SWAP Demo',
        type: LessonStepType.demonstration,
        content: 'We prepare |10⟩ (X on q0) then SWAP → |01⟩.',
        qasmSetup: 'qreg q[2];\nx q[0];\nswap q[0], q[1];',
      ),
      LessonStep(
        title: 'Circuit Identities',
        content: 'Important identities for circuit optimization:\n\n'
            '  H·H = I   (Hadamard is self-inverse)\n'
            '  X·X = I   (double NOT = nothing)\n'
            '  S·S = Z   (two S gates = Z)\n'
            '  T·T = S   (two T gates = S)\n'
            '  Z = S²    (Z is S squared)\n'
            '  S = T²    (S is T squared)\n\n'
            'These let you simplify circuits and reduce gate count.',
      ),
      LessonStep(
        title: 'Verify: T·T = S',
        type: LessonStepType.interactive,
        content: 'Build two circuits and compare their Bloch spheres:\n'
            '1. Circuit A: H, then S\n'
            '2. Circuit B: H, then T, then T\n\n'
            'Both should produce the same state.',
        expectedOutcome: 'Both circuits produce the same Bloch sphere position',
        hint: 'Build each circuit separately and compare the Bloch sphere coordinates.',
      ),
    ],
  ),

  // ── LESSON 9: Deutsch-Jozsa Algorithm ──
  Lesson(
    id: 'q09',
    number: 9,
    title: 'Deutsch-Jozsa Algorithm',
    subtitle: 'Quantum speedup for function testing',
    icon: Icons.speed,
    steps: [
      LessonStep(
        title: 'The Problem',
        content: 'Given a function f: {0,1}^n → {0,1}, determine if f is:\n'
            '  Constant: f(x) = 0 for all x, or f(x) = 1 for all x\n'
            '  Balanced: f(x) = 0 for exactly half the inputs\n\n'
            'Classically, you need 2^(n-1) + 1 queries in the worst case.\n'
            'Quantum: just ONE query! This is exponential speedup.',
      ),
      LessonStep(
        title: 'The Algorithm',
        content: 'Deutsch-Jozsa algorithm:\n\n'
            '1. Start with n qubits in |0...0⟩\n'
            '2. Apply H to each qubit → equal superposition\n'
            '3. Apply the oracle (encodes f as phase flips)\n'
            '4. Apply H to each qubit again\n'
            '5. Measure\n\n'
            'If f is constant → measure |0...0⟩ with certainty\n'
            'If f is balanced → NEVER measure |0...0⟩\n\n'
            'This is implemented in QuantumLab using the PFQVS engine.',
      ),
      LessonStep(
        title: 'Constant Function',
        type: LessonStepType.demonstration,
        content: 'Testing f(x) = 0 (constant). The algorithm returns |00⟩ with high probability, '
            'confirming the function is constant.',
        qasmSetup: '// Deutsch-Jozsa with constant f(x) = 0\n// Result: |00⟩ dominant → constant\nqreg q[2];\nh q[0];\nh q[1];\n// No oracle (f=0 means no phase flips)\nh q[0];\nh q[1];',
      ),
      LessonStep(
        title: 'Balanced Function',
        type: LessonStepType.demonstration,
        content: 'Testing a balanced function: f flips phase for half the inputs. '
            'The algorithm returns a non-|00⟩ state, confirming it\'s balanced.',
        qasmSetup: '// Deutsch-Jozsa with balanced f (CNOT acts as oracle)\nqreg q[2];\nh q[0];\nh q[1];\ncx q[0], q[1];\nh q[0];\nh q[1];',
      ),
    ],
  ),

  // ── LESSON 10: Grover's Search ──
  Lesson(
    id: 'q10',
    number: 10,
    title: "Grover's Search Algorithm",
    subtitle: 'Finding needles in haystacks',
    icon: Icons.search,
    steps: [
      LessonStep(
        title: 'The Search Problem',
        content: 'Given an unsorted database of N items, find one marked item.\n\n'
            'Classical: O(N) queries (check each item)\n'
            'Grover\'s: O(√N) queries — quadratic speedup!\n\n'
            'For N = 1,000,000:\n'
            '  Classical: ~1,000,000 queries\n'
            '  Grover\'s: ~1,000 queries',
      ),
      LessonStep(
        title: 'How It Works',
        content: 'Grover\'s algorithm has two key operations, repeated ~(π/4)√N times:\n\n'
            '1. Oracle: Flip the phase of the target state\n'
            '   |target⟩ → -|target⟩\n\n'
            '2. Diffusion: Reflect all amplitudes about the mean\n'
            '   Each amplitude a_i → 2·mean - a_i\n\n'
            'This gradually amplifies the target state\'s amplitude while '
            'suppressing all others.',
      ),
      LessonStep(
        title: 'Amplitude Amplification',
        content: 'Start with uniform superposition (all N states equal).\n\n'
            'Each Grover iteration:\n'
            '  1. Oracle marks the target (inverts its amplitude)\n'
            '  2. Diffusion boosts amplitudes below average and reduces those above\n'
            '  3. Target amplitude grows, others shrink\n\n'
            'After ~(π/4)√N iterations, the target has nearly 100% probability.\n\n'
            'Too many iterations and the amplitude overshoots and decreases!',
      ),
      LessonStep(
        title: 'Grover Demo (3 qubits)',
        type: LessonStepType.demonstration,
        content: 'Searching for |101⟩ among 8 states (3 qubits).\n'
            'Optimal iterations: round(π/4 · √8) ≈ 2.\n\n'
            'After 2 iterations, |101⟩ should dominate the histogram.',
        qasmSetup: '// Grover\'s search for |101⟩ on 3 qubits\n// Uses the built-in groversSearch algorithm\nqreg q[3];\nh q[0];\nh q[1];\nh q[2];\n// Oracle + Diffusion handled by PFQVS engine',
      ),
      LessonStep(
        title: 'Quiz: Grover Complexity',
        type: LessonStepType.quiz,
        content: 'For a database of 256 items, approximately how many Grover iterations are needed?\n\n'
            'A) 256\n'
            'B) 128\n'
            'C) 16\n'
            'D) 13\n\n'
            'Answer: D — Iterations = round(π/4 × √256) = round(π/4 × 16) = round(12.57) ≈ 13.',
      ),
    ],
  ),
];
