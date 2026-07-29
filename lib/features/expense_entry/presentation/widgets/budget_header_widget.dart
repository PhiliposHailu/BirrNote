import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/locale_provider.dart';
import '../../data/budget_providers.dart';
import 'quick_budget_dialog.dart'; // Import our new separate dialog!

class BudgetHeaderWidget extends ConsumerWidget {
  const BudgetHeaderWidget({super.key});

  void _showQuickBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const QuickBudgetDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetEngineProvider);

    // 1. ONBOARDING CTA CARD (No budget set)
    if (!budgetState.hasBudget) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showQuickBudgetDialog(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.add_card_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref.watch(trProvider('track_spending_power')),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ref.watch(trProvider('tap_to_set_budget')),
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 2. ACTIVE SPENDING POWER CARD (Budget is set)
    final balance = budgetState.todaySpendingPower;
    final isPositive = balance >= 0;

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
            ref.watch(trProvider('today_spending_power')),
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${balance.toStringAsFixed(2)} ETB',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            '${ref.watch(trProvider('daily_allowance'))}: ${budgetState.dailyLimit.toStringAsFixed(0)} ETB/day',
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}