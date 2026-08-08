import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abushakir/abushakir.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/budget_dao.dart';
import '../../../core/utils/calendar_type_provider.dart';
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
  final calendarType = ref.watch(calendarTypeProvider);

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

  // 1. DYNAMIC PERIOD MAPPING (THE CALENDAR ENGINE REWRITE)
  final now = DateTime.now();
  final nowMidnight = DateTime(now.year, now.month, now.day);
  final startMidnight = DateTime(startDate.year, startDate.month, startDate.day);

  DateTime currentCycleStart;
  DateTime nextCycleStart;

  if (period == 'Daily') {
    currentCycleStart = nowMidnight;
    nextCycleStart = nowMidnight.add(const Duration(days: 1));
  } else if (period == 'Weekly') {
    final diffDays = nowMidnight.difference(startMidnight).inDays;
    final completedWeeks = (diffDays >= 0 ? diffDays : 0) ~/ 7;
    currentCycleStart = startMidnight.add(Duration(days: completedWeeks * 7));
    nextCycleStart = currentCycleStart.add(const Duration(days: 7));
  } else if (period == 'Monthly') {
    if (calendarType == CalendarType.ethiopian) {
      final etNow = EtDatetime.fromMillisecondsSinceEpoch(nowMidnight.millisecondsSinceEpoch);
      currentCycleStart = DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: etNow.year, month: etNow.month, day: 1).moment);
      nextCycleStart = etNow.month == 13 
          ? DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: etNow.year + 1, month: 1, day: 1).moment)
          : DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: etNow.year, month: etNow.month + 1, day: 1).moment);
    } else {
      currentCycleStart = DateTime(nowMidnight.year, nowMidnight.month, 1);
      nextCycleStart = DateTime(nowMidnight.year, nowMidnight.month + 1, 1);
    }
  } else if (period == 'Quarterly') {
    if (calendarType == CalendarType.ethiopian) {
      final etNow = EtDatetime.fromMillisecondsSinceEpoch(nowMidnight.millisecondsSinceEpoch);
      final quarterMonth = ((etNow.month - 1) ~/ 3) * 3 + 1; // 1, 4, 7, 10
      currentCycleStart = DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: etNow.year, month: quarterMonth, day: 1).moment);
      nextCycleStart = (quarterMonth + 3 > 13)
          ? DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: etNow.year + 1, month: 1, day: 1).moment)
          : DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: etNow.year, month: quarterMonth + 3, day: 1).moment);
    } else {
      final quarterMonth = ((nowMidnight.month - 1) ~/ 3) * 3 + 1;
      currentCycleStart = DateTime(nowMidnight.year, quarterMonth, 1);
      nextCycleStart = DateTime(nowMidnight.year, quarterMonth + 3, 1);
    }
  } else if (period == 'Yearly') {
    if (calendarType == CalendarType.ethiopian) {
      final etNow = EtDatetime.fromMillisecondsSinceEpoch(nowMidnight.millisecondsSinceEpoch);
      currentCycleStart = DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: etNow.year, month: 1, day: 1).moment);
      nextCycleStart = DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: etNow.year + 1, month: 1, day: 1).moment);
    } else {
      currentCycleStart = DateTime(nowMidnight.year, 1, 1);
      nextCycleStart = DateTime(nowMidnight.year + 1, 1, 1);
    }
  } else {
    currentCycleStart = startMidnight;
    nextCycleStart = currentCycleStart.add(const Duration(days: 7));
  }

  // The total days in THIS specific cycle (e.g., handles 28, 29, 30, 31 for months!)
  final daysInCurrentCycle = nextCycleStart.difference(currentCycleStart).inDays;
  
  // The exact daily limit tailored to THIS specific calendar cycle
  final exactDailyLimit = limitAmount / daysInCurrentCycle;

  // The days elapsed in the current cycle (including today)
  final elapsedDaysInCurrentCycle = nowMidnight.difference(currentCycleStart).inDays + 1;

  // How much they were allowed to spend up to today
  final allowedBudgetUpToToday = elapsedDaysInCurrentCycle * exactDailyLimit;

  // Sum up all expenses spent in this active cycle
  double actualSpentInCurrentCycle = 0.0;
  for (final expense in expenses) {
    if (!expense.isPendingAi && !expense.date.isBefore(currentCycleStart) && expense.date.isBefore(nextCycleStart)) {
      actualSpentInCurrentCycle += expense.amount;
    }
  }

  // Today's Spending Power!
  final todaySpendingPower = allowedBudgetUpToToday - actualSpentInCurrentCycle;

  return SpendingPower(
    todaySpendingPower: todaySpendingPower,
    dailyLimit: exactDailyLimit,
    hasBudget: true,
  );
});