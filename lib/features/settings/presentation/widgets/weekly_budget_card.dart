import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/app_database.dart';

// 1. FIXED: StreamProvider is now safely outside the widget (Global)
final activeBudgetStreamProvider = StreamProvider<Budget?>((ref) {
  final budgetDao = ref.watch(budgetDaoProvider);
  return budgetDao.watchActiveBudget();
});

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
    // 2. FIXED: Watch the global provider instead of creating a new one
    final activeBudgetAsync = ref.watch(activeBudgetStreamProvider);

    return activeBudgetAsync.when(
      // 3. FIXED: No more invisible boxes! We show a loader and error text
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Database Error: $error', 
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ),
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