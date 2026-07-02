import 'package:drift/drift.dart';

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get weeklyLimit => real()();
  DateTimeColumn get startDate => dateTime()();
}