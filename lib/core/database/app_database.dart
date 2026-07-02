import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// 1. Import our split Table blueprints
import 'tables/expenses_table.dart';
import 'tables/category_options_table.dart';
import 'tables/budgets_table.dart';

// 2. Import our upcoming DAOs (Repositories)
import 'daos/expense_dao.dart';
import 'daos/category_dao.dart';
import 'daos/budget_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Expenses, CategoryOptions, Budgets],
  daos: [ExpenseDao, CategoryDao, BudgetDao], // Plugs in our repositories!
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        // Create all tables on a fresh install
        await m.createAll();

        // Seed defaults
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
      },
      onUpgrade: (m, from, to) async {
        // Migration logic remains safe and intact!
        if (from < 2) {
          await m.createTable(budgets);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'birr_note_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}