import 'package:drift/drift.dart';

class Amortizations extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Links to the original expense that is being spread
  IntColumn get expenseId => integer().customConstraint(
    'NOT NULL REFERENCES expenses(id) ON DELETE CASCADE',
  )();

  // The total lump-sum amount being amortized (e.g. 350.0)
  RealColumn get totalAmount => real()();

  // Duration in days (e.g. 7)
  IntColumn get durationDays => integer()();

  // Computed straight-line daily cost: totalAmount / durationDays (e.g. 50.0)
  RealColumn get dailyBurden => real()();

  // Normalized midnight start date of amortization
  DateTimeColumn get startDate => dateTime()();

  // Normalized midnight expiration date (startDate + durationDays)
  DateTimeColumn get endDate => dateTime()();
}
