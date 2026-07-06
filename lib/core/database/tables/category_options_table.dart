import 'package:drift/drift.dart';

class CategoryOptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  
  // Stores the drag-and-drop position (defaults to 0)
  IntColumn get orderIndex => integer().withDefault(const Constant(0))(); 
}