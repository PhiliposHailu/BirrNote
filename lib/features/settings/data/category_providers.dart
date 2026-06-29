import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

// 1. Watches the live list of categories from SQLite
final categoryNamesStreamProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchCategoryNames();
});

// 2. Holds the logic for Category Management
class CategoryManager {
  final AppDatabase db;
  CategoryManager(this.db);

  Future<void> add(String name) async {
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) return;
    
    try {
      await db.addCategoryOption(cleanedName);
    } catch (e) {
      print("Error adding category: $e"); // Handles duplicate name errors silently
    }
  }

  Future<void> delete(String name) async {
    // HCI GUARD: Never let them delete 'Others'
    if (name == 'Others') return; 
    await db.deleteCategoryOption(name);
  }

  Future<void> reset() async {
    await db.resetCategoriesToDefault();
  }
}

final categoryManagerProvider = Provider<CategoryManager>((ref) {
  return CategoryManager(ref.watch(databaseProvider));
});