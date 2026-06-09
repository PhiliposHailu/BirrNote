import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
part 'app_database.g.dart';

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawNote => text().withLength(min: 1, max: 1000)();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  TextColumn get category => text().withDefault(const Constant('Uncategorized'))();
  DateTimeColumn get date => dateTime()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  BoolColumn get isPendingAi => boolean().withDefault(const Constant(false))();
}

class CategorySum {
  final String category;
  final double total;
  CategorySum(this.category, this.total);
}

@DriftDatabase(tables: [Expenses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Stream<List<CategorySum>> watchTotalSpentByCategory() {
    // We write standard SQL to group by category and sum the amounts.
    // We only include items that are NOT pending (is_pending_ai = 0).
    final query = customSelect(
      'SELECT category, SUM(amount) as total FROM expenses WHERE is_pending_ai = 0 GROUP BY category',
      // Drift needs to know which table changes should trigger a UI update.
      readsFrom: {expenses}, 
    );

    // We map the raw SQL rows into our clean Dart object ???
    return query.watch().map((rows) {
      return rows.map((row) => CategorySum(
        row.read<String>('category'),
        row.read<double>('total'),
      )).toList();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'birr_note_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}