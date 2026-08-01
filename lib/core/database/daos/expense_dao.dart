import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/expenses_table.dart';
import '../dtos/category_sum.dart';
import '../dtos/trend_bar_data.dart'; 

part 'expense_dao.g.dart';

@DriftAccessor(tables: [Expenses])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(AppDatabase db) : super(db);

  // 1. Live stream of expenses (reverses list to show newest at bottom)
  Stream<List<Expense>> watchExpenses() {
    return select(expenses).watch();
  }

  // 2. Insert expense
  Future<int> insertExpense(ExpensesCompanion companion) {
    return into(expenses).insert(companion);
  }

  // 3. Delete expense
  Future<int> deleteExpense(int id) {
    return (delete(expenses)..where((tbl) => tbl.id.equals(id))).go();
  }

  // 3.5 Update expense
  Future<bool> updateExpense(ExpensesCompanion companion) {
    return update(expenses).replace(companion);
  }

  // 4. Pie Chart Query (Group by Category)
  Stream<List<CategorySum>> watchTotalSpentByCategory() {
    final query = customSelect(
      'SELECT category, SUM(amount) as total FROM expenses WHERE is_pending_ai = 0 GROUP BY category',
      readsFrom: {expenses},
    );

    return query.watch().map((rows) {
      return rows.map((row) => CategorySum(
        row.read<String>('category'),
        row.read<double>('total'),
      )).toList();
    });
  }

  // 5. Weekly Daily Trends (Dart Native Grouping - Timezone Safe!)
  Stream<List<TrendBarData>> watchWeeklyTrends() {
    final limitDate = DateTime.now().subtract(const Duration(days: 6));
    final startOfLimit = DateTime(limitDate.year, limitDate.month, limitDate.day);

    return (select(expenses)
          ..where((tbl) => tbl.isPendingAi.equals(false) & tbl.date.isBiggerOrEqualValue(startOfLimit)))
        .watch()
        .map((rows) {
      final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final now = DateTime.now();
      
      final Map<String, double> trendMap = {};
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        trendMap[weekdays[date.weekday % 7]] = 0.0;
      }

      for (final row in rows) {
        final label = weekdays[row.date.weekday % 7];
        if (trendMap.containsKey(label)) {
          trendMap[label] = trendMap[label]! + row.amount;
        }
      }

      return trendMap.entries.map((entry) => TrendBarData(entry.key, entry.value)).toList();
    });
  }

  // 6. Monthly Weekly Trends (Dart Native Grouping - Timezone Safe!)
  Stream<List<TrendBarData>> watchMonthlyTrends() {
    final limitDate = DateTime.now().subtract(const Duration(days: 28)); // ~4 weeks
    final startOfLimit = DateTime(limitDate.year, limitDate.month, limitDate.day);
    
    return (select(expenses)
          ..where((tbl) => tbl.isPendingAi.equals(false) & tbl.date.isBiggerOrEqualValue(startOfLimit)))
        .watch()
        .map((rows) {
      final Map<String, double> trendMap = {
        'Week 1': 0.0,
        'Week 2': 0.0,
        'Week 3': 0.0,
        'Week 4': 0.0,
      };

      final now = DateTime.now();
      final nowMidnight = DateTime(now.year, now.month, now.day, 23, 59, 59);

      for (final row in rows) {
        final daysAgo = nowMidnight.difference(row.date).inDays;
        
        // 0-6 days ago = Week 4 (most recent)
        // 7-13 days ago = Week 3
        int weekIndex = 4 - (daysAgo ~/ 7);
        
        if (weekIndex >= 1 && weekIndex <= 4) {
          final label = 'Week $weekIndex';
          trendMap[label] = trendMap[label]! + row.amount;
        }
      }

      return trendMap.entries.map((entry) => TrendBarData(entry.key, entry.value)).toList();
    });
  }

  // 7. Quarterly Monthly Trends (Dart Native Grouping - Timezone Safe!)
  Stream<List<TrendBarData>> watchQuarterlyTrends() {
    final limitDate = DateTime.now().subtract(const Duration(days: 90));
    final startOfLimit = DateTime(limitDate.year, limitDate.month, limitDate.day);

    return (select(expenses)
          ..where((tbl) => tbl.isPendingAi.equals(false) & tbl.date.isBiggerOrEqualValue(startOfLimit)))
        .watch()
        .map((rows) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      final Map<String, double> trendMap = {};
      final now = DateTime.now();
      for (int i = 2; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final label = months[monthDate.month - 1];
        trendMap[label] = 0.0;
      }

      for (final row in rows) {
        final label = months[row.date.month - 1];
        if (trendMap.containsKey(label)) {
          trendMap[label] = trendMap[label]! + row.amount;
        }
      }

      return trendMap.entries.map((entry) => TrendBarData(entry.key, entry.value)).toList();
    });
  }
  // A direct, one-shot Future query (Bypasses lazy-loaded streams!)
  Future<List<CategorySum>> getCategoryTotals() async {
    final query = customSelect(
      'SELECT category, SUM(amount) as total FROM expenses WHERE is_pending_ai = 0 GROUP BY category',
      readsFrom: {expenses},
    );

    // .get() is a one-shot Future request instead of a live .watch() stream!
    final rows = await query.get(); 
    
    return rows.map((row) => CategorySum(
      row.read<String>('category'),
      row.read<double>('total'),
    )).toList();
  }

  // 5. NEW: Live stream of TODAY'S expenses only (00:00:00 to 23:59:59)
  Stream<List<Expense>> watchTodaysExpenses() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return (select(expenses)
          ..where((tbl) => tbl.date.isBetweenValues(start, end)))
        .watch();
  }

  // 6. NEW: Live stream of expenses for any SPECIFIC date (for our History Page)
  Stream<List<Expense>> watchExpensesForDate(DateTime selectedDate) {
    final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
    
    return (select(expenses)
          ..where((tbl) => tbl.date.isBetweenValues(start, end)))
        .watch();
  }

  // 7. NEW: One-shot query to fetch the entire last 90 days of transactions
  Future<List<Expense>> getExpensesForLast90Days() {
    final limitDate = DateTime.now().subtract(const Duration(days: 90));
    
    return (select(expenses)
          ..where((tbl) => tbl.isPendingAi.equals(false) & tbl.date.isBiggerThanValue(limitDate))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc)]))
        .get();
  }
}