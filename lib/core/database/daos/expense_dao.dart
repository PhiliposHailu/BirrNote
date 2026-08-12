import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/expenses_table.dart';
import '../dtos/category_sum.dart';
import '../dtos/trend_bar_data.dart';
import 'package:abushakir/abushakir.dart';

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
  Stream<List<CategorySum>> watchTotalSpentByCategory({DateTime? startDate}) {
    String sql = 'SELECT category, SUM(amount) as total FROM expenses WHERE is_pending_ai = 0';
    List<Variable> variables = [];

    if (startDate != null) {
      sql += ' AND date >= ?';
      variables.add(Variable.withDateTime(startDate));
    }

    sql += ' GROUP BY category';

    final query = customSelect(
      sql,
      variables: variables,
      readsFrom: {expenses},
    );

    return query.watch().map((rows) {
      return rows.map((row) => CategorySum(
        row.read<String>('category'),
        row.read<double>('total'),
      )).toList();
    });
  }

  // 4.5. Accordion Sub-expenses Query (Highest to Lowest)
  Stream<List<Expense>> watchExpensesByCategory(String categoryName, {DateTime? startDate}) {
    var query = select(expenses)..where((tbl) => tbl.category.equals(categoryName) & tbl.isPendingAi.equals(false));
    
    if (startDate != null) {
      query = query..where((tbl) => tbl.date.isBiggerOrEqualValue(startDate));
    }
    
    query = query..orderBy([(t) => OrderingTerm(expression: t.amount, mode: OrderingMode.desc)]);
    return query.watch();
  }

  // 5. Weekly Daily Trends (Dart Native Grouping - Timezone Safe!)
  Stream<List<TrendBarData>> watchWeeklyTrends({bool isEthiopian = false}) {
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
  Stream<List<TrendBarData>> watchMonthlyTrends({bool isEthiopian = false}) {
    final now = DateTime.now();
    final nowMidnight = DateTime(now.year, now.month, now.day);
    
    DateTime startOfLimit;
    List<DateTime> weekStarts = [];
    
    if (isEthiopian) {
      final etNow = EtDatetime.fromMillisecondsSinceEpoch(nowMidnight.millisecondsSinceEpoch);
      weekStarts = [
        DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: etNow.year, month: etNow.month, day: 22).moment),
        DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: etNow.year, month: etNow.month, day: 15).moment),
        DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: etNow.year, month: etNow.month, day: 8).moment),
        DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: etNow.year, month: etNow.month, day: 1).moment),
      ];
      startOfLimit = weekStarts[3];
    } else {
      final week4Start = nowMidnight.subtract(Duration(days: now.weekday - 1));
      weekStarts = [
        week4Start,
        week4Start.subtract(const Duration(days: 7)),
        week4Start.subtract(const Duration(days: 14)),
        week4Start.subtract(const Duration(days: 21)),
      ];
      startOfLimit = weekStarts[3];
    }
    
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

      for (final row in rows) {
        if (!row.date.isBefore(weekStarts[0])) {
          trendMap['Week 4'] = trendMap['Week 4']! + row.amount;
        } else if (!row.date.isBefore(weekStarts[1])) {
          trendMap['Week 3'] = trendMap['Week 3']! + row.amount;
        } else if (!row.date.isBefore(weekStarts[2])) {
          trendMap['Week 2'] = trendMap['Week 2']! + row.amount;
        } else if (!row.date.isBefore(weekStarts[3])) {
          trendMap['Week 1'] = trendMap['Week 1']! + row.amount;
        }
      }

      return trendMap.entries.map((entry) => TrendBarData(entry.key, entry.value)).toList();
    });
  }

  // 7. Quarterly Monthly Trends (Dart Native Grouping - Timezone Safe!)
  Stream<List<TrendBarData>> watchQuarterlyTrends({bool isEthiopian = false}) {
    final now = DateTime.now();
    DateTime startOfLimit;
    List<String> months = [];

    if (isEthiopian) {
      final etNow = EtDatetime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch);
      int startMonth = etNow.month - 2;
      int startYear = etNow.year;
      if (startMonth <= 0) {
        startMonth += 13;
        startYear -= 1;
      }
      startOfLimit = DateTime.fromMillisecondsSinceEpoch(EtDatetime(year: startYear, month: startMonth, day: 1).moment);
      months = ['Mesk', 'Tik', 'Hidar', 'Tahsas', 'Tir', 'Yakatit', 'Magabit', 'Miyazya', 'Ginbot', 'Sene', 'Hamle', 'Nehase', 'Pagume'];
    } else {
      startOfLimit = DateTime(now.year, now.month - 2, 1);
      months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    }

    return (select(expenses)
          ..where((tbl) => tbl.isPendingAi.equals(false) & tbl.date.isBiggerOrEqualValue(startOfLimit)))
        .watch()
        .map((rows) {
      final Map<String, double> trendMap = {};

      if (isEthiopian) {
        final etNow = EtDatetime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch);
        for (int i = 2; i >= 0; i--) {
          int m = etNow.month - i;
          if (m <= 0) m += 13;
          trendMap[months[m - 1]] = 0.0;
        }
        for (final row in rows) {
          final etDate = EtDatetime.fromMillisecondsSinceEpoch(row.date.millisecondsSinceEpoch);
          final label = months[etDate.month - 1];
          if (trendMap.containsKey(label)) {
            trendMap[label] = trendMap[label]! + row.amount;
          }
        }
      } else {
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
      }
      return trendMap.entries.map((entry) => TrendBarData(entry.key, entry.value)).toList();
    });
  }

  // 7.5 Yearly Trends (All Time)
  Stream<List<TrendBarData>> watchYearlyTrends({bool isEthiopian = false}) {
    return (select(expenses)..where((tbl) => tbl.isPendingAi.equals(false)))
        .watch()
        .map((rows) {
      final Map<String, double> trendMap = {};
      final now = DateTime.now();
      
      if (isEthiopian) {
        final etNow = EtDatetime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch);
        for (int i = 2; i >= 0; i--) {
          trendMap[(etNow.year - i).toString()] = 0.0;
        }
        for (final row in rows) {
          final etDate = EtDatetime.fromMillisecondsSinceEpoch(row.date.millisecondsSinceEpoch);
          final label = etDate.year.toString();
          trendMap[label] = (trendMap[label] ?? 0.0) + row.amount;
        }
      } else {
        for (int i = 2; i >= 0; i--) {
          trendMap[(now.year - i).toString()] = 0.0;
        }
        for (final row in rows) {
          final label = row.date.year.toString();
          trendMap[label] = (trendMap[label] ?? 0.0) + row.amount;
        }
      }

      final sortedKeys = trendMap.keys.toList()..sort();
      return sortedKeys.map((k) => TrendBarData(k, trendMap[k]!)).toList();
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

  // 8. NEW: One-shot query to fetch the entire active Quarter of transactions
  Future<List<Expense>> getExpensesForLastQuarter() {
    final now = DateTime.now();
    // Align with the true calendar shifting used by the charts
    final limitDate = DateTime(now.year, now.month - 2, 1);
    
    return (select(expenses)
          ..where((tbl) => tbl.isPendingAi.equals(false) & tbl.date.isBiggerOrEqualValue(limitDate))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc)]))
        .get();
  }
}