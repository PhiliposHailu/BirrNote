import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/category_options_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [CategoryOptions])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(AppDatabase db) : super(db);

  // 1. Watch categories sorted by orderIndex ascending!
  Stream<List<String>> watchCategoryNames() {
    return (select(categoryOptions)
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex, mode: OrderingMode.asc)]))
        .watch()
        .map((rows) => rows.map((row) => row.name).toList());
  }

  // 2. Get active category list sorted by orderIndex ascending!
  Future<List<String>> getActiveCategories() async {
    final rows = await (select(categoryOptions)
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex, mode: OrderingMode.asc)]))
        .get();
    return rows.map((row) => row.name).toList();
  }

  // 3. Add a custom category (We set its orderIndex to the bottom of the list)
  Future<int> addCategoryOption(String name) async {
    final currentCategories = await getActiveCategories();
    return into(categoryOptions).insert(
      CategoryOptionsCompanion.insert(
        name: name,
        orderIndex: Value(currentCategories.length), // Put at the bottom!
      ),
    );
  }

  // 4. Delete a category
  Future<int> deleteCategoryOption(String name) {
    return (delete(categoryOptions)..where((tbl) => tbl.name.equals(name))).go();
  }

  // 5. The Drag-and-Drop Reorder transaction!
  Future<void> updateCategoryOrder(List<String> orderedNames) async {
    // We run this inside a transaction to ensure all updates succeed together
    await transaction(() async {
      for (int i = 0; i < orderedNames.length; i++) {
        await (update(categoryOptions)..where((t) => t.name.equals(orderedNames[i])))
            .write(CategoryOptionsCompanion(orderIndex: Value(i)));
      }
    });
  }

  // 6. Reset to default 5 categories (with correct starting orderIndex 0 to 4)
  Future<void> resetCategoriesToDefault() async {
    await delete(categoryOptions).go();

    final defaultCategories = [
      'Food & Drinks',
      'Transport',
      'Shopping',
      'Bills',
      'Others',
    ];

    for (int i = 0; i < defaultCategories.length; i++) {
      await into(categoryOptions).insert(
        CategoryOptionsCompanion.insert(
          name: defaultCategories[i],
          orderIndex: Value(i), // Keeps default order
        ),
      );
    }
  }
}