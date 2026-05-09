import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/circuit_provider.dart';

/// Horizontal toolbar of draggable gates.
class GatePalette extends ConsumerWidget {
  const GatePalette({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGate = ref.watch(circuitProvider.select((s) => s.selectedGate));
    final isPro = ref.watch(authProvider.select((a) => a.isPro));
    final gates = isPro ? GateType.allGates : GateType.freeGates;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: gates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final gate = gates[index];
          final isSelected = selectedGate == gate;
          return _GateChip(
            gate: gate,
            isSelected: isSelected,
            onTap: () {
              ref.read(circuitProvider.notifier).selectGate(isSelected ? null : gate);
            },
          );
        },
      ),
    );
  }
}

class _GateChip extends StatelessWidget {
  final GateType gate;
  final bool isSelected;
  final VoidCallback onTap;

  const _GateChip({
    required this.gate,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Draggable<GateType>(
      data: gate,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: _GateBox(gate: gate, size: 52),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _GateBox(gate: gate, size: 52),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? gate.color.withValues(alpha: 0.15) : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? gate.color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GateBox(gate: gate, size: 36),
              const SizedBox(height: 2),
              Text(
                gate.fullName,
                style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateBox extends StatelessWidget {
  final GateType gate;
  final double size;

  const _GateBox({required this.gate, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: gate.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          gate.label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}
