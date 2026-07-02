import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/budgets_table.dart';

part 'budget_dao.g.dart';

// We create this class with a simple query for now.
// We will put the rollover spending power calculations here in the next stage!
@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(AppDatabase db) : super(db);

  Stream<List<Budget>> watchAllBudgets() {
    return select(budgets).watch();
  }
}