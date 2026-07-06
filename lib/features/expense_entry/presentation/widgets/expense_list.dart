import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
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
          reverse: true, // Newest at the bottom
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses.reversed.toList()[index];

            // THE HCI MAGIC: Wrap the ListTile in a Dismissible widget
            return Dismissible(
              // Each item MUST have a completely unique key for the animation to work
              key: ValueKey(expense.id),
              
              // Only allow swiping from right to left (HCI Standard for deletion)
              direction: DismissDirection.endToStart,
              
              // The red background with a trash can icon that shows during the swipe
              background: Container(
                color: Colors.red.shade100,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: Icon(Icons.delete_outline, color: Colors.red.shade900),
              ),

              // What happens when they finish swiping
              onDismissed: (direction) async {
                final expenseDao = ref.read(expenseDaoProvider);

                // 1. SILENT DELETE: Delete it from SQLite immediately
                await expenseDao.deleteExpense(expense.id);

                // 2. THE SAFETY NET: Show the SnackBar with an Undo button
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars(); // Dismiss old SnackBars
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted "${expense.rawNote}"'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () async {
                          // THE UNDO: Re-insert the exact copy back into SQLite!
                          // .toCompanion(true) tells Drift to keep its original ID
                          await expenseDao.insertExpense(expense.toCompanion(true));
                        },
                      ),
                    ),
                  );
                }
              },

              child: ListTile(
                title: expense.isPendingAi 
                    ? Text(expense.rawNote, style: const TextStyle(fontStyle: FontStyle.italic))
                    : Text('${expense.category} - ${expense.amount.toStringAsFixed(2)} ETB', 
                           style: const TextStyle(fontWeight: FontWeight.bold)),
                
                subtitle: expense.isPendingAi
                    ? Text('Waiting for AI... • ${expense.date.toString().split('.')[0]}')
                    : Text('Note: "${expense.rawNote}" • Qty: ${expense.quantity}'),
                
                trailing: expense.isPendingAi 
                    ? IconButton(
                        icon: const Icon(Icons.sync, color: Colors.orange),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Retrying AI Sync...')),
                          );
                          ref.read(expenseLogicProvider).syncPendingNotes();
                        },
                      )
                    : const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }
}