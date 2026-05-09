import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/quantum_computer.dart';
import '../../providers/circuit_provider.dart';

/// Bar chart showing measurement probability distribution.
class ProbabilityHistogram extends ConsumerWidget {
  const ProbabilityHistogram({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simulation = ref.watch(circuitProvider.select((s) => s.simulation));
    final cs = Theme.of(context).colorScheme;

    if (simulation.rawProbabilities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 32, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              'Place gates to see probabilities',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a gate, then tap a cell on the grid',
              style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11),
            ),
          ],
        ),
      );
    }

    // Filter to only states with non-negligible probability
    final nQubits = ref.watch(circuitProvider.select((s) => s.circuit.nQubits));
    final probs = simulation.rawProbabilities;
    final entries = <_BarEntry>[];

    for (int i = 0; i < probs.length; i++) {
      if (probs[i] > 0.005) {
        entries.add(_BarEntry(
          label: i.toRadixString(2).padLeft(nQubits, '0'),
          probability: probs[i],
        ));
      }
    }

    if (entries.isEmpty) {
      entries.add(_BarEntry(label: '0' * nQubits, probability: 1.0));
    }

    // Sort by label for consistent ordering
    entries.sort((a, b) => a.label.compareTo(b.label));

    final hasMeasurement = simulation.lastMeasurement != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            children: [
              Text(
                hasMeasurement ? 'Measurement Results' : 'Probabilities',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (hasMeasurement) ...[
                const Spacer(),
                Text(
                  '${simulation.lastMeasurement!.values.fold(0, (a, b) => a + b)} shots',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final entry = entries[groupIndex];
                      return BarTooltipItem(
                        '|${entry.label}\u27E9\n${(entry.probability * 100).toStringAsFixed(1)}%',
                        TextStyle(color: cs.onInverseSurface, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 0.5 || value == 1.0) {
                          return Text(
                            '${(value * 100).toInt()}%',
                            style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < entries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '|${entries[idx].label}\u27E9',
                              style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(entries.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: entries[i].probability,
                        color: cs.primary,
                        width: entries.length <= 4 ? 28 : (entries.length <= 8 ? 18 : 10),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
        if (hasMeasurement)
          _MeasurementCounts(counts: simulation.lastMeasurement!),
      ],
    );
  }
}

class _MeasurementCounts extends StatelessWidget {
  final MeasurementResult counts;

  const _MeasurementCounts({required this.counts});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = counts.values.fold(0, (a, b) => a + b);

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final e = sorted[i];
          final pct = (e.value / total * 100).toStringAsFixed(1);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('|${e.key}⟩', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface)),
                Text('${e.value} ($pct%)', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BarEntry {
  final String label;
  final double probability;
  _BarEntry({required this.label, required this.probability});
}
