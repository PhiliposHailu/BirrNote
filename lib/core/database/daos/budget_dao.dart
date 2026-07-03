import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/budgets_table.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(AppDatabase db) : super(db);

  // 1. Live stream of the active budget (returns null if they haven't set one yet)
  Stream<Budget?> watchActiveBudget() {
    return (select(budgets)..limit(1)).watchSingleOrNull();
  }

  // 2. Set or Update the budget
  Future<void> setWeeklyBudget(double limit) async {
    // HCI Safety: We delete any old budget settings first 
    // to ensure there is only ever ONE active budget row in our database.
    await delete(budgets).go();
    
    await into(budgets).insert(
      BudgetsCompanion.insert(
        weeklyLimit: limit,
        startDate: DateTime.now(), // Sets the start date to exactly NOW!
      ),
    );
  }
}