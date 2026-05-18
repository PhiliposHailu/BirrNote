import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';

// 1. THE READER (Live Stream of Expenses)
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final db = ref.watch(databaseProvider);
  // This listens to the expenses table and automatically updates when data changes.
  return db.select(db.expenses).watch(); 
});

// 2. THE WRITER (Logic to save a new note)
class ExpenseLogic {
  final AppDatabase db;
  ExpenseLogic(this.db);

  Future<void> addRawNote(String text) async {
    if (text.trim().isEmpty) return;

    // We insert a new row into SQLite
    await db.into(db.expenses).insert(
      ExpensesCompanion.insert(
        rawNote: text,
        date: DateTime.now(),
        // We mark it as TRUE because we haven't added the AI parser yet!
        isPendingAi: const Value(true), 
      ),
    );
  }
}

// Make the writer available to the UI
final expenseLogicProvider = Provider<ExpenseLogic>((ref) {
  return ExpenseLogic(ref.watch(databaseProvider));
});