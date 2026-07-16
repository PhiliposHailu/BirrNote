import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../data/expense_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _selectDate(BuildContext context, WidgetRef ref, DateTime currentDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != currentDate) {
      ref.read(historyDateProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(historyDateProvider);
    final historyExpenses = ref.watch(historyExpensesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. DATE SELECTOR BAR (Clickable Calendar Row!)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.blue),
                title: const Text('Filter Date', style: TextStyle(color: Colors.grey, fontSize: 12)),
                subtitle: Text(
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.edit_calendar, color: Colors.blue),
                onTap: () => _selectDate(context, ref, selectedDate),
              ),
            ),
          ),

          // 2. THE FILTERED EXPENSE LIST (With Swipe-to-Delete!)
          Expanded(
            child: historyExpenses.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const Center(
                    child: Text(
                      'No spending logged on this day!',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];

                    return Dismissible(
                      key: ValueKey(expense.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red.shade100,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete_outline, color: Colors.red.shade900),
                      ),
                      onDismissed: (direction) async {
                        final expenseDao = ref.read(expenseDaoProvider);
                        await expenseDao.deleteExpense(expense.id);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deleted "${expense.rawNote}"'),
                              action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () async {
                                    await expenseDao.insertExpense(expense.toCompanion(true));
                                  },
                                ),
                            ),
                          );
                        }
                      },
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: Text(
                          '${expense.category} - ${expense.amount.toStringAsFixed(2)} ETB',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Note: "${expense.rawNote}" • Qty: ${expense.quantity}'),
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}