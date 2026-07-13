import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/ai_service.dart';
import '../../dashboard/data/dashboard_providers.dart';

// Watches and holds our chat history list
final advisorChatProvider = StateProvider<List<Map<String, String>>>((ref) {
  return [
    {
      'role': 'ai', 
      'text': 'Hello! I am your BirrNote AI Advisor. Ask me anything about your spending!'
    }
  ];
});

// Holds the logic to orchestrate sending messages
final advisorLogicProvider = Provider((ref) {
  return AdvisorLogic(ref);
});

class AdvisorLogic {
  final Ref ref;
  AdvisorLogic(this.ref);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add User's message and a temporary "AI is thinking..." bubble immediately
    final chatHistory = ref.read(advisorChatProvider);
    ref.read(advisorChatProvider.notifier).state = [
      ...chatHistory,
      {'role': 'user', 'text': text},
      {'role': 'ai_typing', 'text': 'AI is typing...'} // THE ACTIVE TYPING BUBBLE!
    ];

    // 2. Fetch the latest financial data context from SQLite
    final asyncTotals = ref.read(categoryTotalsProvider);
    String financialContext = "No spending data available yet.";
    if (asyncTotals.value != null && asyncTotals.value!.isNotEmpty) {
      financialContext = asyncTotals.value!
          .map((item) => "${item.category}: ${item.total} ETB")
          .join(", ");
    }

    try {
      // 3. Query the AI Service
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.askAdvisor(text, financialContext);

      // 4. THE IN-PLACE SWAP: Find our typing bubble and replace it with Gemini's advice!
      final currentHistory = List<Map<String, String>>.from(ref.read(advisorChatProvider));
      final typingIndex = currentHistory.indexWhere((msg) => msg['role'] == 'ai_typing');
      
      if (typingIndex != -1) {
        currentHistory[typingIndex] = {'role': 'ai', 'text': response};
        ref.read(advisorChatProvider.notifier).state = currentHistory;
      }
    } catch (e) {
      // 5. THE ERROR SWAP: If it fails, replace the typing bubble with a red error alert
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