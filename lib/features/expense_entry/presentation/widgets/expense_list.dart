import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/expense_providers.dart';

class ExpenseList extends ConsumerWidget {
  const ExpenseList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This is exactly like: const { data, loading, error } = useQuery(expensesStream);
    final expensesStream = ref.watch(expensesStreamProvider);

    return expensesStream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(child: Text('No expenses yet. Start typing!'));
        }
        
        return ListView.builder(
          reverse: true, // newest at the bottom
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses.reversed.toList()[index];
            return ListTile(
              title: Text(expense.rawNote),
              subtitle: Text('Qty: ${expense.quantity} • ${expense.date.toString().split('.')[0]}'),
              trailing: expense.isPendingAi 
                  ? const Icon(Icons.sync, color: Colors.orange)
                  : null,
            );
          },
        );
      },
    );
  }
}