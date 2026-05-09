import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../engine/qasm_parser.dart';

class QasmEditorScreen extends ConsumerStatefulWidget {
  final String? initialCode;
  const QasmEditorScreen({super.key, this.initialCode});

  @override
  ConsumerState<QasmEditorScreen> createState() => _QasmEditorScreenState();
}

class _QasmEditorScreenState extends ConsumerState<QasmEditorScreen> {
  late final TextEditingController _controller;
  QasmResult? _result;
  final _parser = QasmParser();

  static const _defaultCode = '''// QuantumLab QASM Editor
// Supported: h, x, y, z, s, t, cx, swap
OPENQASM 2.0;
qreg q[2];

h q[0];
cx q[0], q[1];

measure q;
''';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode ?? _defaultCode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run() {
    setState(() {
      _result = _parser.parse(_controller.text, shots: 1024);
    });
  }

  void _clear() {
    _controller.clear();
    setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        title: const Text('QASM Editor'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clear, tooltip: 'Clear'),
          FilledButton.icon(
            onPressed: _run,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Run'),
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWide ? _buildWide(cs) : _buildNarrow(cs),
    );
  }

  Widget _buildWide(ColorScheme cs) {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildEditor(cs)),
        VerticalDivider(width: 1, color: cs.outlineVariant),
        Expanded(flex: 2, child: _buildResults(cs)),
      ],
    );
  }

  Widget _buildNarrow(ColorScheme cs) {
    return Column(
      children: [
        Expanded(flex: 3, child: _buildEditor(cs)),
        Divider(height: 1, color: cs.outlineVariant),
        Expanded(flex: 2, child: _buildResults(cs)),
      ],
    );
  }

  Widget _buildEditor(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerLowest,
      child: Column(
        children: [
          // Line numbers + editor
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line numbers
                Container(
                  width: 36,
                  color: cs.surfaceContainerHighest,
                  padding: const EdgeInsets.only(top: 12, right: 4),
                  child: _buildLineNumbers(cs),
                ),
                // Code editor
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: cs.onSurface, height: 1.5),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineNumbers(ColorScheme cs) {
    final lines = _controller.text.split('\n').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(lines, (i) {
        final hasError = _result?.errors.any((e) => e.contains('Line ${i + 1}:')) == true;
        return SizedBox(
          height: 21,
          child: Text(
            '${i + 1}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: hasError ? cs.error : cs.onSurfaceVariant,
              fontWeight: hasError ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResults(ColorScheme cs) {
    if (_result == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, size: 48, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text('Press Run to execute', style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    final r = _result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: r.success ? Colors.green.withValues(alpha: 0.1) : cs.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(r.success ? Icons.check_circle : Icons.error, color: r.success ? Colors.green : cs.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.success ? '${r.instructions.length} instructions executed' : '${r.errors.length} error(s)',
                    style: TextStyle(fontWeight: FontWeight.w600, color: r.success ? Colors.green : cs.error),
                  ),
                ),
              ],
            ),
          ),
          // Errors
          if (r.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final err in r.errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(err, style: TextStyle(color: cs.error, fontSize: 12, fontFamily: 'monospace')),
              ),
          ],
          // Histogram
          if (r.probabilities != null && r.probabilities!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Probabilities', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _ProbChart(probabilities: r.probabilities!, cs: cs),
            ),
          ],
          // Counts
          if (r.measurements != null && r.measurements!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Measurement Counts (1024 shots)', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 13)),
            const SizedBox(height: 8),
            for (final e in (r.measurements!.entries.toList()..sort((a, b) => b.value.compareTo(a.value))))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text('|${e.key}⟩', style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: cs.onSurface)),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: e.value / 1024,
                        backgroundColor: cs.surfaceContainerHighest,
                        color: cs.primary,
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(' ${e.value}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant), textAlign: TextAlign.end),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProbChart extends StatelessWidget {
  final Map<String, double> probabilities;
  final ColorScheme cs;
  const _ProbChart({required this.probabilities, required this.cs});

  @override
  Widget build(BuildContext context) {
    final entries = probabilities.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1.0,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                if (value == 0 || value == 0.5 || value == 1.0) {
                  return Text('${(value * 100).toInt()}%', style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx >= 0 && idx < entries.length) {
                  return Text('|${entries[idx].key}⟩', style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 0.25),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(entries.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value,
                color: cs.primary,
                width: entries.length <= 4 ? 28 : (entries.length <= 8 ? 16 : 8),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
