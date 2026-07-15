import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart'; // Import to write to SQLite
import '../../data/budget_providers.dart';

class BudgetHeaderWidget extends ConsumerWidget {
  const BudgetHeaderWidget({super.key});

  // THE QUICK BUDGET DIALOG SHORTCUT
  void _showQuickBudgetDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    String selectedPeriod = 'Weekly';
    final List<String> periods = ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'Set Your Budget',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Set a budget limit to instantly activate your daily rolling spending power!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  
                  // Period Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Cycle',
                      border: OutlineInputBorder(),
                    ),
                    items: periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        dialogSetState(() => selectedPeriod = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount Input
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Limit Amount (ETB)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                FilledButton(
                  onPressed: () async {
                    final text = amountController.text;
                    final limit = double.tryParse(text);
                    
                    if (limit != null && limit > 0) {
                      Navigator.pop(context); // Close dialog
                      await ref.read(budgetDaoProvider).setBudget(limit, selectedPeriod);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetEngineProvider);

    // 1. IF NO BUDGET: Redesigned with powerful HCI Signifiers!
    if (!budgetState.hasBudget) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 2,
          // HCI: Clean outline border using your active theme primary color!
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showQuickBudgetDialog(context, ref), // The shortcut!
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // HCI Signifier A: Active, inviting "Add Card" icon on the left
                  Icon(
                    Icons.add_card_outlined, 
                    color: Theme.of(context).colorScheme.primary, 
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  
                  // HCI Signifier B: Clear, colored, bold CTA text & instructions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Track Daily Spending Power',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap here to set your weekly limit and activate the rollover engine!',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  
                  // HCI Signifier C: Universal "Chevron right" indicating clickability!
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

    // 2. IF BUDGET SET: Render the standard dynamic colored card (unchanged)
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