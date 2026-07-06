import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/expense_providers.dart';
// 1. IMPORT our live category provider
import '../../../settings/data/category_providers.dart'; 

class ManualEntrySheet extends ConsumerStatefulWidget {
  const ManualEntrySheet({super.key});

  @override
  ConsumerState<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends ConsumerState<ManualEntrySheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  // 2. We initialize this to null instead of a hardcoded string!
  String? _selectedCategory; 
  int _quantity = 1;

  void _submit() {
    final amountText = _amountController.text;
    if (amountText.isEmpty || _selectedCategory == null) return;

    final amount = double.tryParse(amountText) ?? 0.0;
    
    ref.read(expenseLogicProvider).addManualExpense(
      amount: amount,
      category: _selectedCategory!,
      quantity: _quantity,
      note: _noteController.text,
    );

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    // 3. Watch the live category stream from the database!
    final categoriesStream = ref.watch(categoryNamesStreamProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset, left: 16, right: 16, top: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Manual Entry',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // AMOUNT INPUT
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (ETB)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 4. DYNAMIC CATEGORY DROPDOWN
            categoriesStream.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading categories: $error'),
              data: (categories) {
                // HCI Safety Check: If our selected category is null, or if the user 
                // just deleted the category we had selected, automatically fallback 
                // to the first active category in the database (usually "Food & Drinks" or "Others")
                if (_selectedCategory == null || !categories.contains(_selectedCategory)) {
                  _selectedCategory = categories.isNotEmpty ? categories.first : 'Others';
                }

                return DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  // Render items dynamically from SQLite!
                  items: categories.map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // QUANTITY PICKER
            Row(
              children: [
                const Text('Quantity:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
                ),
                Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _quantity++),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // OPTIONAL NOTE
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'e.g. Lunch with friends',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // SAVE BUTTON
            FilledButton(
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Save Expense', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}