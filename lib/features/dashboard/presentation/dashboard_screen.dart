import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/dashboard_providers.dart';
import 'widgets/trend_bar_chart.dart'; 
import '../../../core/utils/locale_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Color _getColor(String category) {
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, 
      Colors.purple, Colors.teal, Colors.pink, Colors.amber, Colors.indigo
    ];
    return colors[category.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch active segment settings
    final chartType = ref.watch(chartTypeProvider);
    final activeFilter = ref.watch(timeFilterProvider);
    
    final isPieSelected = chartType == 'Pie';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 1. Apple-Style Pill Toggle (Pie Share vs Bar Trends)
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'Pie',
                icon: const Icon(Icons.pie_chart_outline),
                label: Text(ref.watch(trProvider('breakdown'))),
              ),
              ButtonSegment(
                value: 'Bar',
                icon: const Icon(Icons.bar_chart_outlined),
                label: Text(ref.watch(trProvider('trends'))),
              ),
            ],
            selected: {chartType},
            onSelectionChanged: (value) {
              ref.read(chartTypeProvider.notifier).state = value.first;
            },
          ),
          const SizedBox(height: 16),

          // 2. Sliding Time Filters Row (Only renders when Bar Chart is selected!)
          if (!isPieSelected) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['This Week', 'This Month', 'Last 3 Months'].map((filter) {
                  final isSelected = activeFilter == filter;
                  String displayFilter = filter;
                  if (filter == 'This Week') displayFilter = ref.watch(trProvider('this_week'));
                  if (filter == 'This Month') displayFilter = ref.watch(trProvider('this_month'));
                  if (filter == 'Last 3 Months') displayFilter = ref.watch(trProvider('last_3_months'));
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(displayFilter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(timeFilterProvider.notifier).state = filter;
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3. THE GRAPH WINDOW AREA
          Expanded(
            child: isPieSelected
                ? _buildPieChartWindow(context, ref) // Render Category Share
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: TrendBarChart(), // Renders our new separate Bar Chart widget!
                  ),
          ),
        ],
      ),
    );
  }

  // Helper method: Kept internally so we don't bloat the build file,
  // simply encapsulates the original Pie Chart + List logic
  Widget _buildPieChartWindow(BuildContext context, WidgetRef ref) {
    final categoryTotals = ref.watch(categoryTotalsProvider);

    return categoryTotals.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('${ref.watch(trProvider('error_prefix'))}$error')),
      data: (totals) {
        if (totals.isEmpty) {
          return Center(child: Text(ref.watch(trProvider('no_data_yet'))));
        }

        final grandTotal = totals.fold(0.0, (sum, item) => sum + item.total);

        return Column(
          children: [
            // The Spend Display
            Text(
              '${grandTotal.toStringAsFixed(2)} ETB',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(ref.watch(trProvider('total_spent')), style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),

            // Pie Drawing
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: totals.map((item) {
                    final percentage = (item.total / grandTotal) * 100;
                    return PieChartSectionData(
                      color: _getColor(item.category),
                      value: item.total,
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category list Legend
            Expanded(
              child: ListView.builder(
                itemCount: totals.length,
                itemBuilder: (context, index) {
                  final item = totals[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(backgroundColor: _getColor(item.category), radius: 6),
                    title: Text(item.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text('${item.total.toStringAsFixed(2)} ETB', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}