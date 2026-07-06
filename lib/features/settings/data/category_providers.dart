import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/category_dao.dart';

// 1. WATCH CATEGORY NAMES (Queries the DAO directly!)
final categoryNamesStreamProvider = StreamProvider<List<String>>((ref) {
  final categoryDao = ref.watch(categoryDaoProvider);
  return categoryDao.watchCategoryNames();
});

// 2. CATEGORY MANAGER
class CategoryManager {
  final CategoryDao categoryDao; // Changed from AppDatabase to CategoryDao
  CategoryManager(this.categoryDao);

  Future<void> add(String name) async {
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) return;
    
    try {
      await categoryDao.addCategoryOption(cleanedName);
    } catch (e) {
      print("Error adding category: $e");
    }
  }

  Future<void> delete(String name) async {
    if (name == 'Others') return; 
    await categoryDao.deleteCategoryOption(name);
  }

  Future<void> reset() async {
    await categoryDao.resetCategoriesToDefault();
  }

  // Triggers the database reorder transaction
  Future<void> reorder(List<String> orderedNames) async {
    await categoryDao.updateCategoryOrder(orderedNames);
  }
}

final categoryManagerProvider = Provider<CategoryManager>((ref) {
  return CategoryManager(ref.watch(categoryDaoProvider));
});