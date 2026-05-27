import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'api_key_provider.dart';

class AiService {
  final String? apiKey;

  AiService(this.apiKey);

  // returns a List of Maps!
  Future<List<Map<String, dynamic>>?> parseNoteToExpenses(String note) async {
    if (apiKey == null || apiKey!.isEmpty) return null;

    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: apiKey!,
      systemInstruction: Content.system('''
        You are a financial parser for BirrNote.
        Extract a LIST of expenses from the user's note.
        
        RULES:
        1. If the user lists multiple items with distinct prices (e.g., "Gas 200, Food 100"), return multiple objects.
        2. If the user lists multiple items but only ONE total price (e.g., "Gas and food 500"), return ONE object. Sum the quantity if applicable, and use a broad category like 'Mixed' or 'General'.
        3. For 'extractedNote', write a short, clean name for the item (e.g., "Gas", "Food", or "Gas and food").
        4. If currency is not specified, assume Ethiopian Birr (ETB).
      '''),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.array(
          items: Schema.object(
            properties: {
              'extractedNote': Schema.string(description: 'A short, clean name for this specific expense.'),
              'amount': Schema.number(description: 'The total cost.'),
              'category': Schema.string(description: 'A 1-2 word broad category.'),
              'quantity': Schema.integer(description: 'Number of items. Default to 1.'),
            },
            requiredProperties: ['extractedNote', 'amount', 'category', 'quantity'],
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
}

final aiServiceProvider = Provider<AiService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  return AiService(apiKey);
});