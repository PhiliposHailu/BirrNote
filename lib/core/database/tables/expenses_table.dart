import 'package:drift/drift.dart';

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawNote => text().withLength(min: 1, max: 1000)();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  TextColumn get category => text().withDefault(const Constant('Others'))();
  DateTimeColumn get date => dateTime()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  BoolColumn get isPendingAi => boolean().withDefault(const Constant(false))();
}