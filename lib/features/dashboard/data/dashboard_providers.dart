import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/dtos/category_sum.dart';
import '../../../core/database/dtos/trend_bar_data.dart';
import 'package:abushakir/abushakir.dart';
import '../../../core/utils/calendar_type_provider.dart';

// 1. WATCH CATEGORY SHARE (Queries the Expense DAO directly)
final categoryTotalsProvider = StreamProvider<List<CategorySum>>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  final activeFilter = ref.watch(timeFilterProvider);

  final calendarType = ref.watch(calendarTypeProvider);

  DateTime? startDate;
  final now = DateTime.now();
  final nowMidnight = DateTime(now.year, now.month, now.day);

  if (activeFilter == 'This Week') {
    startDate = nowMidnight.subtract(const Duration(days: 6));
  } else if (activeFilter == 'This Month') {
    if (calendarType == CalendarType.ethiopian) {
      final noonNow = nowMidnight.add(const Duration(hours: 12));
      final etNow = EtDatetime.fromMillisecondsSinceEpoch(noonNow.millisecondsSinceEpoch);
      final etMonthStart = EtDatetime(year: etNow.year, month: etNow.month, day: 1);
      final noonStart = DateTime.fromMillisecondsSinceEpoch(etMonthStart.moment + 43200000);
      startDate = DateTime(noonStart.year, noonStart.month, noonStart.day);
    } else {
      startDate = nowMidnight.subtract(Duration(days: now.weekday - 1)).subtract(const Duration(days: 21));
    }
  } else if (activeFilter == 'Last 3 Months') {
    if (calendarType == CalendarType.ethiopian) {
      final noonNow = nowMidnight.add(const Duration(hours: 12));
      final etNow = EtDatetime.fromMillisecondsSinceEpoch(noonNow.millisecondsSinceEpoch);
      int startMonth = etNow.month - 2;
      int startYear = etNow.year;
      if (startMonth <= 0) {
        startMonth += 13;
        startYear -= 1;
      }
      final etMonthStart = EtDatetime(year: startYear, month: startMonth, day: 1);
      final noonStart = DateTime.fromMillisecondsSinceEpoch(etMonthStart.moment + 43200000);
      startDate = DateTime(noonStart.year, noonStart.month, noonStart.day);
    } else {
      startDate = DateTime(now.year, now.month - 2, 1);
    }
  } else if (activeFilter == 'All Time') {
    startDate = null;
  } else {
    startDate = nowMidnight.subtract(const Duration(days: 6)); // Default
  }

  return expenseDao.watchTotalSpentByCategory(startDate: startDate);
});

// 2. Tracks the active Chart Type ('Pie' or 'Bar')
final chartTypeProvider = StateProvider<String>((ref) => 'Bar');

// 3. Tracks the active Trend Time Filter ('This Week', 'This Month', 'Last 3 Months')
final timeFilterProvider = StateProvider<String>((ref) => 'This Week');

// 4. Smart Stream Provider that swaps SQLite trend queries reactively!
final trendTotalsProvider = StreamProvider<List<TrendBarData>>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  
  // Watch the active time filter state!
  final activeFilter = ref.watch(timeFilterProvider);
  final calendarType = ref.watch(calendarTypeProvider);
  final isEthiopian = calendarType == CalendarType.ethiopian;

  // Dynamically plug/unplug the correct SQLite live stream
  if (activeFilter == 'This Month') {
    return expenseDao.watchMonthlyTrends(isEthiopian: isEthiopian);
  } else if (activeFilter == 'Last 3 Months') {
    return expenseDao.watchQuarterlyTrends(isEthiopian: isEthiopian);
  } else if (activeFilter == 'All Time') {
    return expenseDao.watchYearlyTrends(isEthiopian: isEthiopian);
  } else {
    return expenseDao.watchWeeklyTrends(isEthiopian: isEthiopian); // Default fallback for 'This Week'
  }
});

// 5. Watch sub-expenses for a specific category (respects the active time filter)
final categoryExpensesProvider = StreamProvider.family<List<Expense>, String>((ref, categoryName) {
  final expenseDao = ref.watch(expenseDaoProvider);
  final activeFilter = ref.watch(timeFilterProvider);
  final calendarType = ref.watch(calendarTypeProvider);

  DateTime? startDate;
  final now = DateTime.now();
  final nowMidnight = DateTime(now.year, now.month, now.day);

  if (activeFilter == 'This Week') {
    startDate = nowMidnight.subtract(const Duration(days: 6));
  } else if (activeFilter == 'This Month') {
    if (calendarType == CalendarType.ethiopian) {
      final noonNow = nowMidnight.add(const Duration(hours: 12));
      final etNow = EtDatetime.fromMillisecondsSinceEpoch(noonNow.millisecondsSinceEpoch);
      final etMonthStart = EtDatetime(year: etNow.year, month: etNow.month, day: 1);
      final noonStart = DateTime.fromMillisecondsSinceEpoch(etMonthStart.moment + 43200000);
      startDate = DateTime(noonStart.year, noonStart.month, noonStart.day);
    } else {
      startDate = nowMidnight.subtract(Duration(days: now.weekday - 1)).subtract(const Duration(days: 21));
    }
  } else if (activeFilter == 'Last 3 Months') {
    if (calendarType == CalendarType.ethiopian) {
      final noonNow = nowMidnight.add(const Duration(hours: 12));
      final etNow = EtDatetime.fromMillisecondsSinceEpoch(noonNow.millisecondsSinceEpoch);
      int startMonth = etNow.month - 2;
      int startYear = etNow.year;
      if (startMonth <= 0) {
        startMonth += 13;
        startYear -= 1;
      }
      final etMonthStart = EtDatetime(year: startYear, month: startMonth, day: 1);
      final noonStart = DateTime.fromMillisecondsSinceEpoch(etMonthStart.moment + 43200000);
      startDate = DateTime(noonStart.year, noonStart.month, noonStart.day);
    } else {
      startDate = DateTime(now.year, now.month - 2, 1);
    }
  } else if (activeFilter == 'All Time') {
    startDate = null;
  } else {
    startDate = nowMidnight.subtract(const Duration(days: 6));
  }

  return expenseDao.watchExpensesByCategory(categoryName, startDate: startDate);
});