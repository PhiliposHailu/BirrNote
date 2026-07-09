import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/dashboard_providers.dart';

class TrendBarChart extends ConsumerWidget {
  const TrendBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(trendTotalsProvider);

    return trendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (trends) {
        if (trends.isEmpty) {
          return const Center(child: Text('No trend data available yet.'));
        }

        final maxSpent = trends.map((t) => t.total).reduce((a, b) => a > b ? a : b);
        // We increase headroom to 30% to make sure the static labels don't get cut off at the top!
        final maxY = maxSpent == 0 ? 100.0 : maxSpent * 1.3; 

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            
            // 1. THE STATIC NUMBER RENDERING Logic
            barTouchData: BarTouchData(
              enabled: true, // Allows tapping on bars
              touchTooltipData: BarTouchTooltipData(
                // We make the tooltip container completely invisible!
                getTooltipColor: (group) => Colors.transparent, 
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 4, // Clean gap above the column
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  // If the user spent 0 on this day, hide the label to prevent clutter!
                  if (rod.toY == 0) return null;

                  return BarTooltipItem(
                    // Display raw integer without decimals (e.g. 200 instead of 200.00)
                    rod.toY.toStringAsFixed(0), 
                    TextStyle(
                      color: Colors.grey.shade600, // Subtle, blend-in grey
                      fontWeight: FontWeight.bold,
                      fontSize: 10, // Tiny font size
                    ),
                  );
                },
              ),
            ),
            
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < trends.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          trends[index].label,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            
            barGroups: trends.asMap().entries.map((entry) {
              final index = entry.key;
              final trend = entry.value;

              return BarChartGroupData(
                x: index,
                // 2. THE CHAT ACTIVATION: If spending is > 0, permanently draw the static label!
                showingTooltipIndicators: trend.total > 0 ? [0] : [],
                barRods: [
                  BarChartRodData(
                    toY: trend.total,
                    color: Theme.of(context).colorScheme.primary,
                    width: 16,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}