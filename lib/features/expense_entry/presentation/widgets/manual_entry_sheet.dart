import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/expense_providers.dart';
// 1. IMPORT our live category provider
import '../../../settings/data/category_providers.dart'; 
import '../../../../core/utils/locale_provider.dart';
import '../../../../core/database/app_database.dart';

class ManualEntrySheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final Expense? existingExpense;
  const ManualEntrySheet({super.key, this.initialDate, this.existingExpense});

  @override
  ConsumerState<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends ConsumerState<ManualEntrySheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  // 2. We initialize this to null instead of a hardcoded string!
  String? _selectedCategory; 
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final expense = widget.existingExpense!;
      _amountController.text = expense.amount.toString();
      
      // Remove any quantity/category formatting from the rawNote if needed,
      // but in BirrNote rawNote stores exactly what we need!
      _noteController.text = expense.rawNote;
      _selectedCategory = expense.category;
      _quantity = expense.quantity;
    }
  }

  void _submit() {
    final amountText = _amountController.text;
    if (amountText.isEmpty || _selectedCategory == null) return;

    final amount = double.tryParse(amountText) ?? 0.0;
    
    if (widget.existingExpense != null) {
      ref.read(expenseLogicProvider).editExpense(
        id: widget.existingExpense!.id,
        amount: amount,
        category: _selectedCategory!,
        quantity: _quantity,
        note: _noteController.text,
        date: widget.existingExpense!.date,
      );
    } else {
      ref.read(expenseLogicProvider).addManualExpense(
        amount: amount,
        category: _selectedCategory!,
        quantity: _quantity,
        note: _noteController.text,
        date: widget.initialDate,
      );
    }

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
            Text(
              widget.existingExpense != null ? "Edit Expense" : ref.watch(trProvider('manual_entry')),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // AMOUNT INPUT
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: ref.watch(trProvider('amount_etb')),
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 4. DYNAMIC CATEGORY DROPDOWN
            categoriesStream.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('${ref.watch(trProvider('error_loading_categories'))}$error'),
              data: (categories) {
                // HCI Safety Check: If the user deleted the category this expense used,
                // we inject it temporarily so the dropdown doesn't break!
                final List<String> availableCategories = List.from(categories);
                if (widget.existingExpense != null && !availableCategories.contains(widget.existingExpense!.category)) {
                  availableCategories.add(widget.existingExpense!.category);
                }

                // If _selectedCategory is STILL null (e.g. brand new entry) fallback to first available
                if (_selectedCategory == null || !availableCategories.contains(_selectedCategory)) {
                  _selectedCategory = availableCategories.isNotEmpty ? availableCategories.first : 'Others';
                }

                return DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: ref.watch(trProvider('category_label')),
                    border: const OutlineInputBorder(),
                  ),
                  // Render items dynamically from SQLite!
                  items: availableCategories.map((category) {
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
                Text(ref.watch(trProvider('quantity_label')), style: const TextStyle(fontSize: 16)),
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
              decoration: InputDecoration(
                labelText: ref.watch(trProvider('note_optional')),
                hintText: ref.watch(trProvider('eg_lunch')),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // SAVE BUTTON
            FilledButton(
              onPressed: _submit,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(ref.watch(trProvider('save_expense')), style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}