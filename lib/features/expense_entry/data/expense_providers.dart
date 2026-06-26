import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/ai_service.dart';

// THE READER (Live Stream)
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final db = ref.watch(databaseProvider);

  return (db.select(db.expenses)..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ]))
      .watch();
});

// THE WRITER
class ExpenseLogic {
  final AppDatabase db;
  final AiService aiService;

  ExpenseLogic(this.db, this.aiService);

  Future<void> addRawNote(String text) async {
    if (text.trim().isEmpty) return;

    // 1. OPTIMISTIC UI: Insert as a pending placeholder
    final pendingId = await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            rawNote: text,
            date: DateTime.now(),
            isPendingAi: const Value(true),
          ),
        );

    try {
      // B. FETCH ACTIVE CATEGORIES FROM DATABASE! (New step)
      final activeCategories = await db.getActiveCategories();

      // C. Ask Gemini, passing the custom category list!
      final parsedList = await aiService.parseNoteToExpenses(
        text,
        activeCategories,
      );

      // D. THE SWAP: Replace the pending placeholder with the parsed data
      if (parsedList != null && parsedList.isNotEmpty) {
        await db.transaction(() async {
          await (db.delete(
            db.expenses,
          )..where((tbl) => tbl.id.equals(pendingId))).go();

          for (final item in parsedList) {
            await db
                .into(db.expenses)
                .insert(
                  ExpensesCompanion.insert(
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
    } catch (e) {
      print("Error in addRawNote: $e");
    }
  }

  // 2. BACKGROUND QUEUE PROCESSOR (Now supports dynamic categories!)
  Future<void> syncPendingNotes() async {
    final pendingNotes = await (db.select(
      db.expenses,
    )..where((tbl) => tbl.isPendingAi.equals(true))).get();

    if (pendingNotes.isEmpty) return;

    try {
      // Fetch active categories from database
      final activeCategories = await db.getActiveCategories();

      for (final note in pendingNotes) {
        final parsedList = await aiService.parseNoteToExpenses(
          note.rawNote,
          activeCategories,
        );

        if (parsedList != null && parsedList.isNotEmpty) {
          await db.transaction(() async {
            await (db.delete(
              db.expenses,
            )..where((tbl) => tbl.id.equals(note.id))).go();

            for (final item in parsedList) {
              await db
                  .into(db.expenses)
                  .insert(
                    ExpensesCompanion.insert(
                      rawNote: item['extractedNote'].toString(),
                      amount: Value((item['amount'] as num).toDouble()),
                      category: Value(item['category'].toString()),
                      quantity: Value(item['quantity'] as int),
                      date: note.date,
                      isPendingAi: const Value(false),
                    ),
                  );
            }
          });
        }
      }
    } catch (e) {
      print("Error in syncPendingNotes: $e");
    }
  }

  // Manual Entry bypasses the AI completely!
  Future<void> addManualExpense({
    required double amount,
    required String category,
    required int quantity,
    required String note,
  }) async {
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            rawNote: note.trim().isEmpty ? category : note,
            amount: Value(amount),
            category: Value(category),
            quantity: Value(quantity),
            date: DateTime.now(),
            isPendingAi: const Value(false),
          ),
        );
  }
}

final expenseLogicProvider = Provider<ExpenseLogic>((ref) {
  final db = ref.watch(databaseProvider);
  final ai = ref.watch(aiServiceProvider);
  return ExpenseLogic(db, ai);
});