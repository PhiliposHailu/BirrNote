import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';

class WeeklyBudgetCard extends ConsumerStatefulWidget {
  const WeeklyBudgetCard({super.key});

  @override
  ConsumerState<WeeklyBudgetCard> createState() => _WeeklyBudgetCardState();
}

class _WeeklyBudgetCardState extends ConsumerState<WeeklyBudgetCard> {
  final _budgetController = TextEditingController();

  void _saveBudget() {
    final text = _budgetController.text;
    final limit = double.tryParse(text);
    
    if (limit != null && limit > 0) {
      // Calls our BudgetDao to save/update the budget
      ref.read(budgetDaoProvider).setWeeklyBudget(limit);
      _budgetController.clear();
      FocusScope.of(context).unfocus(); // Close keyboard
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weekly budget updated successfully!')),
      );
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the active budget stream to show current settings
    final activeBudgetAsync = ref.watch(StreamProvider((ref) {
      return ref.watch(budgetDaoProvider).watchActiveBudget();
    }));

    return activeBudgetAsync.when(
      loading: () => const SizedBox(),
      error: (e, s) => const SizedBox(),
      data: (budget) {
        final hasBudget = budget != null;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Budget Limit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  hasBudget 
                      ? 'Current: ${budget.weeklyLimit.toStringAsFixed(2)} ETB / week'
                      : 'Set a weekly limit to track your rollover spending power!',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // Input Field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _budgetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Weekly Limit (ETB)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.check),
                      onPressed: _saveBudget,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}