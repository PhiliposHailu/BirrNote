import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../data/expense_providers.dart';
import '../../../core/utils/locale_provider.dart';
import 'widgets/manual_entry_sheet.dart';
import 'package:abushakir/abushakir.dart';
import '../../../core/utils/calendar_type_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // FIXED: Generates 7 days dynamically centered around the selected date!
  List<DateTime> _generateTimelineDates(DateTime selectedDate) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final selectedMidnight = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    final daysFromToday = todayMidnight.difference(selectedMidnight).inDays;
    
    // Shift ensures we never show future dates!
    int shift = 3; 
    if (daysFromToday < 3) {
      shift = daysFromToday;
    }
    
    return List.generate(7, (index) {
      final diff = shift - index; 
      return selectedMidnight.add(Duration(days: diff));
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
    final calendarType = ref.watch(calendarTypeProvider);

    final timelineDates = _generateTimelineDates(selectedDate);
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final etMonths = ['Mesk', 'Tik', 'Hidar', 'Tahsas', 'Tir', 'Yakatit', 'Magabit', 'Miyazya', 'Ginbot', 'Sene', 'Hamle', 'Nehase', 'Pagume'];

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.watch(trProvider('history'))),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => _selectCalendarDate(context, ref, selectedDate),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => ManualEntrySheet(initialDate: selectedDate),
          );
        },
        tooltip: 'Log Past Expense',
        child: const Icon(Icons.add),
      ),
      // THE SWIPE: Swipe left/right safely without any accidental deletions!
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          final today = DateTime.now();
          final todayMidnight = DateTime(today.year, today.month, today.day);

          if (details.primaryVelocity! > 0) {
            // Swipe Right ──► Go to tomorrow
            final tomorrow = selectedDate.add(const Duration(days: 1));

            // RIGHT WALL: Cannot swipe into the future
            if (!tomorrow.isAfter(todayMidnight)) {
              ref.read(historyDateProvider.notifier).state = tomorrow;
            }
          } else if (details.primaryVelocity! < 0) {
            // Swipe Left ──► Go to yesterday
            final yesterday = selectedDate.subtract(const Duration(days: 1));

            // NO LEFT WALL: Infinite scrolling into the past!
            ref.read(historyDateProvider.notifier).state = yesterday;
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

                  String monthText;
                  String dayText;

                  if (calendarType == CalendarType.ethiopian) {
                    final etDate = EtDatetime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch);
                    monthText = etMonths[etDate.month - 1];
                    dayText = etDate.day.toString();
                  } else {
                    monthText = months[date.month - 1];
                    dayText = date.day.toString();
                  }

                  return GestureDetector(
                    onTap: () {
                      ref.read(historyDateProvider.notifier).state = date;
                    },
                    child: Container(
                      width: 53, 
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            dayText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            monthText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white70 : Colors.grey.shade500,
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
                error: (error, stack) => Center(child: Text('${ref.watch(trProvider('error_prefix'))}$error')),
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return Center(
                      child: Text(
                        ref.watch(trProvider('no_spending_on_day')),
                        style: const TextStyle(
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
                        onTap: () {
                          if (!expense.isPendingAi) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => ManualEntrySheet(existingExpense: expense),
                            );
                          }
                        },
                        leading: const Icon(Icons.receipt_long),
                        title: Text(
                          '${expense.category} - ${expense.amount.toStringAsFixed(2)} ETB',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${ref.watch(trProvider('note_prefix'))}${expense.rawNote}${ref.watch(trProvider('qty_prefix'))}${expense.quantity}',
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
                                  content: Text('${ref.watch(trProvider('deleted'))}"${expense.rawNote}"'),
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
