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

  // 2. Set or Update the budget with a dynamic period
  Future<void> setBudget(double limit, String period) async {
    // We delete any old budget rows first to ensure there is only ever ONE active budget row
    await delete(budgets).go();
    
    await into(budgets).insert(
      BudgetsCompanion.insert(
        limitAmount: limit,
        period: Value(period),
        startDate: DateTime.now(), // Sets the start date to exactly NOW!
      ),
    );
  }
}