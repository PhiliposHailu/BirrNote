import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

// A simple live stream that pushes the updated Pie Chart data automatically!
final categoryTotalsProvider = StreamProvider<List<CategorySum>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchTotalSpentByCategory();
});