import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PfqvsScreen extends StatelessWidget {
  const PfqvsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        title: const Text('PFQVS Engine'),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.tertiaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.blur_on, size: 48, color: cs.onPrimaryContainer),
                  const SizedBox(height: 12),
                  Text(
                    'Perlin-Fourier Quantum\nVirtual Simulation',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Powered by novum-qvm',
                    style: TextStyle(color: cs.onPrimaryContainer.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _SectionTitle('Overview', cs),
            const _Body(
              'PFQVS (Perlin-Fourier Quantum Virtual Simulation) is a novel quantum circuit '
              'simulation approach developed for the novum-qvm library, published on PyPI. It combines '
              'three mathematical techniques to create a more physically-motivated quantum simulator:\n\n'
              '1. Perlin noise for state initialization\n'
              '2. Fourier-domain (FFT) gate execution\n'
              '3. Spectral decoherence modeling\n\n'
              'QuantumLab uses PFQVS as its core simulation engine, ported from Python/NumPy to Dart.',
            ),

            _SectionTitle('Layer 1: Perlin State Initialization', cs),
            const _Body(
              'In standard quantum simulators, qubits start in the |0⟩ state — a mathematically perfect, '
              'noise-free initialization. Real quantum hardware, however, has initialization errors.\n\n'
              'PFQVS initializes quantum states using 3D Perlin noise, a technique borrowed from computer '
              'graphics (invented by Ken Perlin in 1983 for the movie Tron). Each amplitude in the state '
              'vector is computed as:\n\n'
              '  ψ[i] = perlin(i/N, 0.1, seed·0.001) + i·perlin((i/N+0.5)%1, 0.2, seed·0.001)\n\n'
              'where perlin(x, y, z) is 3D gradient noise. This produces smooth, deterministic, '
              'reproducible initial states that approximate the "noisy" initialization of real quantum hardware.\n\n'
              'The state is then normalized: ψ → ψ/||ψ||.\n\n'
              'Benefit: PFQVS states are seeded (deterministic for a given seed) but non-trivial, '
              'making them useful for studying how algorithms perform under initialization noise.',
            ),

            _SectionTitle('Layer 2: O(N) Gate Execution', cs),
            const _Body(
              'Standard simulators build full 2^n × 2^n matrices via Kronecker products (O(4^n) space!). '
              'PFQVS uses an efficient O(N) pair-iteration algorithm:\n\n'
              'For a single-qubit gate U on qubit q:\n'
              '  1. Identify pairs of basis states that differ only in qubit q\n'
              '  2. For each pair (i, j) where i has qubit q = 0 and j has qubit q = 1:\n'
              '     [ψ\'[i]]   [U₀₀  U₀₁] [ψ[i]]\n'
              '     [ψ\'[j]] = [U₁₀  U₁₁] [ψ[j]]\n'
              '  3. No Kronecker product needed!\n\n'
              'Time complexity: O(2^n) instead of O(4^n)\n'
              'Space complexity: O(1) extra (in-place update)\n\n'
              'For CNOT gates, PFQVS uses computational-basis permutation: if the control qubit is |1⟩, '
              'flip the target bit in the basis state index. This is also O(N).\n\n'
              'The "FFT" in the name refers to the gate cache system, which precomputes '
              'Fourier-domain representations of gates for potential future optimizations with '
              'circulant gate decompositions.',
            ),

            _SectionTitle('Layer 3: Spectral Decoherence', cs),
            const _Body(
              'Real qubits lose coherence over time — a process called decoherence. PFQVS models this '
              'using octave-weighted Perlin noise that evolves with circuit depth.\n\n'
              'For each amplitude ψ[i], a damping factor is computed:\n\n'
              '  damping[i] = exp(-|E(i, t)| × dt)\n\n'
              'where E(i, t) is multi-octave Perlin noise:\n'
              '  E(i, t) = Σ_{o=1}^{octaves} (1/2^o) × perlin(i/N × 2^o, 0.1×o, seed + t×0.01)\n\n'
              'Key properties:\n'
              '  • Time-dependent: decoherence pattern changes with circuit depth t\n'
              '  • Spatially correlated: nearby basis states experience similar decoherence\n'
              '  • Multi-scale: octave weighting captures both local and global noise\n'
              '  • Controllable: dt parameter controls decoherence strength',
            ),

            _SectionTitle('Layer 4: Importance Sampling', cs),
            const _Body(
              'Standard measurement samples from Born-rule probabilities P(i) = |ψ[i]|². '
              'PFQVS uses FFT-based importance sampling to reduce measurement variance:\n\n'
              '1. Compute Born-rule probabilities: P[i] = |ψ[i]|²\n'
              '2. Compute the DFT of the probability distribution\n'
              '3. Keep only the top k spectral components (k = N × spectralFraction)\n'
              '4. Inverse DFT to get a spectral mask M[i]\n'
              '5. Blend: Q[i] = P[i] + α × M[i]\n'
              '6. Sample from Q instead of P\n\n'
              'This biases sampling toward the dominant modes of the probability distribution, '
              'reducing the number of shots needed for accurate estimates of high-probability states.\n\n'
              'Parameter α controls the blend strength (default 0.5). When α = 0, this reduces to '
              'standard Born-rule sampling.',
            ),

            _SectionTitle('How QuantumLab Uses PFQVS', cs),
            const _Body(
              'QuantumLab provides two simulation modes:\n\n'
              '• Educational Mode (default): Standard |0⟩ initialization with standard measurement. '
              'This is clearer for learning.\n\n'
              '• PFQVS Mode (advanced): Perlin initialization + decoherence + importance sampling. '
              'Shows how real-world noise affects quantum algorithms.\n\n'
              'Both modes use the O(N) pair-iteration gate execution from Layer 2.\n\n'
              'The Grover\'s search and Deutsch-Jozsa implementations use the PFQVS measurement system '
              'for more physically-motivated results.',
            ),

            _SectionTitle('Technical Reference', cs),
            const _Body(
              'Library: novum-qvm v1.2.0 (PyPI)\n'
              'Author: Amin Alogaili\n'
              'License: MIT\n'
              'Repository: github.com/iriszimmerfrau-collab/novum-qvm\n\n'
              'The Dart implementation in QuantumLab is a faithful port of the Python original, '
              'optimized for mobile performance with List<Complex> instead of NumPy arrays.\n\n'
              'Max qubits: 8 (256 amplitudes = ~4 KB memory)\n'
              'Gate execution: < 1ms for all supported gates\n'
              'Measurement: < 10ms for 1024 shots',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final ColorScheme cs;
  const _SectionTitle(this.title, this.cs);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6));
  }
}
