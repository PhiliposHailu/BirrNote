import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/budget_dao.dart';
import 'expense_providers.dart';

final activeBudgetStreamProvider = StreamProvider<Budget?>((ref) {
  final budgetDao = ref.watch(budgetDaoProvider);
  return budgetDao.watchActiveBudget();
});

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

// THE UPGRADED ENGINE
final budgetEngineProvider = Provider<SpendingPower>((ref) {
  final activeBudgetAsync = ref.watch(activeBudgetStreamProvider);
  // Watching the all-time database stream instead of today-only!
  final expensesAsync = ref.watch(allExpensesStreamProvider);

  if (activeBudgetAsync.isLoading || expensesAsync.isLoading) {
    return SpendingPower(todaySpendingPower: 0, dailyLimit: 0, hasBudget: false);
  }

  final budget = activeBudgetAsync.value;
  final expenses = expensesAsync.value ?? [];

  if (budget == null) {
    return SpendingPower(todaySpendingPower: 0, dailyLimit: 0, hasBudget: false);
  }

  final limitAmount = budget.limitAmount;
  final startDate = budget.startDate;
  final String period = budget.period;

  // 1. DYNAMIC PERIOD MAPPING
  int periodInDays = 7; // Default fallback to Weekly
  if (period == 'Daily') periodInDays = 1;
  if (period == 'Weekly') periodInDays = 7;
  if (period == 'Monthly') periodInDays = 30;
  if (period == 'Quarterly') periodInDays = 90;
  if (period == 'Yearly') periodInDays = 365;

  final dailyLimit = limitAmount / periodInDays;

  // --- THE CALENDAR MATH ENGINE ---
  final now = DateTime.now();
  
  // Calculate exact days elapsed since they set this budget
  final differenceInDays = DateTime(now.year, now.month, now.day)
      .difference(DateTime(startDate.year, startDate.month, startDate.day))
      .inDays;

  // Calculate completed cycles (weeks, months, years etc.)
  final completedCycles = differenceInDays ~/ periodInDays;
  
  // The exact start date of this current active cycle
  final currentCycleStart = startDate.add(Duration(days: completedCycles * periodInDays));
  
  // The days elapsed in the current cycle
  final elapsedDaysInCurrentCycle = (differenceInDays % periodInDays) + 1;

  // How much they were allowed to spend up to today
  final allowedBudgetUpToToday = elapsedDaysInCurrentCycle * dailyLimit;

  // Sum up all expenses spent in this active cycle
  double actualSpentInCurrentCycle = 0.0;
  for (final expense in expenses) {
    // Only count expenses that are not pending AI, and happened after currentCycleStart
    if (!expense.isPendingAi && expense.date.isAfter(currentCycleStart)) {
      actualSpentInCurrentCycle += expense.amount;
    }
  }

  // Today's Spending Power!
  final todaySpendingPower = allowedBudgetUpToToday - actualSpentInCurrentCycle;

  return SpendingPower(
    todaySpendingPower: todaySpendingPower,
    dailyLimit: dailyLimit,
    hasBudget: true,
  );
});