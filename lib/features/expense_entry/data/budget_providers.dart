import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/budget_dao.dart';
import 'expense_providers.dart'; // We watch the expenses stream!

// 1. The shared active budget stream now lives here globally
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

// 2. THE ENGINE
final budgetEngineProvider = Provider<SpendingPower>((ref) {
  // Watch our global streams
  final activeBudgetAsync = ref.watch(activeBudgetStreamProvider);
  final expensesAsync = ref.watch(expensesStreamProvider);

  // A. Check if the streams are STILL LOADING. 
  // If they are loading, we return a default state.
  if (activeBudgetAsync.isLoading || expensesAsync.isLoading) {
    return SpendingPower(todaySpendingPower: 0, dailyLimit: 0, hasBudget: false);
  }

  // B. Get the loaded values
  final budget = activeBudgetAsync.value;
  final expenses = expensesAsync.value ?? [];

  // C. If the database loaded successfully, but the budget is literally NULL, 
  // it means they haven't saved a budget limit yet!
  if (budget == null) {
    return SpendingPower(todaySpendingPower: 0, dailyLimit: 0, hasBudget: false);
  }

  final weeklyLimit = budget.weeklyLimit;
  final startDate = budget.startDate;
  final dailyLimit = weeklyLimit / 7.0;

  // --- THE CALENDAR MATH ENGINE ---
  final now = DateTime.now();
  
  // Calculate total days elapsed since they set this budget
  final differenceInDays = DateTime(now.year, now.month, now.day)
      .difference(DateTime(startDate.year, startDate.month, startDate.day))
      .inDays;

  final completedWeeks = differenceInDays ~/ 7;
  final currentCycleStart = startDate.add(Duration(days: completedWeeks * 7));
  final elapsedDaysInCurrentCycle = (differenceInDays % 7) + 1;

  final allowedBudgetUpToToday = elapsedDaysInCurrentCycle * dailyLimit;

  double actualSpentInCurrentCycle = 0.0;
  for (final expense in expenses) {
    if (!expense.isPendingAi && expense.date.isAfter(currentCycleStart)) {
      actualSpentInCurrentCycle += expense.amount;
    }
  }

  final todaySpendingPower = allowedBudgetUpToToday - actualSpentInCurrentCycle;

  return SpendingPower(
    todaySpendingPower: todaySpendingPower,
    dailyLimit: dailyLimit,
    hasBudget: true,
  );
});