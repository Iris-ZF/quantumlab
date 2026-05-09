import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/gate.dart' show GateType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../engine/export.dart';
import '../../providers/circuit_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../widgets/gate_palette.dart';
import '../widgets/circuit_grid.dart';
import '../widgets/bloch_sphere.dart';
import '../widgets/probability_histogram.dart';

class CircuitBuilderScreen extends ConsumerWidget {
  const CircuitBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circuitState = ref.watch(circuitProvider);
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;
    final isExtraWide = screenWidth > 1100;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            ref.read(circuitProvider.notifier).undo(),
        const SingleActivator(LogicalKeyboardKey.keyH): () =>
            ref.read(circuitProvider.notifier).selectGate(GateType.h),
        const SingleActivator(LogicalKeyboardKey.keyX): () =>
            ref.read(circuitProvider.notifier).selectGate(GateType.x),
        const SingleActivator(LogicalKeyboardKey.keyY): () =>
            ref.read(circuitProvider.notifier).selectGate(GateType.y),
        const SingleActivator(LogicalKeyboardKey.keyZ): () =>
            ref.read(circuitProvider.notifier).selectGate(GateType.z),
        const SingleActivator(LogicalKeyboardKey.keyC): () =>
            ref.read(circuitProvider.notifier).selectGate(GateType.cnot),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            ref.read(circuitProvider.notifier).selectGate(null),
        const SingleActivator(LogicalKeyboardKey.keyR): () =>
            ref.read(circuitProvider.notifier).runMeasurement(),
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            ref.read(circuitProvider.notifier).clear(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Circuit Builder'),
        actions: [
          // Qubit count
          _QubitControl(circuitState: circuitState, ref: ref, cs: cs),
          IconButton(
            icon: const Icon(Icons.undo, size: 20),
            tooltip: 'Undo (Ctrl+Z)',
            onPressed: ref.read(circuitProvider.notifier).canUndo
                ? () => ref.read(circuitProvider.notifier).undo()
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Clear circuit',
            onPressed: () => ref.read(circuitProvider.notifier).clear(),
          ),
          // Save & History
          IconButton(
            icon: const Icon(Icons.save_outlined, size: 20),
            tooltip: 'Save circuit',
            onPressed: () async {
              final auth = ref.read(authProvider);
              if (!auth.isSignedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sign in to save circuits'),
                    action: SnackBarAction(label: 'Sign in', onPressed: () => context.go('/settings')),
                  ),
                );
                return;
              }
              await ref.read(circuitProvider.notifier).saveToHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Circuit saved')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, size: 20),
            tooltip: 'Circuit history',
            onPressed: () => _showHistory(context, ref),
          ),
          // Export menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.ios_share, size: 20),
            tooltip: 'Export',
            onSelected: (format) => _export(context, ref, format),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'qiskit', child: Text('Export Qiskit')),
              const PopupMenuItem(value: 'cirq', child: Text('Export Cirq')),
              const PopupMenuItem(value: 'qasm', child: Text('Export OpenQASM')),
            ],
          ),
          // Run
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () {
                ref.read(circuitProvider.notifier).runMeasurement();
                FirebaseService.instance.recordExperience('run_circuit', data: {
                  'qubits': circuitState.circuit.nQubits,
                  'gates': circuitState.circuit.gates.length,
                });
              },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Run'),
              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const GatePalette().animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0, duration: 300.ms, curve: Curves.easeOut),
          const Divider(height: 1),
          Expanded(
            child: isExtraWide
                ? _ExtraWideLayout()
                : isWide
                    ? _WideLayout()
                    : _NarrowLayout(),
          ),
        ],
      ),
    )),
    );
  }

  void _export(BuildContext context, WidgetRef ref, String format) {
    final auth = ref.read(authProvider);
    if (!auth.isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Export requires QuantumLab Pro'),
          action: SnackBarAction(label: 'Upgrade', onPressed: () => context.go('/settings')),
        ),
      );
      return;
    }

    final circuit = ref.read(circuitProvider).circuit;
    String code;
    String label;
    switch (format) {
      case 'qiskit':
        code = exportQiskit(circuit);
        label = 'Qiskit';
      case 'cirq':
        code = exportCirq(circuit);
        label = 'Cirq';
      case 'qasm':
        code = exportQasm(circuit);
        label = 'OpenQASM';
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label Export'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              code,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authProvider);
    if (!auth.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sign in to view circuit history'),
          action: SnackBarAction(label: 'Sign in', onPressed: () => context.go('/settings')),
        ),
      );
      return;
    }

    final history = await FirebaseService.instance.getCircuitHistory(limit: 20);
    if (!context.mounted) return;

    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved circuits yet')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Circuit History'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (_, i) {
                final item = history[i];
                final name = item['name'] as String? ?? 'Untitled';
                final nQubits = item['nQubits'] as int? ?? 2;
                final gateCount = (item['gates'] as List?)?.length ?? 0;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text('$nQubits', style: TextStyle(color: cs.onPrimaryContainer)),
                  ),
                  title: Text(name),
                  subtitle: Text('$nQubits qubits, $gateCount gates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(circuitProvider.notifier).loadCircuit(item);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Loaded: $name')),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }
}

class _QubitControl extends StatelessWidget {
  final CircuitState circuitState;
  final WidgetRef ref;
  final ColorScheme cs;

  const _QubitControl({required this.circuitState, required this.ref, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Q:', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        IconButton(
          icon: const Icon(Icons.remove, size: 16),
          onPressed: circuitState.circuit.nQubits > 1
              ? () => ref.read(circuitProvider.notifier).setQubits(circuitState.circuit.nQubits - 1)
              : null,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
        Text('${circuitState.circuit.nQubits}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        IconButton(
          icon: const Icon(Icons.add, size: 16),
          onPressed: circuitState.circuit.nQubits < 8
              ? () => ref.read(circuitProvider.notifier).setQubits(circuitState.circuit.nQubits + 1)
              : null,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }
}

class _ExtraWideLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Expanded(flex: 4, child: CircuitGrid()),
        VerticalDivider(width: 1, color: cs.outlineVariant),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Expanded(child: BlochSphereWidget()),
                Divider(height: 1, color: cs.outlineVariant),
                const Expanded(child: ProbabilityHistogram()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Expanded(flex: 3, child: CircuitGrid()),
        VerticalDivider(width: 1, color: cs.outlineVariant),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const Expanded(
                child: Padding(padding: EdgeInsets.all(12), child: BlochSphereWidget()),
              ),
              Divider(height: 1, color: cs.outlineVariant),
              const Expanded(
                child: Padding(padding: EdgeInsets.all(12), child: ProbabilityHistogram()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const Expanded(flex: 3, child: CircuitGrid()),
        Divider(height: 1, color: cs.outlineVariant),
        Expanded(
          flex: 2,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'Histogram', icon: Icon(Icons.bar_chart, size: 16)),
                    Tab(text: 'Bloch', icon: Icon(Icons.public, size: 16)),
                  ],
                  labelStyle: const TextStyle(fontSize: 11),
                  labelColor: cs.primary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      Padding(padding: EdgeInsets.all(12), child: ProbabilityHistogram()),
                      Padding(padding: EdgeInsets.all(12), child: BlochSphereWidget()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
