import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/budget_providers.dart';

class BudgetHeaderWidget extends ConsumerWidget {
  const BudgetHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch our math engine!
    final budgetState = ref.watch(budgetEngineProvider);

    // If they haven't set a budget yet, show a friendly placeholder
    if (!budgetState.hasBudget) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Set a weekly budget limit in Settings to track your daily spending power!',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final balance = budgetState.todaySpendingPower;
    final isPositive = balance >= 0;

    // HCI COLOR CODE: Emerald Green if surplus, Crimson Red if deficit
    final textColor = isPositive ? Colors.green.shade800 : Colors.red.shade800;
    final bgColor = isPositive ? Colors.green.shade50 : Colors.red.shade50;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Spending Power",
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${balance.toStringAsFixed(2)} ETB',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Daily base allowance: ${budgetState.dailyLimit.toStringAsFixed(0)} ETB/day',
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}