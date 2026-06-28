import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// --- TABLE 1: EXPENSES ---
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawNote => text().withLength(min: 1, max: 1000)();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  TextColumn get category => text().withDefault(const Constant('Others'))(); // Default changed to 'Others'
  DateTimeColumn get date => dateTime()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  BoolColumn get isPendingAi => boolean().withDefault(const Constant(false))();
}

// --- NEW TABLE 2: DYNAMIC CATEGORY OPTIONS ---
class CategoryOptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()(); // Category names must be unique!
}

class CategorySum {
  final String category;
  final double total;
  CategorySum(this.category, this.total);
}

// --- DATABASE CONNECTION & SEEDING ---
@DriftDatabase(tables: [Expenses, CategoryOptions]) // Added CategoryOptions here
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Stream<List<CategorySum>> watchTotalSpentByCategory() {
    final query = customSelect(
      'SELECT category, SUM(amount) as total FROM expenses WHERE is_pending_ai = 0 GROUP BY category',
      readsFrom: {expenses}, 
    );

    return query.watch().map((rows) {
      return rows.map((row) => CategorySum(
        row.read<String>('category'),
        row.read<double>('total'),
      )).toList();
    });
  }

  // Fetch all active categories from the database
  Future<List<String>> getActiveCategories() async {
    final rows = await select(categoryOptions).get();
    return rows.map((row) => row.name).toList();
  }

  // --- SEEDING LOGIC ---
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        // 1. Create all tables
        await m.createAll();

        // 2. Seed our 5-Category MVP defaults instantly on first install!
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
    );
  }

  //Stream/Watch categories in real-time
  Stream<List<CategoryOption>> watchCategories() {
    return select(categoryOptions).watch();
  }

  //Insert a custom category
  Future<int> addCategory(String name) {
    return into(categoryOptions).insert(
      CategoryOptionsCompanion.insert(name: name),
    );
  }

  //Delete a category
  Future<int> deleteCategory(int id) {
    return (delete(categoryOptions)..where((tbl) => tbl.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'birr_note_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}