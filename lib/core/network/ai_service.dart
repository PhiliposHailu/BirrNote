import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'api_key_provider.dart';

class AiService {
  final String? apiKey;

  AiService(this.apiKey);

  // returns a List of Maps!
  Future<List<Map<String, dynamic>>?> parseNoteToExpenses(
    String note,
    List<String> categories,
  ) async {
    if (apiKey == null || apiKey!.isEmpty) return null;

    // Turn the list of categories into a single comma-separated string (e.g. "Food, Transport, Bills")
    final categoriesString = categories.join(', ');

    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: apiKey!,
      systemInstruction: Content.system('''
        You are a financial parser for BirrNote.
        Extract a LIST of expenses from the user's note.
        
        RULES:
        1. If the user lists multiple items with distinct prices (e.g., "Gas 200, Food 100"), return multiple objects.
        2. If the user lists multiple items but only ONE total price (e.g., "Gas and food 500"), return ONE object.
        3. For 'extractedNote', write a short, clean name for the item.
        4. If currency is not specified, assume Ethiopian Birr (ETB).
        5. You MUST classify each item into EXACTLY ONE of these categories: [$categoriesString]. 
           Do not make up new categories outside of this list!
      '''),

      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.array(
          items: Schema.object(
            properties: {
              'extractedNote': Schema.string(
                description: 'A short, clean name for this specific expense.',
              ),
              'amount': Schema.number(description: 'The total cost.'),
              'category': Schema.string(
                description: 'The category. Must be one of: $categoriesString',
              ),
              'quantity': Schema.integer(
                description: 'Number of items. Default to 1.',
              ),
            },
            requiredProperties: [
              'extractedNote',
              'amount',
              'category',
              'quantity',
            ],
          ),
        ),
      ),
    );

    try {
      final response = await model.generateContent([Content.text(note)]);

      if (response.text != null) {
        // Decode the JSON array
        final List<dynamic> decodedList = jsonDecode(response.text!);
        // Cast it safely to a List of Maps
        return decodedList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('AI Parsing Error: $e');
      return null;
    }
    return null;
  }

  // The Financial Advisor Chat Method
  Future<String> askAdvisor(
    List<Map<String, String>> chatHistory,
    String financialContext,
  ) async {
    if (apiKey == null || apiKey!.isEmpty) {
      return "Please add your Gemini API Key in Settings first!";
    }

    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: apiKey!,
      systemInstruction: Content.system('''
        You are a friendly, professional financial advisor for the BirrNote app.
        The user is asking you for financial advice. 
        
        Here is the user's current spending summary:
        $financialContext
        
        RULES:
        1. Base your advice STRICTLY on the spending summary provided above.
        2. Keep your answers concise, practical, and conversational.
        3. Do not use markdown formatting heavily.
        4. If they ask something unrelated to finance, politely steer them back to their budget.
      '''),
    );

    try {
      final List<Content> geminiHistory = [];
      String newestMessage = "";

      // We filter out any typing placeholders or errors from the history
      final filteredList = chatHistory
          .where((msg) => msg['role'] == 'user' || msg['role'] == 'ai')
          .toList();

      if (filteredList.isNotEmpty) {
        // A. Isolate the very last user message (the active question)
        newestMessage = filteredList.last['text'] ?? '';

        // B. Map all previous messages before it into Gemini Content objects!
        for (int i = 0; i < filteredList.length - 1; i++) {
          final msg = filteredList[i];
          if (msg['role'] == 'user') {
            geminiHistory.add(Content.text(msg['text'] ?? ''));
          } else if (msg['role'] == 'ai') {
            geminiHistory.add(Content.model([TextPart(msg['text'] ?? '')]));
          }
        }
      }

      // C. Start the chat session with our loaded history backlog!
      final chat = model.startChat(history: geminiHistory);

      // D. Send the active question through the chat stream
      final response = await chat.sendMessage(Content.text(newestMessage));
      return response.text ?? "I'm sorry, I couldn't process that right now.";
    } catch (e) {
      print('Advisor AI Error: $e');
      return "Looks like you're offline or there was an error connecting to the AI.";
    }
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  return AiService(apiKey);
});
