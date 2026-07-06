import 'package:drift/drift.dart';

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // Replaces weeklyLimit. Stores the budget amount (e.g. 1400 or 6000)
  RealColumn get limitAmount => real()(); 
  
  // Stores the cycle (e.g. 'Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly')
  TextColumn get period => text().withDefault(const Constant('Weekly'))(); 
  
  DateTimeColumn get startDate => dateTime()();
}