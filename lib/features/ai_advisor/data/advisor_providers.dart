import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/ai_service.dart';
import '../../expense_entry/data/budget_providers.dart';

final advisorChatProvider = StateProvider<List<Map<String, String>>>((ref) {
  return [
    {
      'role': 'ai', 
      'text': 'Hello! I am your BirrNote AI Advisor. Ask me anything about your spending!'
    }
  ];
});

final advisorLogicProvider = Provider((ref) {
  return AdvisorLogic(ref);
});

class AdvisorLogic {
  final Ref ref;
  AdvisorLogic(this.ref);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final chatHistory = ref.read(advisorChatProvider);
    
    final updatedHistoryWithTyping = [
      ...chatHistory,
      {'role': 'user', 'text': text},
      {'role': 'ai_typing', 'text': 'AI is thinking...'}
    ];
    ref.read(advisorChatProvider.notifier).state = updatedHistoryWithTyping;

    try {
      final expenseDao = ref.read(expenseDaoProvider);

      // A. RETRIEVE BUDGET STATUS
      final budgetState = ref.read(budgetEngineProvider);
      String budgetStatus = "No active budget configured.";
      if (budgetState.hasBudget) {
        budgetStatus = "Daily allowance: ${budgetState.dailyLimit.toStringAsFixed(2)} ETB/day. TODAY'S REMAINING SPENDING POWER: ${budgetState.todaySpendingPower.toStringAsFixed(2)} ETB.";
      }

      // B. RETRIEVE 3-MONTH DETAILED TRANSACTION HISTORY
      final last90DaysExpenses = await expenseDao.getExpensesForLast90Days();
      
      // Pack them into an extremely space-saving, dense text block!
      final formattedExpenses = last90DaysExpenses.map((e) {
        final dateStr = "${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}";
        return "$dateStr: ${e.category} - ${e.amount.toStringAsFixed(2)} ETB (${e.rawNote})";
      }).join('\n');

      // C. COMBINE THE ENTIRE FINANCIAL PORTFOLIO CONTEXT
      final fullContext = '''
        --- ACTIVE SYSTEM BUDGET STATUS ---
        $budgetStatus
        
        --- 90-DAY COMPACT LEDGER DATA ---
        ${formattedExpenses.isEmpty ? 'No transactions logged in the last 90 days.' : formattedExpenses}
      ''';

      final aiService = ref.read(aiServiceProvider);
      
      final historyForAi = [
        ...chatHistory,
        {'role': 'user', 'text': text}
      ];

      // D. Send the entire portfolio context and the active session history!
      final response = await aiService.askAdvisor(historyForAi, fullContext);

      final currentHistory = List<Map<String, String>>.from(ref.read(advisorChatProvider));
      final typingIndex = currentHistory.indexWhere((msg) => msg['role'] == 'ai_typing');
      
      if (typingIndex != -1) {
        currentHistory[typingIndex] = {'role': 'ai', 'text': response};
        ref.read(advisorChatProvider.notifier).state = currentHistory;
      }
    } catch (e) {
      print("Advisor Sync Error: $e");
      final currentHistory = List<Map<String, String>>.from(ref.read(advisorChatProvider));
      final typingIndex = currentHistory.indexWhere((msg) => msg['role'] == 'ai_typing');
      
      if (typingIndex != -1) {
        currentHistory[typingIndex] = {
          'role': 'ai_error', 
          'text': 'Connection failed. Please check your internet and try again.'
        };
        ref.read(advisorChatProvider.notifier).state = currentHistory;
      }
    }
  }
}