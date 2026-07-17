import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/expense_dao.dart'; 
import '../../../core/database/daos/category_dao.dart'; 
import '../../../core/network/ai_service.dart';

// 1. WATCH TODAY'S expenses only (replaces old all-time stream)
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  return expenseDao.watchTodaysExpenses(); // Today only!
});

// Watches the entire SQLite database history (Only used by the Budget Engine!)
final allExpensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  return expenseDao.watchExpenses(); // Accesses all-time data
});

// 2. Tracks the selected history filter date (Defaults to today)
final historyDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day); // 12:00:00 AM
});

// 3. WATCH EXPENSES FOR SELECTED HISTORY DATE
final historyExpensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  final selectedDate = ref.watch(historyDateProvider);
  return expenseDao.watchExpensesForDate(selectedDate);
});

class ExpenseLogic {
  final ExpenseDao expenseDao; // Changed from AppDatabase to ExpenseDao
  final CategoryDao categoryDao; // Changed from AppDatabase to CategoryDao
  final AiService aiService;

  ExpenseLogic(this.expenseDao, this.categoryDao, this.aiService);

  // 1. ADD RAW NOTE
  Future<void> addRawNote(String text) async {
    if (text.trim().isEmpty) return;

    // Optimistic UI insert
    final pendingId = await expenseDao.insertExpense(
      ExpensesCompanion.insert(
        rawNote: text,
        date: DateTime.now(),
        isPendingAi: const Value(true), 
      ),
    );

    try {
      // Fetch active categories from Category DAO
      final activeCategories = await categoryDao.getActiveCategories();

      final parsedList = await aiService.parseNoteToExpenses(text, activeCategories);

      if (parsedList != null && parsedList.isNotEmpty) {
        // Run database transactions safely through the DAO database connection
        await expenseDao.transaction(() async {
          await expenseDao.deleteExpense(pendingId);

          for (final item in parsedList) {
            await expenseDao.insertExpense(
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

  // 2. OFFLINE QUEUE PROCESSOR
  Future<void> syncPendingNotes() async {
    // Queries DAO directly
    final pendingNotes = await (expenseDao.select(expenseDao.expenses)
      ..where((tbl) => tbl.isPendingAi.equals(true))).get();

    if (pendingNotes.isEmpty) return;

    try {
      final activeCategories = await categoryDao.getActiveCategories();

      for (final note in pendingNotes) {
        final parsedList = await aiService.parseNoteToExpenses(note.rawNote, activeCategories);

        if (parsedList != null && parsedList.isNotEmpty) {
          await expenseDao.transaction(() async {
            await expenseDao.deleteExpense(note.id);

            for (final item in parsedList) {
              await expenseDao.insertExpense(
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

  // 3. MANUAL ENTRY
  Future<void> addManualExpense({
    required double amount,
    required String category,
    required int quantity,
    required String note,
  }) async {
    await expenseDao.insertExpense(
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
  final expenseDao = ref.watch(expenseDaoProvider);
  final categoryDao = ref.watch(categoryDaoProvider);
  final ai = ref.watch(aiServiceProvider);
  return ExpenseLogic(expenseDao, categoryDao, ai);
});
