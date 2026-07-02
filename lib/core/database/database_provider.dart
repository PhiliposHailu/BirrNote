import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'daos/expense_dao.dart';
import 'daos/category_dao.dart';
import 'daos/budget_dao.dart';

// 1. The Core Database Connection Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// 2. EXPOSE THE EXPENSE REPOSITORY
final expenseDaoProvider = Provider<ExpenseDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.expenseDao; // Accesses the generated getter in app_database.g.dart
});

// 3. EXPOSE THE CATEGORY REPOSITORY
final categoryDaoProvider = Provider<CategoryDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.categoryDao;
});

// 4. EXPOSE THE BUDGET REPOSITORY
final budgetDaoProvider = Provider<BudgetDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.budgetDao;
});