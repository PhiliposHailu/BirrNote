import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/ai_service.dart'; // NEW IMPORT

// THE READER (Live Stream) - Keep this exactly as it was
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.expenses).watch(); 
});

// THE WRITER
class ExpenseLogic {
  final AppDatabase db;
  final AiService aiService; // NEW: Inject the AI Service

  ExpenseLogic(this.db, this.aiService);

  Future<void> addRawNote(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Insert the raw note immediately (UI updates instantly)
    // We save the generated ID so we know which row to update later!
    final newExpenseId = await db.into(db.expenses).insert(
      ExpensesCompanion.insert(
        rawNote: text,
        date: DateTime.now(),
        isPendingAi: const Value(true), // Pending!
      ),
    );

    // 2. Ask Gemini to parse it
    final parsedData = await aiService.parseNoteToExpense(text);

    // 3. If Gemini succeeds, update the database row
    if (parsedData != null) {
      // Because amount could be an int (like 50) or double (50.5) from JSON, 
      // we ensure it parses safely to a double.
      final double parsedAmount = (parsedData['amount'] as num).toDouble();
      
      await (db.update(db.expenses)..where((tbl) => tbl.id.equals(newExpenseId))).write(
        ExpensesCompanion(
          amount: Value(parsedAmount),
          category: Value(parsedData['category'].toString()),
          quantity: Value(parsedData['quantity'] as int),
          isPendingAi: const Value(false), // Done! The orange sync icon will disappear.
        ),
      );
    }
  }
}

// UPDATE THE PROVIDER to pass both the database AND the AI service
final expenseLogicProvider = Provider<ExpenseLogic>((ref) {
  final db = ref.watch(databaseProvider);
  final ai = ref.watch(aiServiceProvider);
  return ExpenseLogic(db, ai);
});