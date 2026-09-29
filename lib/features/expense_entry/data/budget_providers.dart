import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abushakir/abushakir.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
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
  final double totalDailyAmortizedBurden;
  final int activeAmortizationsCount;

  SpendingPower({
    required this.todaySpendingPower,
    required this.dailyLimit,
    required this.hasBudget,
    this.totalDailyAmortizedBurden = 0.0,
    this.activeAmortizationsCount = 0,
  });
}

// THE UPGRADED ENGINE
final budgetEngineProvider = Provider<SpendingPower>((ref) {
  final activeBudgetAsync = ref.watch(activeBudgetStreamProvider);
  // Watching the all-time database stream instead of today-only!
  final expensesAsync = ref.watch(allExpensesStreamProvider);
  final amortizationsAsync = ref.watch(allAmortizationsStreamProvider);
  final calendarType = ref.watch(calendarTypeProvider);

  if (activeBudgetAsync.isLoading ||
      expensesAsync.isLoading ||
      amortizationsAsync.isLoading) {
    return SpendingPower(
      todaySpendingPower: 0,
      dailyLimit: 0,
      hasBudget: false,
    );
  }

  final budget = activeBudgetAsync.value;
  final expenses = expensesAsync.value ?? [];
  final amortizations = amortizationsAsync.value ?? [];

  if (budget == null) {
    return SpendingPower(
      todaySpendingPower: 0,
      dailyLimit: 0,
      hasBudget: false,
    );
  }

  final limitAmount = budget.limitAmount;
  final startDate = budget.startDate;
  final String period = budget.period;

  // 1. DYNAMIC PERIOD MAPPING (THE CALENDAR ENGINE REWRITE)
  final now = DateTime.now();
  final nowMidnight = DateTime(now.year, now.month, now.day);
  final startMidnight = DateTime(
    startDate.year,
    startDate.month,
    startDate.day,
  );

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
      final etNow = EtDatetime.fromMillisecondsSinceEpoch(
        nowMidnight.millisecondsSinceEpoch,
      );
      currentCycleStart = DateTime.fromMillisecondsSinceEpoch(
        EtDatetime(year: etNow.year, month: etNow.month, day: 1).moment,
      );
      nextCycleStart = etNow.month == 13
          ? DateTime.fromMillisecondsSinceEpoch(
              EtDatetime(year: etNow.year + 1, month: 1, day: 1).moment,
            )
          : DateTime.fromMillisecondsSinceEpoch(
              EtDatetime(
                year: etNow.year,
                month: etNow.month + 1,
                day: 1,
              ).moment,
            );
    } else {
      currentCycleStart = DateTime(nowMidnight.year, nowMidnight.month, 1);
      nextCycleStart = DateTime(nowMidnight.year, nowMidnight.month + 1, 1);
    }
  } else if (period == 'Quarterly') {
    if (calendarType == CalendarType.ethiopian) {
      final etNow = EtDatetime.fromMillisecondsSinceEpoch(
        nowMidnight.millisecondsSinceEpoch,
      );
      final quarterMonth = ((etNow.month - 1) ~/ 3) * 3 + 1; // 1, 4, 7, 10
      currentCycleStart = DateTime.fromMillisecondsSinceEpoch(
        EtDatetime(year: etNow.year, month: quarterMonth, day: 1).moment,
      );
      nextCycleStart = (quarterMonth + 3 > 13)
          ? DateTime.fromMillisecondsSinceEpoch(
              EtDatetime(year: etNow.year + 1, month: 1, day: 1).moment,
            )
          : DateTime.fromMillisecondsSinceEpoch(
              EtDatetime(
                year: etNow.year,
                month: quarterMonth + 3,
                day: 1,
              ).moment,
            );
    } else {
      final quarterMonth = ((nowMidnight.month - 1) ~/ 3) * 3 + 1;
      currentCycleStart = DateTime(nowMidnight.year, quarterMonth, 1);
      nextCycleStart = DateTime(nowMidnight.year, quarterMonth + 3, 1);
    }
  } else if (period == 'Yearly') {
    if (calendarType == CalendarType.ethiopian) {
      final etNow = EtDatetime.fromMillisecondsSinceEpoch(
        nowMidnight.millisecondsSinceEpoch,
      );
      currentCycleStart = DateTime.fromMillisecondsSinceEpoch(
        EtDatetime(year: etNow.year, month: 1, day: 1).moment,
      );
      nextCycleStart = DateTime.fromMillisecondsSinceEpoch(
        EtDatetime(year: etNow.year + 1, month: 1, day: 1).moment,
      );
    } else {
      currentCycleStart = DateTime(nowMidnight.year, 1, 1);
      nextCycleStart = DateTime(nowMidnight.year + 1, 1, 1);
    }
  } else {
    currentCycleStart = startMidnight;
    nextCycleStart = currentCycleStart.add(const Duration(days: 7));
  }

  // The total days in THIS specific cycle (e.g., handles 28, 29, 30, 31 for months!)
  final daysInCurrentCycle = nextCycleStart
      .difference(currentCycleStart)
      .inDays;

  // The exact daily limit tailored to THIS specific calendar cycle
  final exactDailyLimit = limitAmount / daysInCurrentCycle;

  // The days elapsed in the current cycle (including today)
  final elapsedDaysInCurrentCycle =
      nowMidnight.difference(currentCycleStart).inDays + 1;

  // How much they were allowed to spend up to today
  final allowedBudgetUpToToday = elapsedDaysInCurrentCycle * exactDailyLimit;

  // 1. Calculate active amortizations today and collect amortized expense IDs
  double totalDailyAmortizedBurden = 0.0;
  int activeAmortizationsCount = 0;
  final Set<int> amortizedExpenseIds = {};

  for (final a in amortizations) {
    amortizedExpenseIds.add(a.expenseId);
    if (!a.startDate.isAfter(nowMidnight) && a.endDate.isAfter(nowMidnight)) {
      totalDailyAmortizedBurden += a.dailyBurden;
      activeAmortizationsCount++;
    }
  }

  // 2. Sum up regular expenses spent in this active cycle (excluding amortized ones)
  double regularSpentInCurrentCycle = 0.0;
  for (final expense in expenses) {
    if (!expense.isPendingAi &&
        !amortizedExpenseIds.contains(expense.id) &&
        !expense.date.isBefore(currentCycleStart) &&
        expense.date.isBefore(nextCycleStart)) {
      regularSpentInCurrentCycle += expense.amount;
    }
  }

  // 3. Compute cycle amortization burden using the cycle-overlap algorithm
  double totalAmortizedBurdenInCycle = 0.0;
  for (final a in amortizations) {
    final windowStart = a.startDate.isAfter(currentCycleStart)
        ? a.startDate
        : currentCycleStart;
    final windowEnd = a.endDate.isBefore(nextCycleStart)
        ? a.endDate
        : nextCycleStart;

    if (windowStart.isBefore(windowEnd) && !windowStart.isAfter(nowMidnight)) {
      final tomorrowMidnight = nowMidnight.add(const Duration(days: 1));
      final effectiveEnd = tomorrowMidnight.isBefore(windowEnd)
          ? tomorrowMidnight
          : windowEnd;
      final elapsedDays = effectiveEnd.difference(windowStart).inDays;
      if (elapsedDays > 0) {
        totalAmortizedBurdenInCycle += elapsedDays * a.dailyBurden;
      }
    }
  }

  // Today's Spending Power!
  final todaySpendingPower =
      allowedBudgetUpToToday -
      regularSpentInCurrentCycle -
      totalAmortizedBurdenInCycle;

  return SpendingPower(
    todaySpendingPower: todaySpendingPower,
    dailyLimit: exactDailyLimit,
    hasBudget: true,
    totalDailyAmortizedBurden: totalDailyAmortizedBurden,
    activeAmortizationsCount: activeAmortizationsCount,
  );
});
