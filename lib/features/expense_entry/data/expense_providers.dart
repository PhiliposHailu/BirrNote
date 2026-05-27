import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/ai_service.dart';

// THE READER (Live Stream)
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final db = ref.watch(databaseProvider);
  
  return (db.select(db.expenses)
        ..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)
        ]))
      .watch(); 
});

// THE WRITER
class ExpenseLogic {
  final AppDatabase db;
  final AiService aiService; // NEW: Inject the AI Service

  ExpenseLogic(this.db, this.aiService);

  Future<void> addRawNote(String text) async {
    if (text.trim().isEmpty) return;

    // 1. OPTIMISTIC UI: Insert as a pending placeholder
    final pendingId = await db.into(db.expenses).insert(
      ExpensesCompanion.insert(
        rawNote: text,
        date: DateTime.now(),
        isPendingAi: const Value(true), 
      ),
    );

    // 2. Ask Gemini
    final parsedList = await aiService.parseNoteToExpenses(text);

    
    if (parsedList != null && parsedList.isNotEmpty) {
      await db.transaction(() async {
        
        // A. Delete the single pending row
        await (db.delete(db.expenses)..where((tbl) => tbl.id.equals(pendingId))).go();

        // B. Insert all the new structured rows
        for (final item in parsedList) {
          await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              // Make sure these match the keys in your AiService schema!
              rawNote: item['extractedNote'].toString(), 
              amount: Value((item['amount'] as num).toDouble()),
              category: Value(item['category'].toString()),
              quantity: Value(item['quantity'] as int),
              date: DateTime.now(), 
              isPendingAi: const Value(false), 
            ),
          );
        }
      });
    }
  }

  // The Background Queue Processor
  Future<void> syncPendingNotes() async {
    // 1. Query the database for all rows that are stuck in "pending"
    final pendingNotes = await (db.select(db.expenses)
      ..where((tbl) => tbl.isPendingAi.equals(true))).get();

    // If nothing is pending, exit.
    if (pendingNotes.isEmpty) return;

    // 2. Loop through each pending note and try to send it to the AI again
    for (final note in pendingNotes) {
      final parsedList = await aiService.parseNoteToExpenses(note.rawNote);

      if (parsedList != null && parsedList.isNotEmpty) {
        // If successful, do the exact same swap we did before!
        await db.transaction(() async {
          await (db.delete(db.expenses)..where((tbl) => tbl.id.equals(note.id))).go();

          for (final item in parsedList) {
            await db.into(db.expenses).insert(
              ExpensesCompanion.insert(
                rawNote: item['extractedNote'].toString(),
                amount: Value((item['amount'] as num).toDouble()),
                category: Value(item['category'].toString()),
                quantity: Value(item['quantity'] as int),
                date: note.date, // Keep the original date they typed it!
                isPendingAi: const Value(false),
              ),
            );
          }
        });
      }
    }
  }

}

final expenseLogicProvider = Provider<ExpenseLogic>((ref) {
  final db = ref.watch(databaseProvider);
  final ai = ref.watch(aiServiceProvider);
  return ExpenseLogic(db, ai);
});