import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/ai_service.dart';
import '../../dashboard/data/dashboard_providers.dart';

// We use a StateProvider to hold the chat history so it stays on screen
final advisorChatProvider = StateProvider<List<Map<String, String>>>((ref) {
  return [
    {'role': 'ai', 'text': 'Hello! I am your BirrNote AI Advisor. Ask me anything about your spending!'}
  ];
});

// handles the logic of sending the message
final advisorLogicProvider = Provider((ref) {
  return AdvisorLogic(ref);
});

class AdvisorLogic {
  final Ref ref;
  AdvisorLogic(this.ref);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add the user's message to the chat UI immediately
    final chatHistory = ref.read(advisorChatProvider);
    ref.read(advisorChatProvider.notifier).state = [
      ...chatHistory,
      {'role': 'user', 'text': text}
    ];

    // 2. Fetch the latest financial data from our SQLite Dashboard Provider
    // This is the "Retrieval" in RAG! ???
    final asyncTotals = ref.read(categoryTotalsProvider);
    
    String financialContext = "No spending data available yet.";
    
    // If we have data, we format it into a clean string for the AI to read
    if (asyncTotals.value != null && asyncTotals.value!.isNotEmpty) {
      financialContext = asyncTotals.value!
          .map((item) => "${item.category}: ${item.total} ETB")
          .join(", ");
    }

    // 3. Ask the AI (passing the data and the question)
    final aiService = ref.read(aiServiceProvider);
    final response = await aiService.askAdvisor(text, financialContext);

    // 4. Add the AI's response to the chat UI
    final updatedHistory = ref.read(advisorChatProvider);
    ref.read(advisorChatProvider.notifier).state = [
      ...updatedHistory,
      {'role': 'ai', 'text': response}
    ];
  }
}