import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/expense_providers.dart';

class ExpenseList extends ConsumerWidget {
  const ExpenseList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesStream = ref.watch(expensesStreamProvider);

    return expensesStream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(child: Text('No expenses yet. Start typing!'));
        }
        
        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            // We reverse the list so the newest items show up at the bottom
             final expense = expenses[index];
            
            return ListTile(
              // If processed, show "Category - ETB Amount" in bold.
              title: expense.isPendingAi 
                  ? Text(expense.rawNote, style: const TextStyle(fontStyle: FontStyle.italic))
                  : Text('${expense.category} - ETB ${expense.amount.toStringAsFixed(2)}', 
                         style: const TextStyle(fontWeight: FontWeight.bold)),
              
              // 2. SUBTITLE: 
              // If pending, tell the user it's waiting for AI.
              // If processed, keep a record of their original raw note + quantity.
              subtitle: expense.isPendingAi
                  ? Text('Waiting for AI... • ${expense.date.toString().split('.')[0]}')
                  : Text('Note: "${expense.rawNote}" • Qty: ${expense.quantity}'),
              
              // 3. TRAILING ICON: 
              // Orange spinning/sync icon when pending, Green checkmark when done!
              trailing: expense.isPendingAi 
                  ? const Icon(Icons.sync, color: Colors.orange)
                  : const Icon(Icons.check_circle, color: Colors.green),
            );
          },
        );
      },
    );
  }
}