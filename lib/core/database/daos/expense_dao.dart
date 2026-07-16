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

  // 5. Weekly Daily Trends (Using Unix Epoch & Localtime modifiers)
  Stream<List<TrendBarData>> watchWeeklyTrends() {
    final query = customSelect(
      "SELECT strftime('%w', date, 'unixepoch', 'localtime') as day_index, SUM(amount) as total "
      "FROM expenses "
      "WHERE is_pending_ai = 0 AND date >= strftime('%s', 'now', '-6 days') "
      "GROUP BY day_index",
      readsFrom: {expenses},
    );

    return query.watch().map((rows) {
      final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      
      final now = DateTime.now();
      final Map<String, double> trendMap = {};
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        trendMap[weekdays[date.weekday % 7]] = 0.0;
      }

      for (final row in rows) {
        final int index = int.parse(row.read<String>('day_index'));
        final label = weekdays[index];
        if (trendMap.containsKey(label)) {
          trendMap[label] = row.read<double>('total');
        }
      }

      return trendMap.entries.map((entry) => TrendBarData(entry.key, entry.value)).toList();
    });
  }

  // 6. Monthly Weekly Trends (Using Unix Epoch & Localtime modifiers)
  Stream<List<TrendBarData>> watchMonthlyTrends() {
    final query = customSelect(
      "SELECT strftime('%W', date, 'unixepoch', 'localtime') as week_num, SUM(amount) as total "
      "FROM expenses "
      "WHERE is_pending_ai = 0 AND date >= strftime('%s', 'now', '-29 days') "
      "GROUP BY week_num",
      readsFrom: {expenses},
    );

    return query.watch().map((rows) {
      final Map<String, double> trendMap = {
        'Week 1': 0.0,
        'Week 2': 0.0,
        'Week 3': 0.0,
        'Week 4': 0.0,
      };

      final sortedWeeks = rows.map((r) => r.read<String>('week_num')).toList()..sort();

      for (final row in rows) {
        final weekNum = row.read<String>('week_num');
        final relativeIndex = sortedWeeks.indexOf(weekNum);
        
        if (relativeIndex >= 0 && relativeIndex < 4) {
          final label = 'Week ${relativeIndex + 1}';
          trendMap[label] = row.read<double>('total');
        }
      }

      return trendMap.entries.map((entry) => TrendBarData(entry.key, entry.value)).toList();
    });
  }

  // 7. Quarterly Monthly Trends (Using Unix Epoch & Localtime modifiers)
  Stream<List<TrendBarData>> watchQuarterlyTrends() {
    final query = customSelect(
      "SELECT strftime('%m', date, 'unixepoch', 'localtime') as month_num, SUM(amount) as total "
      "FROM expenses "
      "WHERE is_pending_ai = 0 AND date >= strftime('%s', 'now', '-90 days') "
      "GROUP BY month_num",
      readsFrom: {expenses},
    );

    return query.watch().map((rows) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      final Map<String, double> trendMap = {};
      final now = DateTime.now();
      for (int i = 2; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final label = months[monthDate.month - 1];
        trendMap[label] = 0.0;
      }

      for (final row in rows) {
        final int index = int.parse(row.read<String>('month_num'));
        final label = months[index - 1];
        if (trendMap.containsKey(label)) {
          trendMap[label] = row.read<double>('total');
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
}