import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../data/expense_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // FIXED: Generates exactly 7 days, starting with TODAY (index 0) on the left!
  List<DateTime> _generateTimelineDates() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: index));
    });
  }

  Future<void> _selectCalendarDate(
    BuildContext context,
    WidgetRef ref,
    DateTime currentDate,
  ) async {
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

    final timelineDates = _generateTimelineDates();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => _selectCalendarDate(context, ref, selectedDate),
          ),
        ],
      ),
      // THE SWIPE: Swipe left/right safely without any accidental deletions!
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          final today = DateTime.now();
          final todayMidnight = DateTime(today.year, today.month, today.day);

          // THE BOUNDARY: Find the exact midnight of the oldest visible day (6 days ago)
          final oldestAllowedDate = todayMidnight.subtract(
            const Duration(days: 6),
          );

          if (details.primaryVelocity! > 0) {
            // Swipe Right ──► Go to tomorrow (pull left)
            final tomorrow = selectedDate.add(const Duration(days: 1));

            // RIGHT WALL: Cannot swipe into the future
            if (!tomorrow.isAfter(todayMidnight)) {
              ref.read(historyDateProvider.notifier).state = tomorrow;
            }
          } else if (details.primaryVelocity! < 0) {
            // Swipe Left ──► Go to yesterday (pull right)
            final yesterday = selectedDate.subtract(const Duration(days: 1));

            // LEFT WALL: Cannot swipe further back than the oldest visible day!
            if (!yesterday.isBefore(oldestAllowedDate)) {
              ref.read(historyDateProvider.notifier).state = yesterday;
            }
          }
        },
        child: Column(
          children: [
            // 1. THE 7-DAY TIMELINE STRIP (Fits screen, Today is leftmost!)
            Container(
              height: 85,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: timelineDates.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final date = timelineDates[index];
                  final isSelected = _isSameDay(date, selectedDate);
                  final dayLabel = weekdays[date.weekday - 1];

                  return GestureDetector(
                    onTap: () {
                      ref.read(historyDateProvider.notifier).state = date;
                    },
                    child: Container(
                      width:
                          53, // Slightly narrower so all 7 fit perfectly on one screen!
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // 2. THE FILTERED EXPENSE LIST
            Expanded(
              child: historyExpenses.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return const Center(
                      child: Text(
                        'No spending logged on this day!',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];

                      // FIXED: Removed Dismissible entirely to prevent gesture collision!
                      return ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: Text(
                          '${expense.category} - ${expense.amount.toStringAsFixed(2)} ETB',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Note: "${expense.rawNote}" • Qty: ${expense.quantity}',
                        ),
                        // FIXED: Added a dedicated, safe, red Trash Can delete button!
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final expenseDao = ref.read(expenseDaoProvider);

                            // 1. Silent Delete
                            await expenseDao.deleteExpense(expense.id);

                            // 2. Show the Undo SnackBar
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Deleted "${expense.rawNote}"'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () async {
                                      // The Undo: Re-insert
                                      await expenseDao.insertExpense(
                                        expense.toCompanion(true),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
