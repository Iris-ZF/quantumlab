import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/bloch.dart';
import '../../engine/quantum_computer.dart';
import '../../models/gate.dart';
import '../../providers/circuit_provider.dart';

/// Bloch sphere visualization using CustomPainter.
class BlochSphereWidget extends ConsumerWidget {
  const BlochSphereWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circuitState = ref.watch(circuitProvider);
    final circuit = circuitState.circuit;
    final selectedQubit = circuitState.selectedQubit;
    final cs = Theme.of(context).colorScheme;

    // Simulate to get state vector, then extract single-qubit state
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

    final (alpha, beta) = qc.state.singleQubitState(selectedQubit);
    final coords = BlochCoords.fromState(alpha, beta);

    final hasGates = circuit.gates.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bloch Sphere',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (circuit.nQubits > 1) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'q$selectedQubit',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _BlochSpherePainter(
                coords: coords,
                primaryColor: cs.primary,
                outlineColor: cs.outlineVariant,
                arrowColor: cs.error,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: hasGates
              ? Text(
                  '(${coords.x.toStringAsFixed(2)}, ${coords.y.toStringAsFixed(2)}, ${coords.z.toStringAsFixed(2)})',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                )
              : Text(
                  'Add gates to see state evolution',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                ),
        ),
      ],
    );
  }
}

class _BlochSpherePainter extends CustomPainter {
  final BlochCoords coords;
  final Color primaryColor;
  final Color outlineColor;
  final Color arrowColor;

  _BlochSpherePainter({
    required this.coords,
    required this.primaryColor,
    required this.outlineColor,
    required this.arrowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final lightOutlinePaint = Paint()
      ..color = outlineColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Outer circle (Z-X plane projection)
    canvas.drawCircle(center, radius, outlinePaint);

    // Horizontal ellipse (X-Y equator)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    final equatorRect = Rect.fromCenter(
      center: Offset.zero,
      width: radius * 2,
      height: radius * 0.6,
    );
    canvas.drawOval(equatorRect, lightOutlinePaint);
    canvas.restore();

    // Vertical axis line
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      lightOutlinePaint,
    );
    // Horizontal axis line
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      lightOutlinePaint,
    );

    // Axis labels
    _drawLabel(canvas, '|0\u27E9', Offset(center.dx, center.dy - radius - 14), primaryColor);
    _drawLabel(canvas, '|1\u27E9', Offset(center.dx, center.dy + radius + 14), primaryColor);
    _drawLabel(canvas, '+X', Offset(center.dx + radius + 14, center.dy), outlineColor);
    _drawLabel(canvas, '+Y', Offset(center.dx - radius - 14, center.dy), outlineColor);

    // State vector arrow — project 3D Bloch coords to 2D
    // x -> right, y -> into screen (foreshortened), z -> up
    final projX = coords.x * radius;
    final projY = -coords.z * radius; // z maps to vertical (up = negative y)
    final arrowEnd = Offset(center.dx + projX, center.dy + projY);

    final arrowPaint = Paint()
      ..color = arrowColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, arrowEnd, arrowPaint);

    // Arrow tip
    canvas.drawCircle(arrowEnd, 5, Paint()..color = arrowColor);

    // Origin dot
    canvas.drawCircle(center, 3, Paint()..color = outlineColor);
  }

  void _drawLabel(Canvas canvas, String text, Offset position, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(position.dx - tp.width / 2, position.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BlochSpherePainter old) =>
      old.coords.x != coords.x || old.coords.y != coords.y || old.coords.z != coords.z;
}
