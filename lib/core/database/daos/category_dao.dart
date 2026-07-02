import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/category_options_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [CategoryOptions])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(AppDatabase db) : super(db);

  // 1. Live stream of category names
  Stream<List<String>> watchCategoryNames() {
    return select(categoryOptions)
        .watch()
        .map((rows) => rows.map((row) => row.name).toList());
  }

  // 2. Get active category list (as a plain Future list of strings)
  Future<List<String>> getActiveCategories() async {
    final rows = await select(categoryOptions).get();
    return rows.map((row) => row.name).toList();
  }

  // 3. Add a custom category
  Future<int> addCategoryOption(String name) {
    return into(categoryOptions).insert(
      CategoryOptionsCompanion.insert(name: name),
    );
  }

  // 4. Delete a category
  Future<int> deleteCategoryOption(String name) {
    return (delete(categoryOptions)..where((tbl) => tbl.name.equals(name))).go();
  }

  // 5. Reset categories to defaults
  Future<void> resetCategoriesToDefault() async {
    await delete(categoryOptions).go();

    final defaultCategories = [
      'Food & Drinks',
      'Transport',
      'Shopping',
      'Bills',
      'Others',
    ];

    for (final name in defaultCategories) {
      await into(categoryOptions).insert(
        CategoryOptionsCompanion.insert(name: name),
      );
    }
  }
}