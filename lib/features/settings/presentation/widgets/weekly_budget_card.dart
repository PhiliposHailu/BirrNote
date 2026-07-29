import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../expense_entry/data/budget_providers.dart';
import '../../../../core/utils/locale_provider.dart';

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
        SnackBar(content: Text(ref.read(trProvider('budget_updated_success')))),
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
            '${ref.watch(trProvider('database_error'))}$error', 
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
                Text(
                  ref.watch(trProvider('budget_limit_settings')),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  hasBudget 
                      ? '${ref.watch(trProvider('current_budget'))}${budget.limitAmount.toStringAsFixed(2)} ETB / ${budget.period.toLowerCase()}'
                      : ref.watch(trProvider('set_a_budget')),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // Period Dropdown
                DropdownButtonFormField<String>(
                  value: hasBudget && _budgetController.text.isEmpty ? budget.period : _selectedPeriod,
                  decoration: InputDecoration(
                    labelText: ref.watch(trProvider('budget_cycle')),
                    border: const OutlineInputBorder(),
                  ),
                  items: _periods.map((period) {
                    String displayPeriod = period;
                    if (period == 'Daily') displayPeriod = ref.watch(trProvider('daily'));
                    if (period == 'Weekly') displayPeriod = ref.watch(trProvider('weekly'));
                    if (period == 'Monthly') displayPeriod = ref.watch(trProvider('monthly'));
                    if (period == 'Quarterly') displayPeriod = ref.watch(trProvider('quarterly'));
                    if (period == 'Yearly') displayPeriod = ref.watch(trProvider('yearly'));
                    return DropdownMenuItem(value: period, child: Text(displayPeriod));
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
                        decoration: InputDecoration(
                          labelText: ref.watch(trProvider('limit_amount')),
                          border: const OutlineInputBorder(),
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
                      label: Text(ref.watch(trProvider('remove_budget')), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        // Confirm Dialog (HCI Heuristic: Safety & Control)
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(ref.watch(trProvider('remove_budget_q'))),
                            content: Text(
                              ref.watch(trProvider('remove_budget_warning'))
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(ref.watch(trProvider('cancel'))),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                child: Text(ref.watch(trProvider('remove'))),
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