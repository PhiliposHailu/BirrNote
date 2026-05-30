import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart'; // The charting library
import '../data/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // A helper function to assign a consistent color to each category
  Color _getColor(String category) {
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, 
      Colors.purple, Colors.teal, Colors.pink, Colors.amber, Colors.indigo
    ];
    // We use the hash of the string so "Food" is ALWAYS the same color
    return colors[category.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Listen to our SQL Aggregation Stream!
    final categoryTotals = ref.watch(categoryTotalsProvider);

    return categoryTotals.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (totals) {
        if (totals.isEmpty) {
          return const Center(child: Text('No data yet. Start tracking!'));
        }

        // 2. Calculate the Grand Total 
        final grandTotal = totals.fold(0.0, (sum, item) => sum + item.total);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  width: double.infinity, // Take up full width
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'Total Spent', 
                        style: TextStyle(fontSize: 16, color: Colors.grey)
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${grandTotal.toStringAsFixed(2)} ETB', 
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // --- THE PIE CHART ---
              SizedBox(
                height: 200, 
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2, // Gap between slices
                    centerSpaceRadius: 50, // Creates the "donut" hole in the middle
                    sections: totals.map((item) {
                      final percentage = (item.total / grandTotal) * 100;
                      
                      return PieChartSectionData(
                        color: _getColor(item.category),
                        value: item.total,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // --- THE LEGEND (List of Categories) ---
              Expanded(
                child: ListView.builder(
                  itemCount: totals.length,
                  itemBuilder: (context, index) {
                    final item = totals[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColor(item.category),
                        radius: 12,
                      ),
                      title: Text(item.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Text(
                        '${item.total.toStringAsFixed(2)} ETB', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}