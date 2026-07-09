import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/dtos/category_sum.dart';
import '../../../core/database/dtos/trend_bar_data.dart'; 

// 1. WATCH CATEGORY SHARE (Queries the Expense DAO directly)
final categoryTotalsProvider = StreamProvider<List<CategorySum>>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  return expenseDao.watchTotalSpentByCategory();
});

// 2. Tracks the active Chart Type ('Pie' or 'Bar')
final chartTypeProvider = StateProvider<String>((ref) => 'Pie');

// 3. Tracks the active Trend Time Filter ('This Week', 'This Month', 'Last 3 Months')
final timeFilterProvider = StateProvider<String>((ref) => 'This Week');

// 4. Smart Stream Provider that swaps SQLite trend queries reactively!
final trendTotalsProvider = StreamProvider<List<TrendBarData>>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  
  // Watch the active time filter state!
  final activeFilter = ref.watch(timeFilterProvider);

  // Dynamically plug/unplug the correct SQLite live stream
  if (activeFilter == 'This Month') {
    return expenseDao.watchMonthlyTrends();
  } else if (activeFilter == 'Last 3 Months') {
    return expenseDao.watchQuarterlyTrends();
  } else {
    return expenseDao.watchWeeklyTrends(); // Default fallback for 'This Week'
  }
});