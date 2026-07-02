import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/dtos/category_sum.dart';

// WATCH CATEGORY TOTALS (Queries the Expense DAO directly!)
final categoryTotalsProvider = StreamProvider<List<CategorySum>>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  return expenseDao.watchTotalSpentByCategory();
});