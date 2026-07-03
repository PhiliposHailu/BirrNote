import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import 'expense_providers.dart'; 

// A simple DTO to pass our calculated budget states to the UI
class SpendingPower {
  final double todaySpendingPower;
  final double dailyLimit;
  final bool hasBudget;

  SpendingPower({
    required this.todaySpendingPower,
    required this.dailyLimit,
    required this.hasBudget,
  });
}

// THE ENGINE: Combines budget settings and expenses to calculate spending power!
final budgetEngineProvider = Provider<SpendingPower>((ref) {
  // A. Watch the budget settings stream
  final budgetDao = ref.watch(budgetDaoProvider);
  final activeBudgetAsync = ref.watch(StreamProvider((ref) => budgetDao.watchActiveBudget()));
  
  // B. Watch all expenses stream
  final expensesAsync = ref.watch(expensesStreamProvider);

  // If we are loading or have no budget set yet, return empty state
  if (activeBudgetAsync.value == null || expensesAsync.value == null) {
    return SpendingPower(todaySpendingPower: 0, dailyLimit: 0, hasBudget: false);
  }

  final budget = activeBudgetAsync.value!;
  final expenses = expensesAsync.value!;

  final weeklyLimit = budget.weeklyLimit;
  final startDate = budget.startDate;
  final dailyLimit = weeklyLimit / 7.0;

  // --- THE CALENDAR MATH ENGINE ---
  final now = DateTime.now();
  
  // 1. Calculate how many days have passed since they set the budget
  final differenceInDays = now.difference(startDate).inDays;
  
  // 2. Calculate how many full 7-day cycles (weeks) have been completed
  final completedWeeks = differenceInDays ~/ 7;
  
  // 3. Find the exact starting date of the CURRENT active 7-day cycle
  final currentCycleStart = startDate.add(Duration(days: completedWeeks * 7));
  
  // 4. Find how many days have elapsed in this current cycle (Value will be 1 to 7)
  final elapsedDaysInCurrentCycle = (differenceInDays % 7) + 1;

  // 5. Total budget allowed up to today (including today)
  final allowedBudgetUpToToday = elapsedDaysInCurrentCycle * dailyLimit;

  // 6. Sum up all expenses that happened *since* this current cycle started
  double actualSpentInCurrentCycle = 0.0;
  for (final expense in expenses) {
    // Only count expenses that are not pending AI, and happened after currentCycleStart
    if (!expense.isPendingAi && expense.date.isAfter(currentCycleStart)) {
      actualSpentInCurrentCycle += expense.amount;
    }
  }

  // 7. Today's Spending Power!
  final todaySpendingPower = allowedBudgetUpToToday - actualSpentInCurrentCycle;

  return SpendingPower(
    todaySpendingPower: todaySpendingPower,
    dailyLimit: dailyLimit,
    hasBudget: true,
  );
});