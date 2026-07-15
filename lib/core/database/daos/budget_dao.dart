import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/budgets_table.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(AppDatabase db) : super(db);

  // 1. Get the single active budget
  Stream<Budget?> watchActiveBudget() {
    return (select(budgets)..limit(1)).watchSingleOrNull();
  }

  // 2. Set the budget and automatically calculate the natural calendar start date!
  Future<void> setBudget(double limit, String period) async {
    // Delete any old budget settings first
    await delete(budgets).go();

    final now = DateTime.now();
    
    // Default fallback: Today at the very first second of the morning (00:00:00)
    DateTime adjustedStartDate = DateTime(now.year, now.month, now.day); 

    if (period == 'Weekly') {
      // THE MAGIC: Find the nearest past Monday morning at 00:00:00!
      // (now.weekday is 1 for Monday, 3 for Wednesday, etc.)
      adjustedStartDate = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    } else if (period == 'Monthly') {
      // THE MAGIC: Find the 1st of the current month at 00:00:00!
      adjustedStartDate = DateTime(now.year, now.month, 1);
    } else if (period == 'Yearly') {
      // THE MAGIC: Find January 1st of the current year at 00:00:00!
      adjustedStartDate = DateTime(now.year, 1, 1);
    }

    await into(budgets).insert(
      BudgetsCompanion.insert(
        limitAmount: limit,
        period: Value(period),
        startDate: adjustedStartDate, // Saved as the natural cycle start!
      ),
    );
  }

  // 3. Delete the budget (The Emergency Exit)
  Future<void> deleteBudget() async {
    await delete(budgets).go();
  }
}