import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// 1. DEFINE OUR TABLE
class Expenses extends Table {
  // The unique ID for each expense
  IntColumn get id => integer().autoIncrement()();

  // The exact text the user typed (e.g., "Coffee 50")
  TextColumn get rawNote => text().withLength(min: 1, max: 1000)();

  // The structured data the AI (or manual form) will fill out
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  TextColumn get category =>
      text().withDefault(const Constant('Uncategorized'))();
  DateTimeColumn get date => dateTime()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  // THE OFFLINE MAGIC: If this is true, it means the AI hasn't parsed this note yet.
  BoolColumn get isPendingAi => boolean().withDefault(const Constant(false))();
}

// 2. CREATE THE DATABASE CLASS
@DriftDatabase(tables: [Expenses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1; // If we add new columns later, we change this to 2
}

// 3. SECURELY STORE THE DATABASE FILE
LazyDatabase _openConnection() {
  // THE WHY: LazyDatabase ensures we don't block the UI when the app starts.
  // It only opens the database the exact moment we need to save or read data.
  return LazyDatabase(() async {
    // Finds the correct safe folder on iOS/Android to store app data
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'birr_note_db.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
