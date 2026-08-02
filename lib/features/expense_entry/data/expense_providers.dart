import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; 
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/expense_dao.dart';
import '../../../core/database/daos/category_dao.dart';
import '../../../core/network/ai_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:async'; // Add this at the top for Timer

// ... (leave imports above intact, we'll insert below)
// StateProvider to track which pending notes have failed their network request
final failedAiNotesProvider = StateProvider<Set<int>>((ref) => {});

// NEW: A smart provider that automatically rolls over exactly at midnight!
class TodayNotifier extends StateNotifier<DateTime> {
  Timer? _timer;
  TodayNotifier() : super(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)) {
    // Check every 60 seconds if we've crossed midnight
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      if (todayMidnight.isAfter(state)) {
        state = todayMidnight; // Trigger a rebuild across the app!
      }
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final todayProvider = StateNotifierProvider<TodayNotifier, DateTime>((ref) {
  return TodayNotifier();
});

// 1. WATCH TODAY'S EXPENSES (For Home Screen)
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  final today = ref.watch(todayProvider); // Now correctly recalculates at midnight!
  
  // Use our new dynamic date fetcher
  return expenseDao.watchExpensesForDate(today); 
});

// 2. WATCH ALL EXPENSES (For Budget Engine)
final allExpensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  return expenseDao.watchExpenses(); 
});

// 3. HISTORY FILTER DATE (Normalized to 12:00:00 AM Midnight!)
final historyDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// 4. WATCH EXPENSES FOR SELECTED HISTORY DATE (For History Screen)
final historyExpensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  final selectedDate = ref.watch(historyDateProvider);
  return expenseDao.watchExpensesForDate(selectedDate);
});

class ExpenseLogic {
  final Ref ref;
  ExpenseLogic(this.ref);

  ExpenseDao get expenseDao => ref.read(expenseDaoProvider);
  CategoryDao get categoryDao => ref.read(categoryDaoProvider);
  AiService get aiService => ref.read(aiServiceProvider);

  // 1. ADD RAW NOTE (AI Parsing)
  Future<void> addRawNote(String text) async {
    if (text.trim().isEmpty) return;

    final pendingId = await expenseDao.insertExpense(
      ExpensesCompanion.insert(
        rawNote: text,
        date: DateTime.now(),
        isPendingAi: const Value(true), 
      ),
    );

    // Clear any previous failure for this ID (just in case)
    ref.read(failedAiNotesProvider.notifier).update((state) {
      final newState = Set<int>.from(state);
      newState.remove(pendingId);
      return newState;
    });

    try {
      final activeCategories = await categoryDao.getActiveCategories();
      
      // FALLBACK: If the user types instantly on launch before the Provider loads the key,
      // we grab it directly from storage so it doesn't fail!
      var key = aiService.apiKey;
      if (key == null || key.isEmpty) {
        key = await const FlutterSecureStorage().read(key: 'gemini_api_key');
      }
      
      final serviceToUse = (aiService.apiKey == null || aiService.apiKey!.isEmpty) && key != null
          ? AiService(key)
          : aiService;

      final parsedList = await serviceToUse.parseNoteToExpenses(text, activeCategories);

      if (parsedList != null && parsedList.isNotEmpty) {
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
      } else {
        // Parsing returned null (e.g. timeout or no API key)
        ref.read(failedAiNotesProvider.notifier).update((state) => Set.from(state)..add(pendingId));
      }
    } catch (e) {
      print("Error in addRawNote: $e");
      ref.read(failedAiNotesProvider.notifier).update((state) => Set.from(state)..add(pendingId));
    }
  }

  // 2. OFFLINE QUEUE PROCESSOR
  Future<void> syncPendingNotes() async {
    final pendingNotes = await (expenseDao.select(expenseDao.expenses)
      ..where((tbl) => tbl.isPendingAi.equals(true))).get();

    if (pendingNotes.isEmpty) return;

    try {
      final activeCategories = await categoryDao.getActiveCategories();

      for (final note in pendingNotes) {
        // Clear failure state for this note before retrying
        ref.read(failedAiNotesProvider.notifier).update((state) {
          final newState = Set<int>.from(state);
          newState.remove(note.id);
          return newState;
        });

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
        } else {
          // Parsing failed on retry
          ref.read(failedAiNotesProvider.notifier).update((state) => Set.from(state)..add(note.id));
        }
      }
    } catch (e) {
      print("Error in syncPendingNotes: $e");
      // Mark all attempted notes as failed if a fatal error occurs
      for (final note in pendingNotes) {
        ref.read(failedAiNotesProvider.notifier).update((state) => Set.from(state)..add(note.id));
      }
    }
  }

  // 3. MANUAL ENTRY
  Future<void> addManualExpense({
    required double amount,
    required String category,
    required int quantity,
    required String note,
    DateTime? date,
  }) async {
    await expenseDao.insertExpense(
      ExpensesCompanion.insert(
        rawNote: note.trim().isEmpty ? category : note,
        amount: Value(amount),
        category: Value(category),
        quantity: Value(quantity),
        date: date ?? DateTime.now(),
        isPendingAi: const Value(false), 
      ),
    );
  }

  // 4. EDIT EXPENSE
  Future<void> editExpense({
    required int id,
    required double amount,
    required String category,
    required int quantity,
    required String note,
    required DateTime date,
  }) async {
    await expenseDao.updateExpense(
      ExpensesCompanion(
        id: Value(id),
        rawNote: Value(note.trim().isEmpty ? category : note),
        amount: Value(amount),
        category: Value(category),
        quantity: Value(quantity),
        date: Value(date),
        isPendingAi: const Value(false), 
      ),
    );
  }
}

final expenseLogicProvider = Provider<ExpenseLogic>((ref) {
  return ExpenseLogic(ref);
});