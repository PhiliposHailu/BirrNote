import 'package:drift/drift.dart';

class CategoryOptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()(); // Category names must be unique!
}