import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../expense_entry/data/budget_providers.dart';

class WeeklyBudgetCard extends ConsumerStatefulWidget {
  const WeeklyBudgetCard({super.key});

  @override
  ConsumerState<WeeklyBudgetCard> createState() => _WeeklyBudgetCardState();
}

class _WeeklyBudgetCardState extends ConsumerState<WeeklyBudgetCard> {
  final _budgetController = TextEditingController();
  String _selectedPeriod = 'Weekly';

  final List<String> _periods = ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly'];

  void _saveBudget() {
    final text = _budgetController.text;
    final limit = double.tryParse(text);
    
    if (limit != null && limit > 0) {
      ref.read(budgetDaoProvider).setBudget(limit, _selectedPeriod);
      _budgetController.clear();
      FocusScope.of(context).unfocus(); // Close keyboard
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget limit updated successfully!')),
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
    final activeBudgetAsync = ref.watch(activeBudgetStreamProvider);

    return activeBudgetAsync.when(
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
                  'Budget Limit Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  hasBudget 
                      ? 'Current: ${budget.limitAmount.toStringAsFixed(2)} ETB / ${budget.period.toLowerCase()}'
                      : 'Set a budget limit to track your rollover spending power!',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // Period Dropdown
                DropdownButtonFormField<String>(
                  value: hasBudget && _budgetController.text.isEmpty ? budget.period : _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Budget Cycle',
                    border: OutlineInputBorder(),
                  ),
                  items: _periods.map((period) {
                    return DropdownMenuItem(value: period, child: Text(period));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedPeriod = value);
                  },
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
                          labelText: 'Limit Amount (ETB)',
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

                // NEW: THE "REMOVE BUDGET" BUTTON (Only shows if a budget is active!)
                if (hasBudget) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                      label: const Text('Remove Budget', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        // Confirm Dialog (HCI Heuristic: Safety & Control)
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Budget?'),
                            content: const Text(
                              'This will stop tracking your daily spending power. Past expenses will not be deleted.'
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          // Call the delete function!
                          await ref.read(budgetDaoProvider).deleteBudget();
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}