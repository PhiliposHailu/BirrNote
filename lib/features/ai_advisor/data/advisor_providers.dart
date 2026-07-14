import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/ai_service.dart';
import '../../../core/database/database_provider.dart';

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
      // FIXED: We fetch the raw, up-to-date totals directly from the database!
      final expenseDao = ref.read(expenseDaoProvider);
      final totals = await expenseDao.getCategoryTotals(); // Await the direct query!
      
      String financialContext = "No spending data available yet.";
      
      if (totals.isNotEmpty) {
        financialContext = totals
            .map((item) => "${item.category}: ${item.total} ETB")
            .join(", ");
      }

      final aiService = ref.read(aiServiceProvider);
      
      final historyForAi = [
        ...chatHistory,
        {'role': 'user', 'text': text}
      ];

      final response = await aiService.askAdvisor(historyForAi, financialContext);

      final currentHistory = List<Map<String, String>>.from(ref.read(advisorChatProvider));
      final typingIndex = currentHistory.indexWhere((msg) => msg['role'] == 'ai_typing');
      
      if (typingIndex != -1) {
        currentHistory[typingIndex] = {'role': 'ai', 'text': response};
        ref.read(advisorChatProvider.notifier).state = currentHistory;
      }
    } catch (e) {
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