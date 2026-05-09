import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gate.dart';
import '../../providers/circuit_provider.dart';

/// Interactive circuit grid with qubit wires and drag-and-drop gate placement.
class CircuitGrid extends ConsumerWidget {
  const CircuitGrid({super.key});

  static const double _cellSize = 56.0;
  static const double _wireRowHeight = 64.0;
  static const double _labelWidth = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circuitState = ref.watch(circuitProvider);
    final circuit = circuitState.circuit;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Qubit labels
            Column(
              children: List.generate(circuit.nQubits, (q) {
                final isSelected = circuitState.selectedQubit == q;
                return GestureDetector(
                  onTap: () => ref.read(circuitProvider.notifier).selectQubit(q),
                  child: Container(
                    width: _labelWidth,
                    height: _wireRowHeight,
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? cs.primaryContainer : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'q$q',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            // Grid
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(circuit.nQubits, (qubit) {
                return SizedBox(
                  height: _wireRowHeight,
                  child: Row(
                    children: List.generate(circuit.columns, (timeStep) {
                      return _CircuitCell(
                        qubit: qubit,
                        timeStep: timeStep,
                        nQubits: circuit.nQubits,
                      );
                    }),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircuitCell extends ConsumerWidget {
  final int qubit;
  final int timeStep;
  final int nQubits;

  const _CircuitCell({
    required this.qubit,
    required this.timeStep,
    required this.nQubits,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circuitState = ref.watch(circuitProvider);
    final gate = circuitState.circuit.gateAt(qubit, timeStep);
    final selectedGate = circuitState.selectedGate;
    final cs = Theme.of(context).colorScheme;

    return DragTarget<GateType>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        _placeGate(ref, details.data, qubit, timeStep);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () {
            if (gate != null) {
              // Remove existing gate
              ref.read(circuitProvider.notifier).removeGateAt(qubit, timeStep);
            } else if (selectedGate != null) {
              _placeGate(ref, selectedGate, qubit, timeStep);
            }
          },
          onLongPress: () {
            if (gate != null) {
              ref.read(circuitProvider.notifier).removeGateAt(qubit, timeStep);
            }
          },
          child: Container(
            width: CircuitGrid._cellSize,
            height: CircuitGrid._wireRowHeight,
            decoration: BoxDecoration(
              color: isHovering ? cs.primaryContainer.withValues(alpha: 0.3) : null,
            ),
            child: CustomPaint(
              painter: _WirePainter(color: cs.outlineVariant),
              child: gate != null && gate.targetQubit == qubit
                  ? Center(child: _PlacedGateWidget(gate: gate))
                  : gate != null && gate.secondQubit == qubit
                      ? Center(child: _ControlDot(gate: gate, isTarget: false))
                      : null,
            ),
          ),
        );
      },
    );
  }

  void _placeGate(WidgetRef ref, GateType type, int qubit, int timeStep) {
    final notifier = ref.read(circuitProvider.notifier);
    if (type.isSingleQubit) {
      notifier.addGate(type, qubit, timeStep);
    } else {
      // Two-qubit gate: use next qubit as second qubit
      final secondQubit = qubit + 1 < nQubits ? qubit + 1 : qubit - 1;
      if (secondQubit >= 0 && secondQubit < nQubits) {
        notifier.addTwoQubitGate(type, qubit, secondQubit, timeStep);
      }
    }
  }
}

class _WirePainter extends CustomPainter {
  final Color color;
  _WirePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WirePainter old) => old.color != color;
}

class _PlacedGateWidget extends StatelessWidget {
  final PlacedGate gate;
  const _PlacedGateWidget({required this.gate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: gate.type.color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: gate.type.color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          gate.type.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ControlDot extends StatelessWidget {
  final PlacedGate gate;
  final bool isTarget;
  const _ControlDot({required this.gate, required this.isTarget});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: gate.type.color,
        shape: BoxShape.circle,
      ),
    );
  }
}
